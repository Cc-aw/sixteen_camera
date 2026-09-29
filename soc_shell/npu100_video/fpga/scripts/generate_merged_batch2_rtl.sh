#!/usr/bin/env bash
set -euo pipefail
npu_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
checkout=$(realpath "${CHIPYARD_ROOT:?Set CHIPYARD_ROOT to an isolated, complete Chipyard checkout}")
config=${CONFIG:-RocketSaturnGemmini64x64PackedInferenceRamMultiXCVU13PConfig}
package=${CONFIG_PACKAGE:-chipyard.fpga.xcvu13p_gemmini_64x64_packed_inference_ram}
model=${MODEL:-XCVU13PGemmini64x64PackedInferenceRamFPGATestHarness}
case "$config" in
  RocketSaturnGemmini64x64PackedInferenceRamMultiXCVU13PConfig|RocketSaturnGemmini64x64PackedInferenceRamXCVU13PConfig) ;;
  TaihangSoC1Rocket1RVV3Gemmini64x64PackedInference100MHzConfig) ;;
  *) echo "Unsupported merged configuration: $config" >&2; exit 2 ;;
esac
export CHIPYARD_ROOT="$checkout"
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/tmp}
export PATH="$checkout/.local/bin:$checkout/.local-espresso/bin:$checkout/.conda-env/riscv-tools/bin:$PATH"
if [[ -x "$checkout/.conda-env/lib/jvm/bin/java" ]]; then
  export JAVA_HOME="$checkout/.conda-env/lib/jvm"
  export PATH="$JAVA_HOME/bin:$PATH"
fi
bash "$npu_root/fpga/scripts/sync_npu_sys_to_chipyard.sh"
# Rebuild from source through Chipyard's normal SBT dependency graph. Do not
# inject classes into an unknown cached generator assembly.
# Always ask SBT to verify source contents. A failed elaboration can leave an
# assembly newer than a subsequently synchronized source with preserved mtime.
make -C "$checkout/fpga" -W "$checkout/build.sbt" verilog \
  SUB_PROJECT="${SUB_PROJECT:-taihang_soc}" \
  SBT_PROJECT=chipyard_fpga MODEL="$model" VLOG_MODEL="$model" \
  MODEL_PACKAGE="$package" CONFIG_PACKAGE="$package" CONFIG="$config" \
  GENERATOR_PACKAGE=chipyard TOP=ChipTop TB=none
rtl="$checkout/fpga/generated-src/$package.$model.$config/gen-collateral"
bash "$npu_root/fpga/scripts/apply_xcvu13p_gemmini_64x64_acc256_wide_uram.sh" "$rtl"
bash "$npu_root/fpga/scripts/apply_xcvu13p_soc_cache_bram.sh" "$rtl"
bash "$npu_root/fpga/scripts/apply_result_bram.sh" "$rtl"
instances=3
[[ "$config" != RocketSaturnGemmini64x64PackedInferenceRamXCVU13PConfig ]] || instances=1
python3 "$npu_root/tests/check_merged_rtl.py" "$rtl" "$instances" "$model"
mkdir -p "$rtl/include"
for header in "$checkout"/generators/gemmini/software/gemmini-rocc-tests/include/gemmini_params_64x64_ws_dual_int8_dsp_inference_ram*xcvu13p.h; do
  cp "$header" "$rtl/include/"
done
printf 'MERGED_RTL=%s\n' "$rtl"
