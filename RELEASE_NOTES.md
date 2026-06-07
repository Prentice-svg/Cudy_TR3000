# Cudy TR3000 112M LEDE v2026.06.07-r1

This release targets the old 128 MB NAND Cudy TR3000 using the
`cudy_tr3000-mod` 112 MiB UBI partition layout.

## Included

- LEDE/OpenWrt 24.10.5, Linux 6.12.92
- OpenClash 0.47.097
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

## Flash Safety

Only flash this image when all of the following are true:

- Device compatible contains `cudy,tr3000-mod`
- NAND revision is `F50L1G41LB`
- UBI partition size is `0x07000000` (112 MiB)
- A compatible 112M U-Boot layout is already installed

Do not preserve settings when migrating from a firewall3/iptables firmware.

## Verification

- Image size: 37,745,440 bytes
- SHA256:
  `a4f674d59c69934c269b0ab22ce08c643d997a31e123618389023251844dfe26`

