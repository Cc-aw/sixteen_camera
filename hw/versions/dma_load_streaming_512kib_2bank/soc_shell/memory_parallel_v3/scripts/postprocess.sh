#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
rtl=$(realpath "${1:?Generated V3 gen-collateral directory required}")
[[ "$rtl" == *TaihangSoC1Rocket1RVV3Gemmini32x32MemoryParallelV3Config/gen-collateral ]]
scripts="$root/soc_shell/npu100_video/fpga/scripts"
# These are the same memory-inference transformations as the passing V1.
# They preserve capacities/ports and do not implement the V3 functionality.
bash "$scripts/apply_xcvu13p_gemmini_32x32_acc256_wide_uram.sh" "$rtl"
bash "$scripts/apply_xcvu13p_soc_cache_bram.sh" "$rtl"
bash "$scripts/apply_result_bram.sh" "$rtl"
