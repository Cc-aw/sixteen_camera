#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
test_tmp=$(mktemp -d /tmp/sixteen-camera-yolov5nu-post.XXXXXX)
trap 'rm -rf "$test_tmp"' EXIT

python3 "$root/scripts/generate_yolov5nu_class_reducer_vectors.py" \
  --reference "$root/sw/yolov5/generators/gemmini/software/gemmini-ort/models/detection/stage8_640x480_hardware_aware/hardware_integer_reference.npz" \
  --image 025 --output-dir "$test_tmp"

verilator --binary --timing -Wall -Wno-fatal \
  --Mdir "$test_tmp/obj" \
  "$root/rtl/ai/postprocess/yolov5nu_class_reducer.sv" \
  "$root/sim/tb_yolov5nu_class_reducer.sv" \
  --top-module tb_yolov5nu_class_reducer

(cd "$test_tmp" && "$test_tmp/obj/Vtb_yolov5nu_class_reducer")

iverilog -g2012 -s tb_yolov5nu_topk_nms \
  -o "$test_tmp/topk_nms" \
  "$root/rtl/ai/postprocess/yolov5nu_topk_nms.sv" \
  "$root/sim/tb_yolov5nu_topk_nms.sv"
vvp "$test_tmp/topk_nms"

iverilog -g2012 -s tb_yolov5nu_dfl_decoder \
  -o "$test_tmp/dfl_decoder" \
  "$root/rtl/ai/postprocess/yolov5nu_dfl_lut.sv" \
  "$root/rtl/ai/postprocess/yolov5nu_dfl_decoder.sv" \
  "$root/sim/tb_yolov5nu_dfl_decoder.sv"
vvp "$test_tmp/dfl_decoder"

python3 "$root/scripts/generate_yolov5nu_dfl_vectors.py" \
  --output-dir "$test_tmp"
iverilog -g2012 -s tb_yolov5nu_dfl_random \
  -o "$test_tmp/dfl_random" \
  "$root/rtl/ai/postprocess/yolov5nu_dfl_lut.sv" \
  "$root/rtl/ai/postprocess/yolov5nu_dfl_decoder.sv" \
  "$root/sim/tb_yolov5nu_dfl_random.sv"
(cd "$test_tmp" && vvp "$test_tmp/dfl_random")

iverilog -g2012 -s tb_yolov5nu_image025_postprocess \
  -o "$test_tmp/image025" \
  "$root/rtl/ai/postprocess/yolov5nu_bbox_decoder.sv" \
  "$root/rtl/ai/postprocess/yolov5nu_topk_nms.sv" \
  "$root/sim/tb_yolov5nu_image025_postprocess.sv"
(cd "$test_tmp" && vvp "$test_tmp/image025")

verilator --binary --timing -Wno-fatal \
  --Mdir "$test_tmp/obj_integrated" \
  "$root/rtl/ai/postprocess/yolov5nu_raw_class_lut.sv" \
  "$root/rtl/ai/postprocess/yolov5nu_dfl_lut.sv" \
  "$root/rtl/ai/postprocess/yolov5nu_class_reducer.sv" \
  "$root/rtl/ai/postprocess/yolov5nu_dfl_decoder.sv" \
  "$root/rtl/ai/postprocess/yolov5nu_bbox_decoder.sv" \
  "$root/rtl/ai/postprocess/yolov5nu_topk_nms.sv" \
  "$root/rtl/ai/postprocess/yolov5nu_postprocessor.sv" \
  "$root/sim/tb_yolov5nu_postprocessor.sv" \
  --top-module tb_yolov5nu_postprocessor
(cd "$test_tmp" && "$test_tmp/obj_integrated/Vtb_yolov5nu_postprocessor")
(cd "$test_tmp" && "$test_tmp/obj_integrated/Vtb_yolov5nu_postprocessor" +dense)
(cd "$test_tmp" && "$test_tmp/obj_integrated/Vtb_yolov5nu_postprocessor" +empty)

python3 "$root/scripts/check_yolov5nu_nms_quantization.py"
