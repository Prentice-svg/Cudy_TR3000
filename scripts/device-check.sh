#!/bin/sh

set -u

echo "== Cudy TR3000 112M pre-flash check =="

echo
echo "-- Model and compatible --"
tr '\0' '\n' </proc/device-tree/model 2>/dev/null || true
tr '\0' '\n' </proc/device-tree/compatible 2>/dev/null || true

echo
echo "-- NAND identification --"
dmesg | grep -Ei 'spi.?nand|nand|F50L1G41L[BC]' | tail -30

echo
echo "-- MTD layout --"
cat /proc/mtd

echo
echo "-- UBI --"
ubinfo -a 2>/dev/null || true

echo
case "$(tr '\0' '\n' </proc/device-tree/compatible 2>/dev/null)" in
  *cudy,tr3000-mod*) echo "PASS: compatible contains cudy,tr3000-mod" ;;
  *) echo "FAIL: compatible does not contain cudy,tr3000-mod" ;;
esac

if dmesg | grep -q 'F50L1G41LB'; then
  echo "PASS: old F50L1G41LB NAND detected"
elif dmesg | grep -q 'F50L1G41LC'; then
  echo "FAIL: newer F50L1G41LC NAND detected; do not flash"
else
  echo "WARN: NAND revision was not found in dmesg"
fi

ubi_hex="$(awk -F'[: ]+' '$4=="\"ubi\"" {print $3}' /proc/mtd | head -1)"
case "$ubi_hex" in
  07000000) echo "PASS: UBI partition is 112 MiB (0x07000000)" ;;
  *) echo "FAIL: UBI partition is ${ubi_hex:-unknown}, expected 07000000" ;;
esac

