#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
test_tmp=$(mktemp -d /tmp/yolov5nu-multi-tensor-dma.XXXXXX)
trap 'rm -rf -- "$test_tmp"' EXIT
cd "$repo_dir"

verilator --binary --timing -Wno-fatal \
  --top-module tb_yolov5nu_multi_channel_tensor_dma \
  --Mdir "$test_tmp/obj" \
  rtl/interfaces/axi4_if.sv \
  rtl/ai/preprocess/yolov5nu_tensor_stream_packer.sv \
  rtl/ai/preprocess/yolov5nu_multi_channel_tensor_dma.sv \
  sim/tb_yolov5nu_multi_channel_tensor_dma.sv
"$test_tmp/obj/Vtb_yolov5nu_multi_channel_tensor_dma"
