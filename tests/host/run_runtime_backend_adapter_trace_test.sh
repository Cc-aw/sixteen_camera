#!/usr/bin/env bash
set -euo pipefail
project_root=$(cd "$(dirname "$0")/../.." && pwd)
source "$project_root/tests/host/runtime_module_sources.sh"
test_tmp=$(mktemp -d /tmp/sixteen-camera-backend-adapter.XXXXXX)
trap 'rm -rf "$test_tmp"' EXIT
model="$project_root/sw/models/yolov5nu"
shared=("$project_root/sw/src/ai/runtime/resources/rt_arena_manager.c"
  "$project_root/sw/src/ai/runtime/resources/rt_head_manager.c"
  "$project_root/sw/src/ai/runtime/ai_head_slot_queue.c")
for workers in 1 2 3; do
  runtime_select_backend "$workers"
  live=0; dim=16; [[ "$workers" != 1 ]] || dim=4; [[ "$workers" != 3 ]] || { live=1; dim=32; }
  flags=(-std=gnu11 -O2 -Wall -Wextra -Werror -DAI_MODEL_WORKER_COUNT=${workers}U
    -DYOLOV5NU_DIM16_WORKER_COUNT=${workers}U -DYOLOV5NU_GEMMINI_DIM=$dim
    -DYOLO32_FIXED_PLANS=1 -DYOLO32_FIXED_PACKETS=1 -DYOLO32_PREPARED_PACKETS=1
    -DYOLO32_PPU_EARLY=1 -DYOLO32_PPU_HEAD_CLEAN=1 -DR2_STOP_PROOF=1 -DAI_BACKEND_RESOURCE_TEST=1
    "${runtime_backend_flags[@]}" -I"$project_root/tests/host/ppu_backend_include" -I"$project_root/sw/src" -I"$model/frozen/native" -I"$model/include" -I"$model/src")
  cc "${flags[@]}" -c "$project_root/sw/src/ai/backend/ai_model_backend_yolov5nu.c" -o "$test_tmp/backend.o"
  cc "${flags[@]}" -c "$project_root/sw/src/ai/runtime/services/rt_postprocess_service.c" -o "$test_tmp/postprocess.o"
  for driver in publication queue; do
    cc "${flags[@]}" -DYOLO32_PPU_ORDERED_MMIO=$live -c "$project_root/sw/src/ai/postprocess/ai_ppu_$driver.c" -o "$test_tmp/$driver.o"
  done
  scenarios=(begin-error start-error model-error)
  [[ "$live" == 1 ]] || scenarios+=(ppu-busy-done)
  for mode in reference current; do
    extras=(); inject=()
    if [[ "$mode" == current ]]; then
      extras=("${runtime_backend_sources[@]}" "$project_root/tests/host/backend_adapter_fixture.c")
      inject=(-include "$project_root/tests/host/backend_adapter_fixture.h")
    fi
    # Compile only the fixture with name interception; native sources and
    # adapter callbacks always bind to the actual production backend.
    cc "${flags[@]}" "${inject[@]}" -DAI_BACKEND_FAULT_TRACE=1 -c "$project_root/tests/host/test_backend_fault_ownership.c" -o "$test_tmp/fixture.o"
    cc "${flags[@]}" "${shared[@]}" "${extras[@]}" "$test_tmp"/*.o -o "$test_tmp/$mode-fault"
    for scenario in "${scenarios[@]}"; do "$test_tmp/$mode-fault" "$scenario" > "$test_tmp/$mode-$scenario.trace"; done
    if [[ "$live" == 1 ]]; then
      for fixture in baseline all-workers; do
        opts=(); [[ "$fixture" != all-workers ]] || opts=(-DR1B_ALL_WORKERS)
        cc "${flags[@]}" "${inject[@]}" "${opts[@]}" -c "$project_root/tests/host/test_runtime_ppu_hal_trace.c" -o "$test_tmp/fixture.o"
        cc "${flags[@]}" "${shared[@]}" "${extras[@]}" "$test_tmp"/*.o -o "$test_tmp/$mode-$fixture"
      done
      for scenario in identity generation-fault abort-gap; do "$test_tmp/$mode-baseline" "$scenario" > "$test_tmp/$mode-$scenario.trace"; done
      "$test_tmp/$mode-all-workers" > "$test_tmp/$mode-all-workers.trace"
    else
      cc "${flags[@]}" "${inject[@]}" -DR1B_LEGACY -c "$project_root/tests/host/test_runtime_ppu_hal_trace.c" -o "$test_tmp/fixture.o"
      cc "${flags[@]}" "${shared[@]}" "${extras[@]}" "$test_tmp"/*.o -o "$test_tmp/$mode-legacy"
      for scenario in publication-on flush-fallback reader-busy ppu-error timeout cpu-fallback; do "$test_tmp/$mode-legacy" "$scenario" > "$test_tmp/$mode-$scenario.trace"; done
    fi
  done
  if [[ "$live" == 1 ]]; then scenarios+=(identity generation-fault abort-gap all-workers)
  else scenarios+=(publication-on flush-fallback reader-busy ppu-error timeout cpu-fallback); fi
  for scenario in "${scenarios[@]}"; do
    diff -u "$test_tmp/reference-$scenario.trace" "$test_tmp/current-$scenario.trace"
    echo "R4A_NATIVE_ADAPTER=PASS workers=$workers live=$live scenario=$scenario events=$(wc -l < "$test_tmp/current-$scenario.trace") native_progress_MMIO_fences_cycles_results_ownership_UART=identical"
  done
done
