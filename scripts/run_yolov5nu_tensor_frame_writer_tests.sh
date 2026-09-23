#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
test_tmp=$(mktemp -d /tmp/sixteen-camera-tensor-writer.XXXXXX)
trap 'rm -rf "$test_tmp"' EXIT

verilator --binary --timing -Wno-fatal \
    --top-module tb_yolov5nu_tensor_frame_writer \
    --Mdir "$test_tmp/obj" \
    "$root/rtl/interfaces/axi4_if.sv" \
    "$root/rtl/ai/preprocess/yolov5nu_tensor_stream_packer.sv" \
    "$root/legacy/rtl/yolov5nu_tensor_frame_writer.sv" \
    "$root/sim/tb_yolov5nu_tensor_frame_writer.sv" \
    >"$test_tmp/build.log"

"$test_tmp/obj/Vtb_yolov5nu_tensor_frame_writer"
"$test_tmp/obj/Vtb_yolov5nu_tensor_frame_writer" +bad_input
"$test_tmp/obj/Vtb_yolov5nu_tensor_frame_writer" +bad_response
"$test_tmp/obj/Vtb_yolov5nu_tensor_frame_writer" +page_boundary
"$test_tmp/obj/Vtb_yolov5nu_tensor_frame_writer" +abort
