#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
if [[ -n "${PPU_TEST_CACHE:-}" ]]; then
    test_tmp="$PPU_TEST_CACHE/ai"
    mkdir -p "$test_tmp"
else
    test_tmp=$(mktemp -d /tmp/sixteen-camera-ai.XXXXXX)
    trap 'rm -rf -- "$test_tmp"' EXIT
fi
cd "$repo_dir"

bash ./sw/test/run_yolov2_fixed_ref_test.sh
bash ./sw/test/run_ai_postprocess_test.sh

verilator --binary --build-jobs "${VERILATOR_JOBS:-8}" --timing -Wno-fatal \
  --top-module tb_axi4_channel_join --Mdir "$test_tmp/channel_join" \
  rtl/interfaces/axi4_if.sv \
  rtl/bus/axi4_channel_join.sv \
  sim/tb_axi4_channel_join.sv
"$test_tmp/channel_join/Vtb_axi4_channel_join"

verilator --binary --build-jobs "${VERILATOR_JOBS:-8}" --timing -Wno-fatal \
  --top-module tb_axi4_write_cdc --Mdir "$test_tmp/write_cdc" \
  rtl/interfaces/axi4_if.sv rtl/bus/cdc_payload_fifo.sv \
  rtl/bus/axi4_write_cdc.sv sim/tb_axi4_write_cdc.sv
"$test_tmp/write_cdc/Vtb_axi4_write_cdc"

verilator --binary --build-jobs "${VERILATOR_JOBS:-8}" --timing -Wno-fatal \
  --top-module tb_axi4_write_cdc_stress \
  --Mdir "$test_tmp/write_cdc_stress" \
  rtl/interfaces/axi4_if.sv rtl/bus/cdc_payload_fifo.sv \
  rtl/bus/axi4_write_cdc.sv sim/tb_axi4_write_cdc_stress.sv
"$test_tmp/write_cdc_stress/Vtb_axi4_write_cdc_stress"

verilator --binary --build-jobs "${VERILATOR_JOBS:-8}" --timing -Wno-fatal \
  --top-module tb_fbus_read_engine --Mdir "$test_tmp/fbus_read" \
  -GSLOT_COUNT=18 -GREAD_ID_COUNT=18 -GID_WIDTH=5 \
  rtl/interfaces/axi4_if.sv \
  rtl/ai/postprocess/fbus_read_engine.sv \
  sim/tb_fbus_read_engine.sv
"$test_tmp/fbus_read/Vtb_fbus_read_engine"

verilator --binary --build-jobs "${VERILATOR_JOBS:-8}" --timing -Wno-fatal \
  --top-module tb_head_uram_local_reader --Mdir "$test_tmp/head_uram" \
  rtl/ai/postprocess/head_uram_store.sv \
  rtl/ai/postprocess/head_local_reader.sv \
  sim/tb_head_uram_local_reader.sv
"$test_tmp/head_uram/Vtb_head_uram_local_reader"

for shadow in 0 1; do
  verilator --binary --build-jobs "${VERILATOR_JOBS:-8}" --timing -Wno-fatal \
    --top-module tb_axi4_head_uram_router \
    -GTEST_SHADOW_DDR="$shadow" \
    --Mdir "$test_tmp/head_router_$shadow" \
    rtl/interfaces/axi4_if.sv \
    rtl/ai/postprocess/head_uram_store.sv \
    rtl/ai/postprocess/axi4_head_uram_router.sv \
    sim/tb_axi4_head_uram_router.sv
  "$test_tmp/head_router_$shadow/Vtb_axi4_head_uram_router"
done

verilator --binary --build-jobs "${VERILATOR_JOBS:-8}" --timing -Wno-fatal \
  --top-module tb_postprocess_read_diagnostic \
  --Mdir "$test_tmp/read_diagnostic" \
  rtl/interfaces/axi_lite_if.sv \
  rtl/interfaces/axi4_if.sv \
  rtl/ai/postprocess/fbus_read_engine.sv \
  rtl/ai/postprocess/head_local_reader.sv \
  rtl/ai/postprocess/yolov5nu_raw_class_lut.sv \
  rtl/ai/postprocess/yolov5nu_dfl_lut.sv \
  rtl/ai/postprocess/yolov5nu_class_fold_tree.sv \
  rtl/ai/postprocess/yolov5nu_class_reducer_wide.sv \
  rtl/ai/postprocess/yolov5nu_class_reducer.sv \
  rtl/ai/postprocess/yolov5nu_probability_pipeline.sv \
  rtl/ai/postprocess/yolov5nu_dfl_edge.sv \
  rtl/ai/postprocess/yolov5nu_dfl_decoder.sv \
  rtl/ai/postprocess/yolov5nu_bbox_decoder.sv \
  rtl/ai/postprocess/yolov5nu_topk_nms.sv \
  rtl/ai/postprocess/ppu_perf_counters.sv \
  rtl/ai/postprocess/yolov5nu_candidate_buckets.sv \
  rtl/ai/postprocess/yolov5nu_nms.sv \
  rtl/ai/postprocess/yolov5nu_candidate_area.sv \
  rtl/ai/postprocess/yolov5nu_iou_pipeline.sv \
  rtl/ai/postprocess/yolov5nu_bucket_nms.sv \
  rtl/ai/postprocess/yolov5nu_bbox_lut.sv \
  rtl/ai/postprocess/yolov5nu_bbox_pipeline.sv \
  rtl/ai/postprocess/yolov5nu_postprocessor.sv \
  rtl/ai/postprocess/ppu_descriptor_fifo.sv \
  rtl/ai/postprocess/ppu_command_queue.sv \
  rtl/ai/postprocess/ppu_result_capture.sv \
  rtl/ai/postprocess/ppu_result_fifo.sv \
  rtl/ai/postprocess/ppu_overlay_label.sv \
  rtl/ai/postprocess/ppu_result_manager.sv \
  rtl/ai/postprocess/ppu_result_csr.sv \
  rtl/ai/postprocess/ppu_result_path.sv \
  rtl/ai/postprocess/ppu_queue_csr.sv \
  rtl/ai/postprocess/ppu_publication_csr.sv \
  rtl/ai/postprocess/ppu_publication_gate.sv \
  rtl/ai/postprocess/postprocess_read_diagnostic.sv \
  sim/tb_postprocess_read_diagnostic.sv
"$test_tmp/read_diagnostic/Vtb_postprocess_read_diagnostic"

bash ./scripts/run_yolov5nu_postprocess_tests.sh

bash "$repo_dir/scripts/run_ppu_publication_tests.sh"
"$repo_dir/scripts/run_ppu_queue_tests.sh"
echo "AI_POSTPROCESSOR_TESTS=PASS"
