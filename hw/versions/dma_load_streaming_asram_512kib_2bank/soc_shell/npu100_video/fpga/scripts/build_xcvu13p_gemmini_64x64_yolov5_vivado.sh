#!/usr/bin/env bash
set -euo pipefail
echo "This legacy board recipe predates the merged ACC256 and axi4_fbus/axi4_mmio ports." >&2
echo "Use fpga/scripts/generate_merged_batch2_rtl.sh and connect those ports in your board wrapper." >&2
exit 2

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
generated_dir="$repo_root/fpga/generated-src/xcvu13p_gemmini_64x64_yolov5/gen-collateral"
vivado_bin=${VIVADO_BIN:-vivado}

# Generate only this configuration's RTL. No synthesis or implementation is
# launched here; Vivado is used only to create the independent project.
make -C "$repo_root/fpga" verilog \
  SBT_PROJECT=chipyard_fpga \
  MODEL=XCVU13PGemmini64x64YoloV5TrimmedFPGATestHarness \
  VLOG_MODEL=XCVU13PGemmini64x64YoloV5TrimmedFPGATestHarness \
  MODEL_PACKAGE=chipyard.fpga.xcvu13p_gemmini_64x64_yolov5 \
  CONFIG=RocketSaturnGemmini64x64YoloV5TrimmedXCVU13PConfig \
  CONFIG_PACKAGE=chipyard.fpga.xcvu13p_gemmini_64x64_yolov5 \
  GENERATOR_PACKAGE=chipyard \
  TOP=ChipTop TB=none \
  GEN_COLLATERAL_DIR="$generated_dir"

project_dir="$repo_root/fpga/vivado/xcvu13p-gemmini-64x64-yolov5-trimmed-demo"
cd "$project_dir"
"$vivado_bin" -mode batch -source create_project.tcl
"$vivado_bin" -mode batch -source check_project.tcl

printf 'VIVADO_PROJECT=%s\n' "$project_dir/xcvu13p_gemmini_64x64_yolov5_trimmed.xpr"
