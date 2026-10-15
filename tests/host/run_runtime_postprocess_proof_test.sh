#!/usr/bin/env bash
set -euo pipefail
project_root=$(cd "$(dirname "$0")/../.." && pwd)
test_tmp=$(mktemp -d /tmp/sixteen-camera-postprocess-proof.XXXXXX)
trap 'rm -rf "$test_tmp"' EXIT
model="$project_root/sw/models/yolov5nu"
flags=(-std=gnu11 -O2 -Wall -Wextra -Werror -DAI_BACKEND_RESOURCE_TEST=1 -DYOLO32_LIVE=1 -DAI_MODEL_WORKER_COUNT=3U
  -DYOLOV5NU_DIM16_WORKER_COUNT=3U -DYOLO32_FIXED_PLANS=1 -DYOLO32_FIXED_PACKETS=1
  -DYOLO32_PREPARED_PACKETS=1 -DYOLO32_PPU_EARLY=1 -DYOLO32_PPU_HEAD_CLEAN=1
  -I"$project_root/tests/host/ppu_backend_include" -I"$project_root/sw/src" -I"$model/frozen/native" -I"$model/include" -I"$model/src")
linux_prefix="${TOOLCHAIN:-riscv64-unknown-elf-}"
linux_cc="${RISCV_LINUX_CC:-${linux_prefix%riscv64-unknown-elf-}riscv64-unknown-linux-gnu-gcc}"
for platform in host rv64; do
  compiler=cc; platform_flags=(); runner=()
  if [[ "$platform" == rv64 ]]; then
    if ! command -v "$linux_cc" > /dev/null || ! command -v qemu-riscv64 > /dev/null; then
      echo 'R4B_HEAD_PROOF_RV64=SKIP compiler_or_QEMU_unavailable'
      continue
    fi
    compiler="$linux_cc"; platform_flags=(-static -march=rv64gcv -mabi=lp64d); runner=(qemu-riscv64)
  fi
  "$compiler" "${platform_flags[@]}" "${flags[@]}" -c "$project_root/sw/src/ai/backend/ai_model_backend_yolov5nu.c" -o "$test_tmp/backend.o"
  "$compiler" "${platform_flags[@]}" "${flags[@]}" -c "$project_root/sw/src/ai/runtime/services/rt_postprocess_service.c" -o "$test_tmp/postprocess.o"
  for driver in ai_ppu_publication ai_ppu_queue; do
    "$compiler" "${platform_flags[@]}" "${flags[@]}" -DYOLO32_PPU_ORDERED_MMIO=1 -c "$project_root/sw/src/ai/postprocess/$driver.c" -o "$test_tmp/$driver.o"
  done
  "$compiler" "${platform_flags[@]}" "${flags[@]}" "$project_root/tests/host/test_runtime_postprocess_proof.c" \
    "$project_root/sw/src/ai/runtime/resources/rt_arena_manager.c" \
    "$project_root/sw/src/ai/runtime/resources/rt_head_manager.c" \
    "$project_root/sw/src/ai/runtime/ai_head_slot_queue.c" "$test_tmp"/*.o -o "$test_tmp/test"
  "${runner[@]}" "$test_tmp/test"
  echo "R4B_HEAD_PROOF_PLATFORM=PASS platform=$platform"
done
