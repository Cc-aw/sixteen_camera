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

# P1C-2 requires 7-bit TL sources. With the current Rocket-Chip adapter this
# produces two physical AXI ID groups with 32 read source counters each.
grep -Eq 'output \[6:0\][[:space:]]+auto_out_a_bits_source' \
  "$source_dir/AXI4ToTL.sv" || {
  echo "generated AXI4ToTL does not expose a 7-bit source" >&2
  exit 1
}
grep -Eq 'reg[[:space:]]+\[5:0\][[:space:]]+r_count_0' \
  "$source_dir/AXI4ToTL.sv" || {
  echo "generated AXI4ToTL does not contain 32 read sources per ID group" >&2
  exit 1
}

mkdir -p "$target_dir"
rsync -rt --delete "$source_dir/" "$target_dir/"

echo "SOC_COLLATERAL_SYNC=PASS"
echo "SOURCE_BITS=7"
echo "READ_SOURCES=64"
echo "TARGET=$target_dir"
