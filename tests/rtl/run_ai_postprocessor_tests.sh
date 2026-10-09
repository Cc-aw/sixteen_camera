#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
if [[ -n "${PPU_TEST_CACHE:-}" ]]; then
    test_tmp="$PPU_TEST_CACHE/ai"
    mkdir -p "$test_tmp"
else
    test_tmp=$(mktemp -d /tmp/sixteen-camera-ai.XXXXXX)
    trap 'rm -rf -- "$test_tmp"' EXIT
fi
cd "$repo_dir"

bash ./tests/host/run_ai_postprocess_test.sh

verilator --binary --build-jobs "${VERILATOR_JOBS:-8}" --timing -Wno-fatal \
  --top-module tb_axi4_channel_join --Mdir "$test_tmp/channel_join" \
  hw/rtl/interfaces/axi4_if.sv \
  hw/rtl/bus/axi4_channel_join.sv \
  tests/rtl/benches/memory/tb_axi4_channel_join.sv
"$test_tmp/channel_join/Vtb_axi4_channel_join"

verilator --binary --build-jobs "${VERILATOR_JOBS:-8}" --timing -Wno-fatal \
  --top-module tb_axi4_write_cdc --Mdir "$test_tmp/write_cdc" \
  hw/rtl/interfaces/axi4_if.sv hw/rtl/bus/cdc_payload_fifo.sv \
  hw/rtl/bus/axi4_write_cdc.sv tests/rtl/benches/memory/tb_axi4_write_cdc.sv
"$test_tmp/write_cdc/Vtb_axi4_write_cdc"

verilator --binary --build-jobs "${VERILATOR_JOBS:-8}" --timing -Wno-fatal \
  --top-module tb_axi4_write_cdc_stress \
  --Mdir "$test_tmp/write_cdc_stress" \
  hw/rtl/interfaces/axi4_if.sv hw/rtl/bus/cdc_payload_fifo.sv \
  hw/rtl/bus/axi4_write_cdc.sv tests/rtl/benches/memory/tb_axi4_write_cdc_stress.sv
"$test_tmp/write_cdc_stress/Vtb_axi4_write_cdc_stress"

verilator --binary --build-jobs "${VERILATOR_JOBS:-8}" --timing -Wno-fatal \
  --top-module tb_fbus_read_engine --Mdir "$test_tmp/fbus_read" \
  -GSLOT_COUNT=18 -GREAD_ID_COUNT=18 -GID_WIDTH=5 \
  hw/rtl/interfaces/axi4_if.sv \
  hw/rtl/ai/postprocess/fbus_read_engine.sv \
  tests/rtl/benches/memory/tb_fbus_read_engine.sv
"$test_tmp/fbus_read/Vtb_fbus_read_engine"

verilator --binary --build-jobs "${VERILATOR_JOBS:-8}" --timing -Wno-fatal \
  --top-module tb_head_uram_local_reader --Mdir "$test_tmp/head_uram" \
  hw/rtl/ai/postprocess/head_uram_store.sv \
  hw/rtl/ai/postprocess/head_local_reader.sv \
  tests/rtl/benches/ppu/tb_head_uram_local_reader.sv
"$test_tmp/head_uram/Vtb_head_uram_local_reader"

for shadow in 0 1; do
  verilator --binary --build-jobs "${VERILATOR_JOBS:-8}" --timing -Wno-fatal \
    --top-module tb_axi4_head_uram_router \
    -GTEST_SHADOW_DDR="$shadow" \
    --Mdir "$test_tmp/head_router_$shadow" \
    hw/rtl/interfaces/axi4_if.sv \
    hw/rtl/ai/postprocess/head_uram_store.sv \
    hw/rtl/ai/postprocess/axi4_head_uram_router.sv \
    tests/rtl/benches/ppu/tb_axi4_head_uram_router.sv
  "$test_tmp/head_router_$shadow/Vtb_axi4_head_uram_router"
done

verilator --binary --build-jobs "${VERILATOR_JOBS:-8}" --timing -Wno-fatal \
  --top-module tb_postprocess_read_diagnostic \
  --Mdir "$test_tmp/read_diagnostic" \
  hw/rtl/interfaces/axi_lite_if.sv \
  hw/rtl/interfaces/axi4_if.sv \
  hw/rtl/ai/postprocess/fbus_read_engine.sv \
  hw/rtl/ai/postprocess/head_local_reader.sv \
  hw/rtl/ai/postprocess/yolov5nu_raw_class_lut.sv \
  hw/rtl/ai/postprocess/yolov5nu_dfl_lut.sv \
  hw/rtl/ai/postprocess/yolov5nu_class_fold_tree.sv \
  hw/rtl/ai/postprocess/yolov5nu_class_reducer_wide.sv \
  hw/rtl/ai/postprocess/yolov5nu_class_reducer.sv \
  hw/rtl/ai/postprocess/yolov5nu_probability_pipeline.sv \
  hw/rtl/ai/postprocess/yolov5nu_dfl_edge.sv \
  hw/rtl/ai/postprocess/yolov5nu_dfl_decoder.sv \
  hw/rtl/ai/postprocess/yolov5nu_bbox_decoder.sv \
  hw/rtl/ai/postprocess/yolov5nu_topk_nms.sv \
  hw/rtl/ai/postprocess/ppu_perf_counters.sv \
  hw/rtl/ai/postprocess/yolov5nu_candidate_buckets.sv \
  hw/rtl/ai/postprocess/yolov5nu_nms.sv \
  hw/rtl/ai/postprocess/yolov5nu_candidate_area.sv \
  hw/rtl/ai/postprocess/yolov5nu_iou_pipeline.sv \
  hw/rtl/ai/postprocess/yolov5nu_bucket_nms.sv \
  hw/rtl/ai/postprocess/yolov5nu_bbox_lut.sv \
  hw/rtl/ai/postprocess/yolov5nu_bbox_pipeline.sv \
  hw/rtl/ai/postprocess/yolov5nu_postprocessor.sv \
  hw/rtl/ai/postprocess/ppu_descriptor_fifo.sv \
  hw/rtl/ai/postprocess/ppu_command_queue.sv \
  hw/rtl/ai/postprocess/ppu_result_capture.sv \
  hw/rtl/ai/postprocess/ppu_result_fifo.sv \
  hw/rtl/ai/postprocess/ppu_overlay_label.sv \
  hw/rtl/ai/postprocess/ppu_result_manager.sv \
  hw/rtl/ai/postprocess/ppu_result_csr.sv \
  hw/rtl/ai/postprocess/ppu_result_path.sv \
  hw/rtl/ai/postprocess/ppu_queue_csr.sv \
  hw/rtl/ai/postprocess/ppu_publication_csr.sv \
  hw/rtl/ai/postprocess/ppu_publication_gate.sv \
  hw/rtl/ai/postprocess/postprocess_read_diagnostic.sv \
  tests/rtl/benches/ppu/tb_postprocess_read_diagnostic.sv
"$test_tmp/read_diagnostic/Vtb_postprocess_read_diagnostic"

bash ./tests/rtl/run_yolov5nu_postprocess_tests.sh

bash "$repo_dir/tests/rtl/run_ppu_publication_tests.sh"
"$repo_dir/tests/rtl/run_ppu_queue_tests.sh"
echo "AI_POSTPROCESSOR_TESTS=PASS"
