#!/usr/bin/env bash
set -Eeuo pipefail

readonly config="TaihangSoC1Rocket1RVV2Gemmini16x16PackedFullOps256BitConfig"
readonly tree="tsmcchip.fpga.taihangsoc.TaihangSoCFPGATestHarness.${config}"

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
chipyard_root=${1:-}
if [[ -z "$chipyard_root" ]]; then
  if [[ -d "$script_dir/../fpga" ]]; then
    chipyard_root=$(cd "$script_dir/.." && pwd)
  else
    echo "Usage: $0 CHIPYARD_ROOT" >&2
    exit 2
  fi
fi

out="$chipyard_root/fpga/generated-src/$tree"
rtl="$out/gen-collateral"
for file in \
  "$rtl/TaihangSoCFPGATestHarness.sv" \
  "$rtl/RocketTile.sv" \
  "$rtl/SaturnRocketUnit.sv" \
  "$rtl/Gemmini.sv" \
  "$rtl/Gemmini_1.sv" \
  "$out/model_module_hierarchy.json"; do
  [[ -s "$file" ]] || { echo "missing generated file: $file" >&2; exit 1; }
done

gemmini_modules=$(rg -l '^module Gemmini(_1)?\(' "$rtl/Gemmini.sv" "$rtl/Gemmini_1.sv" | wc -l)
[[ "$gemmini_modules" -eq 2 ]] || {
  echo "expected two Gemmini modules, found $gemmini_modules" >&2
  exit 1
}
rg -q '^module RocketTile\(' "$rtl/RocketTile.sv"
rg -q '^module SaturnRocketUnit\(' "$rtl/SaturnRocketUnit.sv"
rg -q 'input  \[255:0\].*axi4_fbus' "$rtl/TaihangSoCFPGATestHarness.sv" || \
  rg -q '\[255:0\].*fbus' "$rtl/TaihangSoCFPGATestHarness.sv"

echo "GENERATED_SOC_VERIFY=PASS"
echo "CONFIG=$config"
echo "ROCKETS=1"
echo "SATURN_RVV=1"
echo "GEMMINI_16X16_PACKED=2"
echo "COLLATERAL=$out"
