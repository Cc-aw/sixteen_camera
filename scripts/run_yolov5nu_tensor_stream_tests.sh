#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
test_tmp=$(mktemp -d /tmp/sixteen-camera-tensor-stream.XXXXXX)
trap 'rm -rf "$test_tmp"' EXIT

iverilog -g2012 -s tb_yolov5nu_tensor_stream_packer \
    -o "$test_tmp/packer" \
    "$root/rtl/ai/preprocess/yolov5nu_tensor_stream_packer.sv" \
    "$root/sim/tb_yolov5nu_tensor_stream_packer.sv"
vvp "$test_tmp/packer"
vvp "$test_tmp/packer" +bad
vvp "$test_tmp/packer" +continuous
