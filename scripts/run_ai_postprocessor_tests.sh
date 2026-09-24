#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
test_tmp=$(mktemp -d /tmp/sixteen-camera-postprocessor.XXXXXX)
trap 'rm -rf -- "$test_tmp"' EXIT
cd "$repo_dir"

bash ./sw/test/run_yolov2_fixed_ref_test.sh
bash ./sw/test/run_ai_postprocess_test.sh

verilator --binary --timing -Wno-fatal \
  --top-module tb_axi4_channel_join --Mdir "$test_tmp/channel_join" \
  rtl/interfaces/axi4_if.sv \
  rtl/bus/axi4_channel_join.sv \
  sim/tb_axi4_channel_join.sv
"$test_tmp/channel_join/Vtb_axi4_channel_join"

verilator --binary --timing -Wno-fatal \
  --top-module tb_axi4_write_cdc --Mdir "$test_tmp/write_cdc" \
  rtl/interfaces/axi4_if.sv rtl/bus/cdc_payload_fifo.sv \
  rtl/bus/axi4_write_cdc.sv sim/tb_axi4_write_cdc.sv
"$test_tmp/write_cdc/Vtb_axi4_write_cdc"

verilator --binary --timing -Wno-fatal \
  --top-module tb_axi4_write_cdc_stress \
  --Mdir "$test_tmp/write_cdc_stress" \
  rtl/interfaces/axi4_if.sv rtl/bus/cdc_payload_fifo.sv \
  rtl/bus/axi4_write_cdc.sv sim/tb_axi4_write_cdc_stress.sv
"$test_tmp/write_cdc_stress/Vtb_axi4_write_cdc_stress"

verilator --binary --timing -Wno-fatal \
  --top-module tb_fbus_read_engine --Mdir "$test_tmp/fbus_read" \
  -GSLOT_COUNT=18 -GREAD_ID_COUNT=18 -GID_WIDTH=5 \
  rtl/interfaces/axi4_if.sv \
  rtl/ai/postprocess/fbus_read_engine.sv \
  sim/tb_fbus_read_engine.sv
"$test_tmp/fbus_read/Vtb_fbus_read_engine"

verilator --binary --timing -Wno-fatal \
  --top-module tb_head_uram_local_reader --Mdir "$test_tmp/head_uram" \
  rtl/ai/postprocess/head_uram_store.sv \
  rtl/ai/postprocess/head_local_reader.sv \
  sim/tb_head_uram_local_reader.sv
"$test_tmp/head_uram/Vtb_head_uram_local_reader"

for shadow in 0 1; do
  verilator --binary --timing -Wno-fatal \
    --top-module tb_axi4_head_uram_router \
    -GTEST_SHADOW_DDR="$shadow" \
    --Mdir "$test_tmp/head_router_$shadow" \
    rtl/interfaces/axi4_if.sv \
    rtl/ai/postprocess/head_uram_store.sv \
    rtl/ai/postprocess/axi4_head_uram_router.sv \
    sim/tb_axi4_head_uram_router.sv
  "$test_tmp/head_router_$shadow/Vtb_axi4_head_uram_router"
done

verilator --binary --timing -Wno-fatal \
  --top-module tb_postprocess_read_diagnostic \
  --Mdir "$test_tmp/read_diagnostic" \
  rtl/interfaces/axi_lite_if.sv \
  rtl/interfaces/axi4_if.sv \
  rtl/ai/postprocess/fbus_read_engine.sv \
  rtl/ai/postprocess/head_local_reader.sv \
  rtl/ai/postprocess/yolov5nu_raw_class_lut.sv \
  rtl/ai/postprocess/yolov5nu_dfl_lut.sv \
  rtl/ai/postprocess/yolov5nu_class_reducer.sv \
  rtl/ai/postprocess/yolov5nu_dfl_decoder.sv \
  rtl/ai/postprocess/yolov5nu_bbox_decoder.sv \
  rtl/ai/postprocess/yolov5nu_topk_nms.sv \
  rtl/ai/postprocess/yolov5nu_postprocessor.sv \
  rtl/ai/postprocess/postprocess_read_diagnostic.sv \
  sim/tb_postprocess_read_diagnostic.sv
"$test_tmp/read_diagnostic/Vtb_postprocess_read_diagnostic"

bash ./scripts/run_yolov5nu_postprocess_tests.sh

echo "AI_POSTPROCESSOR_TESTS=PASS"
