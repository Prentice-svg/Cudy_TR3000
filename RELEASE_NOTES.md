# Cudy TR3000 112M LEDE v2026.06.07-r3

This release targets the old 128 MB NAND Cudy TR3000 using the
`cudy_tr3000-mod` 112 MiB UBI partition layout.

## Included

- LEDE/OpenWrt 24.10.5, Linux 6.12.92
- Argon 2.4.3 blue LuCI theme enabled by default
- Bootstrap LuCI theme retained as a selectable fallback
- OpenClash 0.47.097
- `dnsmasq-full` nftset support for Firewall4/OpenClash
- Tailscale 1.84.2
- Tailscale community LuCI 4.0.0-r1 with Simplified Chinese translation
- Embedded ARM64 Mihomo `clash_meta` core
- Embedded GeoIP, GeoSite, Country MMDB, and ASN MMDB databases
- `nlbwmon` LuCI traffic statistics
- ZTE F50 USB 3.0 RNDIS and CDC-NCM networking drivers
- MT7981 PPE flow offload and WED support
- Hardware-offload runtime checker: `tr3000-offload-check`

## Not Included

- iStore
- AdGuard Home
- Preset root password or subscription configuration

## Tailscale Note

The community LuCI status, login, routes, exit-node, DNS, and firewall4
features are included. Its optional custom relay-server-port setting requires
Tailscale 1.90.5 or newer and is unavailable with the locked feeds version.

## Flash Safety

Only flash this image when all of the following are true:

- Device compatible contains `cudy,tr3000-mod`
- NAND revision is `F50L1G41LB`
- UBI partition size is `0x07000000` (112 MiB)
- A compatible 112M U-Boot layout is already installed

Do not preserve settings when migrating from a firewall3/iptables firmware.

## Verification

- Image size: 45,415,200 bytes
- SHA256:
  `5c50208325dae92741bd08a1b57859ac2ad3c8edbb06ff7f0d1dabeae7c73a11`
