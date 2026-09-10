#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
test_tmp=$(mktemp -d /tmp/sixteen-camera-postprocessor.XXXXXX)
trap 'rm -rf -- "$test_tmp"' EXIT
cd "$repo_dir"

./sw/test/run_yolov2_fixed_ref_test.sh
./sw/test/run_ai_postprocess_test.sh

verilator --binary --timing -Wno-fatal \
  --top-module tb_axi4_channel_join --Mdir "$test_tmp/channel_join" \
  rtl/interfaces/axi4_if.sv \
  rtl/bus/axi4_channel_join.sv \
  sim/tb_axi4_channel_join.sv
"$test_tmp/channel_join/Vtb_axi4_channel_join"

verilator --binary --timing -Wno-fatal \
  --top-module tb_fbus_read_engine --Mdir "$test_tmp/fbus_read" \
  rtl/interfaces/axi4_if.sv \
  rtl/ai/postprocess/fbus_read_engine.sv \
  sim/tb_fbus_read_engine.sv
"$test_tmp/fbus_read/Vtb_fbus_read_engine"

verilator --binary --timing -Wno-fatal \
  --top-module tb_postprocess_read_diagnostic \
  --Mdir "$test_tmp/read_diagnostic" \
  rtl/interfaces/axi_lite_if.sv \
  rtl/interfaces/axi4_if.sv \
  rtl/ai/postprocess/fbus_read_engine.sv \
  rtl/ai/postprocess/postprocess_read_diagnostic.sv \
  sim/tb_postprocess_read_diagnostic.sv
"$test_tmp/read_diagnostic/Vtb_postprocess_read_diagnostic"

echo "AI_POSTPROCESSOR_TESTS=PASS"
