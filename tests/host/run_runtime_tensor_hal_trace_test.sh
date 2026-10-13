#!/usr/bin/env bash
set -euo pipefail
project_root=$(cd "$(dirname "$0")/../.." && pwd)
test_tmp=$(mktemp -d /tmp/sixteen-camera-runtime-tensor-trace.XXXXXX)
trap 'rm -rf "$test_tmp"' EXIT
flags=(-std=c11 -Wall -Wextra -Werror -DAI_STREAM_RUNTIME_HOST_TEST
  -I"$project_root/tests/host/include" -I"$project_root/sw/src")
for workers in 2 3; do
  for mode in reference current; do
    if [[ "$mode" == reference ]]; then
      cp "$project_root/tests/data/runtime/r0/stream-runtime-reference.c.inc" "$test_tmp/runtime.c"
      device_source=()
    else
      cp "$project_root/sw/src/ai/runtime/ai_batch_runtime_stream.c" "$test_tmp/runtime.c"
      device_source=("$project_root/sw/src/drivers/tensor/ai_tensor_device.c")
    fi
    cc "${flags[@]}" -DAI_MODEL_WORKER_COUNT=${workers}U "$test_tmp/runtime.c" \
      "${device_source[@]}" "$project_root/sw/src/ai/postprocess/ai_result_manager.c" \
      "$project_root/tests/host/test_runtime_tensor_hal_trace.c" -o "$test_tmp/$mode-$workers"
    "$test_tmp/$mode-$workers" > "$test_tmp/$mode-$workers.trace"
  done
  diff -u "$test_tmp/reference-$workers.trace" "$test_tmp/current-$workers.trace"
  echo "R1A_RUNTIME_TRACE=PASS workers=$workers events=$(wc -l < "$test_tmp/current-$workers.trace") MMIO_fence_cycle_dispatch_compute_result_UART_arguments=identical"
done
