#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
if [[ -n "${PPU_TEST_CACHE:-}" ]]; then
    test_tmp="$PPU_TEST_CACHE/yolo"
    mkdir -p "$test_tmp"
else
    test_tmp=$(mktemp -d /tmp/sixteen-camera-yolo.XXXXXX)
    trap 'rm -rf -- "$test_tmp"' EXIT
fi

bash "$root/sw/test/run_ai_head_slot_queue_test.sh"

python3 "$root/scripts/generate_yolov5nu_class_reducer_vectors.py" \
  --reference "$root/sw/yolov5/generators/gemmini/software/gemmini-ort/models/detection/stage8_640x480_hardware_aware/hardware_integer_reference.npz" \
  --image 025 --output-dir "$test_tmp"

verilator --binary --build-jobs "${VERILATOR_JOBS:-8}" --timing -Wall -Wno-fatal \
  --Mdir "$test_tmp/obj" \
  "$root/rtl/ai/postprocess/yolov5nu_class_fold_tree.sv" \
  "$root/rtl/ai/postprocess/yolov5nu_class_reducer_wide.sv" \
  "$root/rtl/ai/postprocess/yolov5nu_class_reducer.sv" \
  "$root/sim/tb_yolov5nu_class_reducer.sv" \
  --top-module tb_yolov5nu_class_reducer

(cd "$test_tmp" && "$test_tmp/obj/Vtb_yolov5nu_class_reducer")
(cd "$test_tmp" && "$test_tmp/obj/Vtb_yolov5nu_class_reducer" +synthetic)

iverilog -g2012 -s tb_yolov5nu_topk_nms \
  -o "$test_tmp/topk_nms" \
  "$root/rtl/ai/postprocess/yolov5nu_topk_nms.sv" \
  "$root/sim/tb_yolov5nu_topk_nms.sv"
vvp "$test_tmp/topk_nms"

iverilog -g2012 -s tb_yolov5nu_topk_nms_capacity \
  -o "$test_tmp/topk_nms_capacity" \
  "$root/rtl/ai/postprocess/yolov5nu_topk_nms.sv" \
  "$root/sim/tb_yolov5nu_topk_nms_capacity.sv"
vvp "$test_tmp/topk_nms_capacity"

iverilog -g2012 -s tb_yolov5nu_dfl_decoder \
  -o "$test_tmp/dfl_decoder" \
  "$root/rtl/ai/postprocess/yolov5nu_dfl_lut.sv" \
  "$root/rtl/ai/postprocess/yolov5nu_probability_pipeline.sv" \
  "$root/rtl/ai/postprocess/yolov5nu_dfl_edge.sv" \
  "$root/rtl/ai/postprocess/yolov5nu_dfl_decoder.sv" \
  "$root/sim/tb_yolov5nu_dfl_decoder.sv"
vvp "$test_tmp/dfl_decoder"

python3 "$root/scripts/generate_yolov5nu_dfl_vectors.py" \
  --output-dir "$test_tmp"
iverilog -g2012 -s tb_yolov5nu_dfl_random \
  -o "$test_tmp/dfl_random" \
  "$root/rtl/ai/postprocess/yolov5nu_dfl_lut.sv" \
  "$root/rtl/ai/postprocess/yolov5nu_probability_pipeline.sv" \
  "$root/rtl/ai/postprocess/yolov5nu_dfl_edge.sv" \
  "$root/rtl/ai/postprocess/yolov5nu_dfl_decoder.sv" \
  "$root/sim/tb_yolov5nu_dfl_random.sv"
(cd "$test_tmp" && vvp "$test_tmp/dfl_random")

iverilog -g2012 -s tb_yolov5nu_image025_postprocess \
  -o "$test_tmp/image025" \
  "$root/rtl/ai/postprocess/yolov5nu_bbox_decoder.sv" \
  "$root/rtl/ai/postprocess/yolov5nu_topk_nms.sv" \
  "$root/sim/tb_yolov5nu_image025_postprocess.sv"
(cd "$test_tmp" && vvp "$test_tmp/image025")

