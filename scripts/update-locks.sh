#!/usr/bin/env bash

set -euo pipefail

cat <<EOF
Review these refs and update versions.lock intentionally:
LEDE_COMMIT=$(git ls-remote https://github.com/coolsnowwolf/lede.git HEAD | awk '{print $1}')
PACKAGES_COMMIT=$(git ls-remote https://github.com/coolsnowwolf/packages.git HEAD | awk '{print $1}')
LUCI_COMMIT=$(git ls-remote https://github.com/coolsnowwolf/luci.git refs/heads/openwrt-25.12 | awk '{print $1}')
ROUTING_COMMIT=$(git ls-remote https://github.com/coolsnowwolf/routing.git HEAD | awk '{print $1}')
TELEPHONY_COMMIT=$(git ls-remote https://github.com/coolsnowwolf/telephony.git HEAD | awk '{print $1}')
OPENCLASH_COMMIT=$(git ls-remote https://github.com/vernesong/OpenClash.git refs/heads/master | awk '{print $1}')
TAILSCALE_LUCI_COMMIT=$(git ls-remote https://github.com/Tokisaki-Galaxy/luci-app-tailscale-community.git refs/heads/master | awk '{print $1}')
META_RULES_COMMIT=$(git ls-remote https://github.com/MetaCubeX/meta-rules-dat.git refs/heads/release | awk '{print $1}')
EOF
