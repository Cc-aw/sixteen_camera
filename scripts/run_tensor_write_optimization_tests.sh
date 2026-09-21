#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
test_tmp=$(mktemp -d /tmp/tensor-write-optimization.XXXXXX)
trap 'rm -rf -- "$test_tmp"' EXIT
cd "$repo_dir"

verilator --cc --exe --build -j 4 -Wno-fatal \
  --top-module fbus_write_order_top --Mdir "$test_tmp/write_cdc" \
  rtl/interfaces/axi4_if.sv rtl/bus/cdc_payload_fifo.sv \
  rtl/bus/axi4_write_cdc.sv sim/fbus_write_order_top.sv \
  "$repo_dir/sim/fbus_write_order_main.cpp"
"$test_tmp/write_cdc/Vfbus_write_order_top"

verilator --cc --exe --build -j 4 -Wno-fatal \
  --top-module tensor_admission_top --Mdir "$test_tmp/admission" \
  rtl/interfaces/axi4_if.sv \
  rtl/ai/preprocess/yolov5nu_tensor_stream_packer.sv \
  rtl/ai/preprocess/yolov5nu_multi_channel_tensor_dma.sv \
  sim/tensor_admission_top.sv \
  "$repo_dir/sim/tensor_admission_main.cpp"
"$test_tmp/admission/Vtensor_admission_top"

echo "TENSOR_WRITE_OPTIMIZATION_TESTS=PASS"
