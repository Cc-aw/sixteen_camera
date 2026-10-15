#!/usr/bin/env bash
set -euo pipefail
project_root=$(cd "$(dirname "$0")/../.." && pwd)
test_tmp=$(mktemp -d /tmp/sixteen-camera-v17a-backend.XXXXXX)
trap 'rm -rf "$test_tmp"' EXIT
model="$project_root/sw/models/yolov5nu"
cat > "$test_tmp/mmio.h" <<'HEADER'
#ifndef TEST_V17A_MMIO_H
#define TEST_V17A_MMIO_H
#include <stdint.h>
extern uint64_t test_cycle;
uint32_t mmio_read32(uintptr_t);
void mmio_write32(uintptr_t, uint32_t);
void mmio_fence(void);
void test_wfi(void);
static inline uint64_t read_cycle(void) { return ++test_cycle; }
static inline void cpu_wfi(void) { test_wfi(); }
#if YOLO32_PPU_ORDERED_MMIO
void yolo32_ppu_io_barrier(void);
#define mmio_fence yolo32_ppu_io_barrier
#endif
#endif
HEADER
flags=(-std=gnu11 -O2 -Wall -Wextra -Werror -DAI_BACKEND_RESOURCE_TEST=1 -DYOLO32_LIVE=1 -DAI_MODEL_WORKER_COUNT=3U
  -DYOLOV5NU_DIM16_WORKER_COUNT=3U -DYOLO32_FIXED_PLANS=1 -DYOLO32_FIXED_PACKETS=1
  -DYOLO32_PREPARED_PACKETS=1 -DYOLO32_PPU_EARLY=1 -DYOLO32_PPU_HEAD_CLEAN=1
  -I"$test_tmp" -I"$project_root/sw/src" -I"$model/frozen/native" -I"$model/include" -I"$model/src")
cc "${flags[@]}" -c "$project_root/sw/src/ai/backend/ai_model_backend_yolov5nu.c" -o "$test_tmp/backend.o"
cc "${flags[@]}" -c "$project_root/sw/src/ai/runtime/services/rt_postprocess_service.c" -o "$test_tmp/postprocess.o"
for driver in ai_ppu_publication ai_ppu_queue; do
  cc "${flags[@]}" -DYOLO32_PPU_ORDERED_MMIO=1 -c "$project_root/sw/src/ai/postprocess/$driver.c" -o "$test_tmp/$driver.o"
done
cc "${flags[@]}" "$project_root/tests/host/test_v17a_backend.c" \
  "$project_root/sw/src/ai/runtime/resources/rt_arena_manager.c" \
  "$project_root/sw/src/ai/runtime/resources/rt_head_manager.c" \
  "$project_root/sw/src/ai/runtime/ai_head_slot_queue.c" "$test_tmp"/*.o -o "$test_tmp/test"
"$test_tmp/test"
