#!/usr/bin/env bash
set -euo pipefail
project_root=$(cd "$(dirname "$0")/../.." && pwd)
test_tmp=$(mktemp -d /tmp/sixteen-camera-overlay-device.XXXXXX)
trap 'rm -rf "$test_tmp"' EXIT
flags=(-std=c11 -O2 -Wall -Wextra -Werror -I"$project_root/tests/host/tensor_device_include"
  -I"$project_root/tests/host/include" -I"$project_root/sw/src")
for mode in reference current; do
  sources=()
  source="$project_root/sw/src/ai/postprocess/ai_overlay.c"
  if [[ "$mode" == reference ]]; then
    cp "$project_root/tests/data/runtime/r1b/overlay-reference.c.inc" "$test_tmp/overlay.c"
    source="$test_tmp/overlay.c"
  else
    sources=("$project_root/sw/src/drivers/overlay/ai_overlay_device.c")
  fi
  cc "${flags[@]}" "$source" "${sources[@]}" "$project_root/sw/src/ai/postprocess/ai_display_map.c" \
    "$project_root/sw/src/ai/postprocess/ai_class_names.c" "$project_root/tests/host/test_ai_overlay_device.c" -o "$test_tmp/$mode"
  "$test_tmp/$mode" > "$test_tmp/$mode.trace"
done
diff -u "$test_tmp/reference.trace" "$test_tmp/current.trace"
echo "R1C_OVERLAY_DEVICE_TRACE=PASS events=$(wc -l < "$test_tmp/current.trace") MMIO_labels_cycle_retry_timeout=identical"
