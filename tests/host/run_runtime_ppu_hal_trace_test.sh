#!/usr/bin/env bash
set -euo pipefail
project_root=$(cd "$(dirname "$0")/../.." && pwd)
test_tmp=$(mktemp -d /tmp/sixteen-camera-runtime-ppu-trace.XXXXXX)
trap 'rm -rf "$test_tmp"' EXIT
model="$project_root/sw/models/yolov5nu"
flags=(-std=gnu11 -O2 -Wall -Wextra -Werror -DYOLO32_LIVE=1 -DAI_MODEL_WORKER_COUNT=3U
  -DYOLOV5NU_DIM16_WORKER_COUNT=3U -DYOLO32_FIXED_PLANS=1 -DYOLO32_FIXED_PACKETS=1
  -DYOLO32_PREPARED_PACKETS=1 -DYOLO32_PPU_EARLY=1 -DYOLO32_PPU_HEAD_CLEAN=1
  -I"$project_root/tests/host/ppu_backend_include" -I"$project_root/sw/src" -I"$model/frozen/native" -I"$model/include" -I"$model/src")
for mode in reference current; do
  source="$project_root/sw/src/ai/backend/ai_model_backend_yolov5nu.c"
  if [[ "$mode" == reference ]]; then
    cp "$project_root/tests/data/runtime/r1a/model-backend-reference.c.inc" "$test_tmp/backend.c"
    source="$test_tmp/backend.c"
  fi
  cc "${flags[@]}" -c "$source" -o "$test_tmp/backend.o"
  rm -f "$test_tmp/postprocess.o"
  if [[ "$mode" == current ]]; then
    cc "${flags[@]}" -c "$project_root/sw/src/ai/runtime/services/rt_postprocess_service.c" -o "$test_tmp/postprocess.o"
  fi
  for driver in publication queue; do
    source="$project_root/sw/src/ai/postprocess/ai_ppu_$driver.c"
    if [[ "$mode" == reference ]]; then
      cp "$project_root/tests/data/runtime/r1a/ppu-$driver-reference.c.inc" "$test_tmp/$driver.c"
      source="$test_tmp/$driver.c"
    fi
    cc "${flags[@]}" -DYOLO32_PPU_ORDERED_MMIO=1 -c "$source" -o "$test_tmp/$driver.o"
  done
  for fixture in baseline all-workers; do
    extras=()
    if [[ "$mode" == current ]]; then extras+=(-DR2_STOP_PROOF=1); fi
    if [[ "$fixture" == all-workers ]]; then extras+=(-DR1B_ALL_WORKERS); fi
    cc "${flags[@]}" "${extras[@]}" "$project_root/tests/host/test_runtime_ppu_hal_trace.c" \
      "$project_root/sw/src/ai/runtime/resources/rt_arena_manager.c" \
      "$project_root/sw/src/ai/runtime/resources/rt_head_manager.c" \
      "$project_root/sw/src/ai/runtime/ai_head_slot_queue.c" "$test_tmp"/*.o -o "$test_tmp/$mode-$fixture"
  done
  for scenario in identity generation-fault abort-gap; do
    "$test_tmp/$mode-baseline" "$scenario" > "$test_tmp/$mode-$scenario.trace"
  done
  "$test_tmp/$mode-all-workers" > "$test_tmp/$mode-all-workers.trace"
done
for scenario in identity generation-fault abort-gap all-workers; do
  if [[ "$scenario" == abort-gap ]]; then
    rg -q 'R0_KNOWN_GAP=abort_zero_without_compute_stop_proof' "$test_tmp/reference-$scenario.trace"
    rg -q 'R2_STOP_PROOF=PASS' "$test_tmp/current-$scenario.trace"
    echo 'R2_ABORT_TRACE=PASS expected_behavior_change old_false_success new_fault_held'
    continue
  fi
  diff -u "$test_tmp/reference-$scenario.trace" "$test_tmp/current-$scenario.trace"
  echo "R1B_BACKEND_TRACE=PASS scenario=$scenario events=$(wc -l < "$test_tmp/current-$scenario.trace") MMIO_barriers_cycles_Head_identity_UART_arguments=identical"
done
# Legacy one/two worker firmware also uses the PPU single-command path.
for workers in 1 2; do
  legacy_flags=(-std=gnu11 -O2 -Wall -Wextra -Werror -DYOLO32_LIVE=0 -DR1B_LEGACY
    -DYOLO32_PPU_EARLY=1 -DYOLO32_PPU_HEAD_CLEAN=1
    -DYOLO32_FIXED_PLANS=1 -DYOLO32_FIXED_PACKETS=1 -DYOLO32_PREPARED_PACKETS=1
    -DAI_MODEL_WORKER_COUNT=${workers}U -DYOLOV5NU_DIM16_WORKER_COUNT=${workers}U
    -I"$project_root/tests/host/ppu_backend_include" -I"$project_root/sw/src" -I"$model/frozen/native" -I"$model/include" -I"$model/src")
  for mode in reference current; do
    source="$project_root/sw/src/ai/backend/ai_model_backend_yolov5nu.c"
    if [[ "$mode" == reference ]]; then source="$test_tmp/backend.c"; fi
    cc "${legacy_flags[@]}" -c "$source" -o "$test_tmp/backend.o"
    rm -f "$test_tmp/postprocess.o"
    if [[ "$mode" == current ]]; then
      cc "${legacy_flags[@]}" -c "$project_root/sw/src/ai/runtime/services/rt_postprocess_service.c" -o "$test_tmp/postprocess.o"
    fi
    for driver in publication queue; do
      source="$project_root/sw/src/ai/postprocess/ai_ppu_$driver.c"
      if [[ "$mode" == reference ]]; then source="$test_tmp/$driver.c"; fi
      cc "${legacy_flags[@]}" -c "$source" -o "$test_tmp/$driver.o"
    done
    cc "${legacy_flags[@]}" "$project_root/tests/host/test_runtime_ppu_hal_trace.c" \
      "$project_root/sw/src/ai/runtime/resources/rt_arena_manager.c" \
      "$project_root/sw/src/ai/runtime/resources/rt_head_manager.c" \
      "$project_root/sw/src/ai/runtime/ai_head_slot_queue.c" "$test_tmp"/*.o -o "$test_tmp/$mode-legacy"
    for scenario in publication-on flush-fallback reader-busy ppu-error timeout cpu-fallback; do
      "$test_tmp/$mode-legacy" "$scenario" > "$test_tmp/$mode-$scenario.trace"
    done
  done
  for scenario in publication-on flush-fallback reader-busy ppu-error timeout cpu-fallback; do
    diff -u "$test_tmp/reference-$scenario.trace" "$test_tmp/current-$scenario.trace"
    echo "R1B_LEGACY_BACKEND_TRACE=PASS workers=$workers scenario=$scenario events=$(wc -l < "$test_tmp/current-$scenario.trace") MMIO_fences_cache_cycles_result_UART_arguments=identical"
  done
done
