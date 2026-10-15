#!/usr/bin/env bash
set -euo pipefail
echo "This legacy board recipe predates the merged ACC256 and axi4_fbus/axi4_mmio ports." >&2
echo "Use fpga/scripts/generate_merged_batch2_rtl.sh and connect those ports in your board wrapper." >&2
exit 2

npu_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
chipyard_root=${CHIPYARD_ROOT:?Set CHIPYARD_ROOT to a complete Chipyard checkout}
base_project=${XCVU13P_BASE_PROJECT:?Set XCVU13P_BASE_PROJECT to an XCVU13P board baseline .xpr}
vivado_bin=${VIVADO_BIN:-vivado}
generated_dir=${GEN_COLLATERAL_DIR:-"$chipyard_root/fpga/generated-src/xcvu13p_gemmini_64x64_packed_inference_ram_single_silu/gen-collateral"}
project_dir="$npu_root/fpga/vivado/xcvu13p-gemmini-64x64-packed-inference-ram-single-silu-wide-uram-slr-demo"

if [[ -z ${JAVA_HOME:-} && -x "$chipyard_root/.conda-env/lib/jvm/bin/java" ]]; then
  export JAVA_HOME="$chipyard_root/.conda-env/lib/jvm"
  export PATH="$JAVA_HOME/bin:$PATH"
fi
if [[ -x "$chipyard_root/.local-espresso/bin/espresso" ]]; then
  export PATH="$chipyard_root/.local-espresso/bin:$PATH"
elif [[ -x "$chipyard_root/.conda-env/riscv-tools/bin/espresso" ]]; then
  export PATH="$chipyard_root/.conda-env/riscv-tools/bin:$PATH"
fi
if [[ -x "$chipyard_root/.conda-env/riscv-tools/bin/firtool" ]]; then
  export PATH="$chipyard_root/.conda-env/riscv-tools/bin:$PATH"
fi

"$npu_root/fpga/scripts/sync_npu_sys_to_chipyard.sh"

# Force a fresh elaboration so this recipe cannot import stale collateral.
make -B -C "$chipyard_root/fpga" verilog \
  SBT_PROJECT=chipyard_fpga \
  MODEL=XCVU13PGemmini64x64PackedInferenceRamFPGATestHarness \
  VLOG_MODEL=XCVU13PGemmini64x64PackedInferenceRamFPGATestHarness \
  MODEL_PACKAGE=chipyard.fpga.xcvu13p_gemmini_64x64_packed_inference_ram \
  CONFIG=RocketSaturnGemmini64x64PackedInferenceRamXCVU13PConfig \
  CONFIG_PACKAGE=chipyard.fpga.xcvu13p_gemmini_64x64_packed_inference_ram \
  GENERATOR_PACKAGE=chipyard TOP=ChipTop TB=none \
  GEN_COLLATERAL_DIR="$generated_dir"

[[ -d "$generated_dir" ]] || { echo "Error: RTL was not generated: $generated_dir" >&2; exit 1; }
cd "$project_dir"
XCVU13P_BASE_PROJECT="$base_project" GEMMINI_64_RTL_DIR="$generated_dir" \
  "$vivado_bin" -mode batch -source create_project.tcl
"$vivado_bin" -mode batch -source check_project.tcl

printf 'VIVADO_PROJECT=%s\n' "$project_dir/xcvu13p_gemmini_64x64_packed_inference_ram_single_silu_wide_uram_slr.xpr"
