# Reference firmware comparison

## Verdict

The generated firmware is structurally compatible with the provided known-good
firmware and is expected to pass the same 112M U-Boot/sysupgrade checks and
boot on the same old-revision Cudy TR3000.

Flash the generated image without preserving settings. The reference image
uses firewall3/iptables while the generated image uses firewall4/nftables.

## Image identity and layout

| Property | Known-good reference | Generated firmware |
| --- | --- | --- |
| Sysupgrade directory | `sysupgrade-cudy_tr3000-mod` | `sysupgrade-cudy_tr3000-mod` |
| CONTROL board | `cudy_tr3000-mod` | `cudy_tr3000-mod` |
| Supported device metadata | `cudy,tr3000-mod` | `cudy,tr3000-mod` |
| Target | `mediatek/filogic` | `mediatek/filogic` |
| Architecture | `aarch64_cortex-a53` | `aarch64_cortex-a53` |
| OpenWrt release | `24.10.5` | `24.10.5` |
| Kernel | `6.12.79` | `6.12.92` |
| Root filesystem | SquashFS/XZ, 256 KiB blocks | SquashFS/XZ, 256 KiB blocks |
| UBI partition in DTB | `0x5c0000 0x7000000` | `0x5c0000 0x7000000` |

Both FIT kernels use:

- AArch64 Linux kernel compressed with LZMA
- load address `0x48000000`
- entry address `0x48000000`
- `kernel-1`, `fdt-1`, and default `config-1`
- model `Cudy TR3000 (U-Boot mod)`
- compatible `cudy,tr3000-mod`, `mediatek,mt7981`

The decompiled DTBs differ by only one line: the generated firmware updates the
MediaTek GPIO range count from `0x38` to `0x39`. The flash layout, Ethernet,
USB, Wi-Fi, LEDs, and all device-specific definitions are otherwise identical.

The sysupgrade implementation files `lib/upgrade/platform.sh` and
`lib/upgrade/common.sh` are byte-identical between the two images.

## Required features

Both images include:

- OpenClash
- `kmod-usb3`
- `kmod-usb-net`
- `kmod-usb-net-cdc-ether`
- `kmod-usb-net-cdc-ncm`
- `kmod-usb-net-rndis`
- MT7981 Wi-Fi offload firmware

The generated image removes iStore and adds `nlbwmon` with its LuCI traffic
statistics page. It also adds Tailscale 1.84.2 and the community Tailscale LuCI
4.0.0-r1 interface with Simplified Chinese translation. It additionally embeds:

- AArch64 Mihomo core at `/etc/openclash/core/clash_meta`
- `/etc/openclash/GeoIP.dat`
- `/etc/openclash/GeoSite.dat`
- `/etc/openclash/Country.mmdb`
- `/etc/openclash/ASN.mmdb`

The reference image has no embedded core and must download one after boot.

## Important difference

The reference image uses:

- firewall3/iptables
- `kmod-ipt-offload`
- `luci-app-turboacc`

The generated image uses:

- firewall4/nftables
- `kmod-nft-offload`
- software and hardware flow offloading enabled through UCI defaults

The newer nftables path supports MT7981 PPE flow offload and WED, but there is
no TurboACC LuCI page. Proxied OpenClash traffic generally cannot benefit from
hardware offload because it must traverse OpenClash rules.

Standard upstream MediaTek PPE offload only accepts MediaTek Ethernet output
devices, DSA ports, and WED Wi-Fi devices. Its `mtk_flow_set_output_device()`
returns `-EOPNOTSUPP` for other output devices such as USB RNDIS/NCM.
Therefore, both "hardware offload enabled" and "F50 USB networking works" are
true for the generated image, but they do not by themselves prove that an F50
USB flow is handled by PPE.

Some downstream MT798x trees add an external-device HWNAT path specifically
for USB/PCIe modems. That is a separate vendor-style implementation, currently
has no Cudy TR3000 device definition, and cannot be safely transplanted into
this locked Linux 6.12 LEDE build without a substantial kernel port.

The generated image includes `/usr/sbin/tr3000-offload-check`. While running a
direct speed test with OpenClash disabled or bypassed, run:

```sh
tr3000-offload-check 30
```

Increasing PPE bound-entry and `[HW_OFFLOAD]` counts prove hardware offload for
the tested path. If F50 is the USB default route and those counts do not
increase, F50 is using CPU/software flow offload.

## Flash recommendation

1. Run `scripts/device-check.sh` on the router and require:
   - `cudy,tr3000-mod`
   - NAND `F50L1G41LB`
   - UBI size `07000000`
2. Back up the current firmware/configuration.
3. Flash the generated sysupgrade image with **Keep settings disabled**.
4. Verify Ethernet and LuCI first, then F50 RNDIS, OpenClash, and hardware flow
   offload.

Generated image SHA256:

`fb9fedd8894cf457dd1adbbb7f75304811ff1d6c0f4d8d6b1a7f22ac15972684`