verilator --binary --build-jobs "${VERILATOR_JOBS:-8}" --timing -Wno-fatal \
  --Mdir "$test_tmp/obj_integrated" \
  "$root/rtl/ai/postprocess/yolov5nu_raw_class_lut.sv" \
  "$root/rtl/ai/postprocess/yolov5nu_dfl_lut.sv" \
  "$root/rtl/ai/postprocess/yolov5nu_class_fold_tree.sv" \
  "$root/rtl/ai/postprocess/yolov5nu_class_reducer_wide.sv" \
  "$root/rtl/ai/postprocess/yolov5nu_class_reducer.sv" \
  "$root/rtl/ai/postprocess/yolov5nu_probability_pipeline.sv" \
  "$root/rtl/ai/postprocess/yolov5nu_dfl_edge.sv" \
  "$root/rtl/ai/postprocess/yolov5nu_dfl_decoder.sv" \
  "$root/rtl/ai/postprocess/yolov5nu_bbox_decoder.sv" \
  "$root/rtl/ai/postprocess/yolov5nu_topk_nms.sv" \
  "$root/rtl/ai/postprocess/ppu_perf_counters.sv" \
  "$root/rtl/ai/postprocess/yolov5nu_candidate_buckets.sv" \
  "$root/rtl/ai/postprocess/yolov5nu_nms.sv" \
  "$root/rtl/ai/postprocess/yolov5nu_candidate_area.sv" \
  "$root/rtl/ai/postprocess/yolov5nu_iou_pipeline.sv" \
  "$root/rtl/ai/postprocess/yolov5nu_bucket_nms.sv" \
  "$root/rtl/ai/postprocess/yolov5nu_bbox_lut.sv" \
  "$root/rtl/ai/postprocess/yolov5nu_bbox_pipeline.sv" \
  "$root/rtl/ai/postprocess/yolov5nu_postprocessor.sv" \
  "$root/sim/tb_yolov5nu_postprocessor.sv" \
  --top-module tb_yolov5nu_postprocessor
(cd "$test_tmp" && "$test_tmp/obj_integrated/Vtb_yolov5nu_postprocessor")
(cd "$test_tmp" && "$test_tmp/obj_integrated/Vtb_yolov5nu_postprocessor" +dense)
(cd "$test_tmp" && "$test_tmp/obj_integrated/Vtb_yolov5nu_postprocessor" +empty)

python3 "$root/scripts/check_yolov5nu_nms_quantization.py"

iverilog -g2012 -s tb_yolov5nu_bucket_sort -o "$test_tmp/bucket_sort" \
  "$root/rtl/ai/postprocess/yolov5nu_candidate_buckets.sv" \
  "$root/rtl/ai/postprocess/yolov5nu_nms.sv" \
  "$root/rtl/ai/postprocess/yolov5nu_candidate_area.sv" \
  "$root/rtl/ai/postprocess/yolov5nu_iou_pipeline.sv" \
  "$root/rtl/ai/postprocess/yolov5nu_bucket_nms.sv" \
  "$root/sim/tb_yolov5nu_bucket_sort.sv"
vvp "$test_tmp/bucket_sort"

verilator --binary --build-jobs "${VERILATOR_JOBS:-8}" --timing -Wno-fatal \
  --Mdir "$test_tmp/bbox_pipeline" --top-module tb_yolov5nu_bbox_pipeline \
  "$root/rtl/ai/postprocess/yolov5nu_bbox_decoder.sv" \
  "$root/rtl/ai/postprocess/yolov5nu_bbox_lut.sv" \
  "$root/rtl/ai/postprocess/yolov5nu_bbox_pipeline.sv" \
  "$root/sim/tb_yolov5nu_bbox_pipeline.sv"
"$test_tmp/bbox_pipeline/Vtb_yolov5nu_bbox_pipeline"

iverilog -g2012 -s tb_yolov5nu_probability_pipeline -o "$test_tmp/probability" \
  "$root/rtl/ai/postprocess/yolov5nu_probability_pipeline.sv" \
  "$root/sim/tb_yolov5nu_probability_pipeline.sv"
vvp "$test_tmp/probability"

verilator --binary --build-jobs "${VERILATOR_JOBS:-8}" --timing -Wno-fatal \
  --Mdir "$test_tmp/class32" --top-module tb_yolov5nu_class_reducer -GFOLD_BYTES=32 \
  "$root/rtl/ai/postprocess/yolov5nu_class_fold_tree.sv" \
  "$root/rtl/ai/postprocess/yolov5nu_class_reducer_wide.sv" \
  "$root/rtl/ai/postprocess/yolov5nu_class_reducer.sv" \
  "$root/sim/tb_yolov5nu_class_reducer.sv"
(cd "$test_tmp" && "$test_tmp/class32/Vtb_yolov5nu_class_reducer")
(cd "$test_tmp" && "$test_tmp/class32/Vtb_yolov5nu_class_reducer" +synthetic)
