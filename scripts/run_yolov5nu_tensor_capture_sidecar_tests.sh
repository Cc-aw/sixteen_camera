#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
test_tmp=$(mktemp -d /tmp/sixteen-camera-sidecar.XXXXXX)
trap 'rm -rf "$test_tmp"' EXIT
verilator --binary --timing -Wno-fatal \
    --top-module tb_yolov5nu_tensor_capture_sidecar \
    --Mdir "$test_tmp/obj" \
    "$root/rtl/interfaces/axi4_if.sv" \
    "$root/rtl/ai/preprocess/yolov5nu_tensor_stream_packer.sv" \
    "$root/rtl/rtl_old/yolov5nu_tensor_frame_writer.sv" \
    "$root/rtl/rtl_old/yolov5nu_tensor_capture_sidecar.sv" \
    "$root/sim/tb_yolov5nu_tensor_capture_sidecar.sv" \
    >"$test_tmp/build.log"
"$test_tmp/obj/Vtb_yolov5nu_tensor_capture_sidecar"
"$test_tmp/obj/Vtb_yolov5nu_tensor_capture_sidecar" +overflow
