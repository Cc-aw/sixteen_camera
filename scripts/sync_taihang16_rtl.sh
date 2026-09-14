#!/usr/bin/env bash
set -Eeuo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
chipyard_root="${CHIPYARD_ROOT:-/home/wzr/chipyard}"
config=TaihangSoC1Rocket1RVV2Gemmini16x16PackedFullOps256BitConfig
tree=tsmcchip.fpga.taihangsoc.TaihangSoCFPGATestHarness.$config
source_dir="$chipyard_root/fpga/generated-src/$tree/gen-collateral"
target_dir="$repo_dir/rtl/soc/$tree/gen-collateral"

[[ -f "$source_dir/AXI4ToTL.sv" ]] || {
  echo "missing generated collateral: $source_dir" >&2
  exit 1
}

# Preserve 32 physical AXI ID groups, each with two read sources.
python3 "$repo_dir/scripts/check_fbus_id_groups.py" "$source_dir"

mkdir -p "$target_dir"
rsync -rt --delete "$source_dir/" "$target_dir/"

echo "SOC_COLLATERAL_SYNC=PASS"
echo "SOURCE_BITS=7"
echo "READ_SOURCES=64"
echo "TARGET=$target_dir"
