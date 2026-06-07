#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="${PROJECT_DIR:-/mnt/e/Dev/Cudy_TR3000}"
BUILD_ROOT="${BUILD_ROOT:-/root/cudy-tr3000-build}"
LEDE_DIR="$BUILD_ROOT/lede"
LOCK_FILE="$PROJECT_DIR/versions.lock"
ARTIFACT_DIR="$PROJECT_DIR/artifacts"
LOG_DIR="$PROJECT_DIR/logs"

source "$LOCK_FILE"

mkdir -p "$BUILD_ROOT/sources" "$BUILD_ROOT/downloads" "$ARTIFACT_DIR" "$LOG_DIR"
exec > >(tee "$LOG_DIR/build-$(date +%Y%m%d-%H%M%S).log") 2>&1

export DEBIAN_FRONTEND=noninteractive
export FORCE_UNSAFE_CONFIGURE=1
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
apt-get update
apt-get install -y \
  build-essential clang flex bison g++ gawk gcc-multilib gettext git \
  libncurses-dev libssl-dev python3 python3-dev python3-setuptools \
  python3-pyelftools python3-docutils rsync swig unzip zlib1g-dev file wget \
  curl jq ca-certificates libelf-dev ecj fastjar java-propose-classpath \
  subversion time xsltproc

clone_locked() {
  local repo="$1" dest="$2" commit="$3"
  if [ ! -d "$dest/.git" ]; then
    git clone "$repo" "$dest"
  fi
  git -C "$dest" fetch --all --tags --prune
  if [ "$(git -C "$dest" rev-parse HEAD)" != "$commit" ]; then
    git -C "$dest" checkout --detach "$commit"
    git -C "$dest" reset --hard "$commit"
    git -C "$dest" clean -fdx
  fi
}

clone_locked "$LEDE_REPO" "$LEDE_DIR" "$LEDE_COMMIT"
clone_locked "$OPENCLASH_REPO" "$BUILD_ROOT/sources/openclash" "$OPENCLASH_COMMIT"
clone_locked "$TAILSCALE_LUCI_REPO" "$BUILD_ROOT/sources/luci-app-tailscale-community" "$TAILSCALE_LUCI_COMMIT"
clone_locked "$META_RULES_REPO" "$BUILD_ROOT/sources/meta-rules-dat" "$META_RULES_COMMIT"

cd "$LEDE_DIR"
ln -sfn "$BUILD_ROOT/downloads" dl

./scripts/feeds update -a
for spec in \
  "packages:$PACKAGES_COMMIT" \
  "luci:$LUCI_COMMIT" \
  "routing:$ROUTING_COMMIT" \
  "telephony:$TELEPHONY_COMMIT"
do
  feed="${spec%%:*}"
  commit="${spec#*:}"
  git -C "feeds/$feed" checkout --detach "$commit"
done

rm -rf package/custom
mkdir -p package/custom
cp -a "$BUILD_ROOT/sources/openclash/luci-app-openclash" package/custom/
cp -a "$BUILD_ROOT/sources/luci-app-tailscale-community/luci-app-tailscale-community" package/custom/
sed -i "/^LUCI_TITLE/i PKG_VERSION:=$TAILSCALE_LUCI_VERSION\nPKG_RELEASE:=1\n" \
  package/custom/luci-app-tailscale-community/Makefile

./scripts/feeds install -a

# Prefer the locked community v4 source over the older copy in the locked LuCI
# feed. The community version includes daemon settings and current firewall4 UI.
rm -f package/feeds/luci/luci-app-tailscale-community

mkdir -p files/etc/openclash/core files/etc/uci-defaults files/usr/sbin
rm -f files/etc/uci-defaults/99-cudy-tr3000-*
cp -f "$PROJECT_DIR/files/etc/uci-defaults/99-cudy-tr3000-r4-network-defaults" \
  files/etc/uci-defaults/
chmod 0755 files/etc/uci-defaults/99-cudy-tr3000-r4-network-defaults
cp -f "$PROJECT_DIR/files/usr/sbin/tr3000-offload-check" files/usr/sbin/
chmod 0755 files/usr/sbin/tr3000-offload-check

core_gz="$BUILD_ROOT/downloads/$(basename "$MIHOMO_URL")"
if [ ! -f "$core_gz" ]; then
  curl -fL --retry 5 --retry-delay 5 "$MIHOMO_URL" -o "$core_gz"
fi
echo "$MIHOMO_GZ_SHA256  $core_gz" | sha256sum -c -
gzip -dc "$core_gz" > files/etc/openclash/core/clash_meta
echo "$MIHOMO_BIN_SHA256  files/etc/openclash/core/clash_meta" | sha256sum -c -
chmod 0755 files/etc/openclash/core/clash_meta

cp -f "$BUILD_ROOT/sources/meta-rules-dat/geoip.dat" files/etc/openclash/GeoIP.dat
cp -f "$BUILD_ROOT/sources/meta-rules-dat/geosite.dat" files/etc/openclash/GeoSite.dat
cp -f "$BUILD_ROOT/sources/meta-rules-dat/country.mmdb" files/etc/openclash/Country.mmdb
cp -f "$BUILD_ROOT/sources/meta-rules-dat/GeoLite2-ASN.mmdb" files/etc/openclash/ASN.mmdb
echo "$GEOIP_SHA256  files/etc/openclash/GeoIP.dat" | sha256sum -c -
echo "$GEOSITE_SHA256  files/etc/openclash/GeoSite.dat" | sha256sum -c -
echo "$COUNTRY_MMDB_SHA256  files/etc/openclash/Country.mmdb" | sha256sum -c -
echo "$ASN_MMDB_SHA256  files/etc/openclash/ASN.mmdb" | sha256sum -c -

# LEDE's default-settings package sets a known root password. Remove that
# behavior so first boot has no preset password.
settings_file="package/lean/default-settings/files/zzz-default-settings"
grep -v '/etc/shadow' "$settings_file" > "$settings_file.tmp"
mv "$settings_file.tmp" "$settings_file"

cp -f "$PROJECT_DIR/configs/tr3000-112m.diffconfig" .config
make defconfig
./scripts/diffconfig.sh | tee "$ARTIFACT_DIR/effective.diffconfig"

make download -j"$(nproc)"
make -j"$(nproc)" V=s

{
  cat "$LOCK_FILE"
  echo "KERNEL_VERSION=6.12$(sed -n 's/^LINUX_VERSION-6.12 = //p' include/kernel-6.12)"
  echo "BUILD_DATE=$(date -u +%FT%TZ)"
} > "$ARTIFACT_DIR/build-versions.txt"

"$PROJECT_DIR/scripts/verify.sh" "$LEDE_DIR" "$ARTIFACT_DIR"
