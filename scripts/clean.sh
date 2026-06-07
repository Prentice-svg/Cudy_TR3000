#!/usr/bin/env bash

set -euo pipefail

BUILD_ROOT="${BUILD_ROOT:-/root/cudy-tr3000-build}"
rm -rf "$BUILD_ROOT/lede/bin" "$BUILD_ROOT/lede/build_dir" \
  "$BUILD_ROOT/lede/staging_dir" "$BUILD_ROOT/lede/tmp"

