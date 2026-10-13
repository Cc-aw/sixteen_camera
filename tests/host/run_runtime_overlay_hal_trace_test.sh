#!/usr/bin/env bash
set -euo pipefail
project_root=$(cd "$(dirname "$0")/../.." && pwd)
test_tmp=$(mktemp -d /tmp/sixteen-camera-runtime-overlay.XXXXXX)
trap 'rm -rf "$test_tmp"' EXIT
flags=(-std=c11 -Wall -Wextra -Werror -DAI_STREAM_RUNTIME_HOST_TEST
  -I"$project_root/tests/host/include" -I"$project_root/sw/src")
for workers in 2 3; do
  for mode in reference current; do
    source="$project_root/sw/src/ai/postprocess/ai_overlay.c"
    device=()
    if [[ "$mode" == reference ]]; then
      cp "$project_root/tests/data/runtime/r1b/overlay-reference.c.inc" "$test_tmp/overlay.c"
      source="$test_tmp/overlay.c"
    else
      device=("$project_root/sw/src/drivers/overlay/ai_overlay_device.c")
    fi
    cc "${flags[@]}" -Dai_overlay_try_submit=real_overlay_try_submit -c "$source" -o "$test_tmp/overlay.o"
    cc "${flags[@]}" -DAI_MODEL_WORKER_COUNT=${workers}U \
      "$project_root/sw/src/ai/runtime/ai_batch_runtime_stream.c" \
      "$project_root/sw/src/drivers/tensor/ai_tensor_device.c" "${device[@]}" \
      "$project_root/sw/src/ai/postprocess/ai_result_manager.c" \
      "$project_root/sw/src/ai/postprocess/ai_display_map.c" \
      "$project_root/sw/src/ai/postprocess/ai_class_names.c" \
      "$project_root/tests/host/test_runtime_overlay_hal_trace.c" "$test_tmp/overlay.o" -o "$test_tmp/$mode"
    "$test_tmp/$mode" > "$test_tmp/$mode.trace"
  done
  diff -u "$test_tmp/reference.trace" "$test_tmp/current.trace"
  echo "R1C_RUNTIME_OVERLAY_TRACE=PASS workers=$workers events=$(wc -l < "$test_tmp/current.trace") MMIO_cycles_result_order_TTL_busy_retry=identical"
done
