#!/usr/bin/env bash

set -euo pipefail

LEDE_DIR="${1:-/root/cudy-tr3000-build/lede}"
OUT_DIR="${2:-$(cd "$(dirname "$0")/.." && pwd)/artifacts}"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BIN_DIR="$LEDE_DIR/bin/targets/mediatek/filogic"
IMAGE="$(find "$BIN_DIR" -maxdepth 1 -type f -name '*cudy_tr3000-mod*squashfs-sysupgrade.bin' | head -1)"
MANIFEST="$(find "$BIN_DIR" -maxdepth 1 -type f -name '*cudy_tr3000-mod.manifest' | head -1)"
ROOTFS="$(find "$LEDE_DIR/build_dir" -maxdepth 2 -type d -name root-mediatek | head -1)"

source "$PROJECT_DIR/versions.lock"

test -n "$IMAGE"
test -s "$IMAGE"
test -n "$MANIFEST"
test -n "$ROOTFS"

size="$(stat -c %s "$IMAGE")"
max=$((112 * 1024 * 1024))
test "$size" -lt "$max"

grep -q '"cudy,tr3000-mod"' "$BIN_DIR/profiles.json"
grep -q '^luci-app-openclash ' "$MANIFEST"
grep -q '^luci-app-nlbwmon ' "$MANIFEST"
grep -q '^nlbwmon ' "$MANIFEST"
! grep -Eq '^(luci-app-store|luci-lib-taskd|luci-lib-xterm|taskd) ' "$MANIFEST"
grep -q '^kmod-usb-net-rndis ' "$MANIFEST"
grep -q '^kmod-usb-net-cdc-ncm ' "$MANIFEST"
grep -q '^usbutils ' "$MANIFEST"
test -x "$ROOTFS/etc/openclash/core/clash_meta"
test -s "$ROOTFS/etc/openclash/GeoIP.dat"
test -s "$ROOTFS/etc/openclash/GeoSite.dat"
test -s "$ROOTFS/etc/openclash/Country.mmdb"
test -s "$ROOTFS/etc/openclash/ASN.mmdb"
echo "$GEOIP_SHA256  $ROOTFS/etc/openclash/GeoIP.dat" | sha256sum -c -
echo "$GEOSITE_SHA256  $ROOTFS/etc/openclash/GeoSite.dat" | sha256sum -c -
echo "$COUNTRY_MMDB_SHA256  $ROOTFS/etc/openclash/Country.mmdb" | sha256sum -c -
echo "$ASN_MMDB_SHA256  $ROOTFS/etc/openclash/ASN.mmdb" | sha256sum -c -
test -x "$ROOTFS/usr/sbin/tr3000-offload-check"
grep -q "flow_offloading='1'" "$ROOTFS/etc/uci-defaults/99-cudy-tr3000-baseline"
grep -q "flow_offloading_hw='1'" "$ROOTFS/etc/uci-defaults/99-cudy-tr3000-baseline"
grep -q '^CONFIG_NF_FLOW_TABLE=' "$LEDE_DIR/build_dir/target-aarch64_cortex-a53_musl/linux-mediatek_filogic/linux-"*/.config
grep -q '^CONFIG_NET_MEDIATEK_SOC=y' "$LEDE_DIR/build_dir/target-aarch64_cortex-a53_musl/linux-mediatek_filogic/linux-"*/.config
grep -q '^CONFIG_NET_MEDIATEK_SOC_WED=y' "$LEDE_DIR/build_dir/target-aarch64_cortex-a53_musl/linux-mediatek_filogic/linux-"*/.config
grep -q '^CONFIG_DEBUG_FS=y' "$LEDE_DIR/build_dir/target-aarch64_cortex-a53_musl/linux-mediatek_filogic/linux-"*/.config
find "$LEDE_DIR/build_dir/target-aarch64_cortex-a53_musl/linux-mediatek_filogic/linux-"* \
  -path '*/drivers/net/ethernet/mediatek/mtk_ppe_offload.o' -print -quit | grep -q .
grep -q '^root:::' "$ROOTFS/etc/shadow"
! grep -Eq '^luci-app-(arpbind|autoreboot|ddns|turboacc|upnp|vlmcsd|vsftpd|wol) ' "$MANIFEST"

mkdir -p "$OUT_DIR"
rm -f "$OUT_DIR"/luci-app-store*.ipk "$OUT_DIR"/luci-app-store*.apk
cp -f "$IMAGE" "$MANIFEST" "$BIN_DIR/profiles.json" "$BIN_DIR/sha256sums" "$OUT_DIR/"
find "$LEDE_DIR/bin/packages" -type f \
  \( -name 'luci-app-openclash*.ipk' -o -name 'luci-app-openclash*.apk' \) \
  -exec cp -f {} "$OUT_DIR/" \;

(
  cd "$OUT_DIR"
  sha256sum * > SHA256SUMS
)

cat >"$OUT_DIR/verification.txt" <<EOF
profile=cudy_tr3000-mod
image=$(basename "$IMAGE")
image_size_bytes=$size
image_limit_bytes=$max
openclash=present
istore=absent
nlbwmon=present
rndis=present
cdc_ncm=present
embedded_mihomo=present_in_rootfs_overlay
embedded_mihomo_arch=aarch64
embedded_geoip=present
embedded_geosite=present
embedded_country_mmdb=present
embedded_asn_mmdb=present
flow_offloading=enabled
flow_offloading_hw=enabled
mt7981_ppe=present
mt7981_wed=enabled
offload_runtime_check=/usr/sbin/tr3000-offload-check
root_password=unset
EOF

echo "Verified: $IMAGE ($size bytes)"
