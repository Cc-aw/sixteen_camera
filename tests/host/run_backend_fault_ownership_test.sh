#!/usr/bin/env bash
set -euo pipefail
project_root=$(cd "$(dirname "$0")/../.." && pwd)
test_tmp=$(mktemp -d /tmp/sixteen-camera-backend-fault.XXXXXX)
trap 'rm -rf "$test_tmp"' EXIT
model="$project_root/sw/models/yolov5nu/triple32"
for workers in 1 2 3; do
  live=0; [[ "$workers" != 3 ]] || live=1
  flags=(-std=gnu11 -O2 -Wall -Wextra -Werror -DYOLO32_LIVE=$live -DAI_MODEL_WORKER_COUNT=${workers}U
    -DYOLOV5NU_DIM16_WORKER_COUNT=${workers}U -DYOLO32_FIXED_PLANS=1 -DYOLO32_FIXED_PACKETS=1
    -DYOLO32_PREPARED_PACKETS=1 -DYOLO32_PPU_EARLY=1 -DYOLO32_PPU_HEAD_CLEAN=1
    -I"$project_root/tests/host/ppu_backend_include" -I"$project_root/sw/src" -I"$model/native" -I"$model")
  cc "${flags[@]}" -c "$project_root/sw/src/ai/backend/ai_model_backend_yolov5nu.c" -o "$test_tmp/backend.o"
  cc "${flags[@]}" -c "$project_root/sw/src/ai/runtime/services/rt_postprocess_service.c" -o "$test_tmp/postprocess.o"
  for driver in publication queue; do
    cc "${flags[@]}" -DYOLO32_PPU_ORDERED_MMIO=$live -c "$project_root/sw/src/ai/postprocess/ai_ppu_$driver.c" -o "$test_tmp/$driver.o"
  done
  cc "${flags[@]}" "$project_root/tests/host/test_backend_fault_ownership.c" \
    "$project_root/sw/src/ai/runtime/ai_head_slot_queue.c" \
    "$project_root/sw/src/ai/runtime/resources/rt_arena_manager.c" \
    "$project_root/sw/src/ai/runtime/resources/rt_head_manager.c" "$test_tmp"/*.o -o "$test_tmp/test"
  for scenario in begin-error start-error model-error; do "$test_tmp/test" "$scenario"; done
  scenarios=3
  if [[ "$live" == 0 ]]; then "$test_tmp/test" ppu-busy-done; scenarios=4; fi
  echo "R2_BACKEND_FAULTS=PASS workers=$workers live=$live scenarios=$scenarios"
done
