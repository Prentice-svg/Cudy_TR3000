# Cudy TR3000 112M LEDE build

Reproducible LEDE build for the Cudy TR3000 128 MB old NAND revision
(`F50L1G41LB`) with the 112 MiB U-Boot partition layout.

The actual OpenWrt build tree is kept in WSL2 at
`/root/cudy-tr3000-build`. Firmware and reports are copied back to
`artifacts/`.

## Included

- LEDE `mediatek/filogic` target, `cudy_tr3000-mod` profile
- Argon blue LuCI theme enabled by default, with Bootstrap retained as fallback
- OpenClash with an embedded ARM64 Mihomo core
- Tailscale 1.84.2 with the community LuCI interface and Chinese translation
- Netlink bandwidth monitor (`nlbwmon`) with LuCI traffic statistics
- OpenClash GeoIP, GeoSite, Country MMDB, and ASN MMDB databases
- USB 3.0, RNDIS, CDC Ethernet, and CDC NCM support for ZTE F50
- Software and hardware flow offloading enabled by default
- Firewall4-compatible `dnsmasq-full` nftset support
- LuCI at `192.168.1.1`
- No preset root password, subscription, or OpenClash configuration

## Build

Run from PowerShell:

```powershell
wsl.exe -d CodexUbuntuNoble -- bash /mnt/e/Dev/Cudy_TR3000/scripts/build.sh
```

The script installs Ubuntu build dependencies, creates the Linux-side build
tree, locks all upstream repositories to `versions.lock`, builds the image,
and verifies the result.

## Device safety check

Before flashing, copy `scripts/device-check.sh` to the router and run it over
SSH. Only use the resulting image when it reports:

- NAND contains `F50L1G41LB`
- compatible includes `cudy,tr3000-mod`
- UBI partition is approximately 112 MiB

Do not flash this image on a stock/64 MiB layout or the newer
`F50L1G41LC` NAND revision.

## Hardware offload check

After flashing, disable or bypass OpenClash and run a direct speed test. At
the same time, run:

```sh
tr3000-offload-check 30
```

The command identifies USB network interfaces and watches MT7981 PPE entries.
The hardware-offload switch being enabled does not by itself prove that F50
USB traffic is entering PPE.

## Flashing

Back up the router first. Flash only the generated
`openwrt-mediatek-filogic-cudy_tr3000-mod-squashfs-sysupgrade.bin` through the
112M U-Boot/OpenWrt upgrade path.
