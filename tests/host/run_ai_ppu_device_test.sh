#!/usr/bin/env bash
set -euo pipefail
project_root=$(cd "$(dirname "$0")/../.." && pwd)
test_tmp=$(mktemp -d /tmp/sixteen-camera-ppu-device.XXXXXX)
trap 'rm -rf "$test_tmp"' EXIT
flags=(-std=c11 -O2 -Wall -Wextra -Werror -I"$project_root/tests/host/ppu_device_include"
  -I"$project_root/sw/src" -I"$project_root/sw/models/yolov5nu/include/runtime")
for ordered in 0 1; do
  for mode in reference current; do
    extras=()
    for driver in publication queue; do
      if [[ "$mode" == reference ]]; then
        cp "$project_root/tests/data/runtime/r1a/ppu-$driver-reference.c.inc" "$test_tmp/$driver.c"
      else
        # Includes resolve relative to the production adapter's own path.
        extras=(-DR1B_CURRENT)
      fi
      source="$test_tmp/$driver.c"
      if [[ "$mode" == current ]]; then source="$project_root/sw/src/ai/postprocess/ai_ppu_$driver.c"; fi
      cc "${flags[@]}" -DYOLO32_PPU_ORDERED_MMIO=$ordered -c "$source" -o "$test_tmp/$driver.o"
    done
    cc "${flags[@]}" "${extras[@]}" "$project_root/tests/host/test_ai_ppu_device.c" \
      "$test_tmp/publication.o" "$test_tmp/queue.o" -o "$test_tmp/$mode"
    "$test_tmp/$mode" > "$test_tmp/$mode.trace"
  done
  diff -u "$test_tmp/reference.trace" "$test_tmp/current.trace"
  echo "R1B_PPU_DEVICE_TRACE=PASS ordered=$ordered events=$(wc -l < "$test_tmp/current.trace") MMIO_barrier_order=identical"
done
