#!/usr/bin/env bash
set -euo pipefail
project_root=$(cd "$(dirname "$0")/../.." && pwd)
test_tmp=$(mktemp -d /tmp/sixteen-camera-resources.XXXXXX)
trap 'rm -rf "$test_tmp"' EXIT
sources=("$project_root/sw/src/ai/runtime/resources/rt_job.c"
  "$project_root/sw/src/ai/runtime/resources/rt_tensor_manager.c"
  "$project_root/sw/src/ai/runtime/resources/rt_arena_manager.c"
  "$project_root/sw/src/ai/runtime/resources/rt_head_manager.c"
  "$project_root/sw/src/ai/runtime/ai_head_slot_queue.c" "$project_root/tests/host/test_runtime_resources.c")
flags=(-std=c11 -O2 -Wall -Wextra -Werror -I"$project_root/sw/src" -I"$project_root/sw/models/yolov5nu/runtime")
cc "${flags[@]}" "${sources[@]}" -o "$test_tmp/host"
"$test_tmp/host"
linux_prefix="${TOOLCHAIN:-riscv64-unknown-elf-}"
linux_cc="${RISCV_LINUX_CC:-${linux_prefix%riscv64-unknown-elf-}riscv64-unknown-linux-gnu-gcc}"
if command -v "$linux_cc" > /dev/null && command -v qemu-riscv64 > /dev/null; then
  "$linux_cc" -static -march=rv64gcv -mabi=lp64d "${flags[@]}" "${sources[@]}" -o "$test_tmp/rv64"
  qemu-riscv64 "$test_tmp/rv64"
else
  echo 'R2_RESOURCES_RV64=SKIP compiler_or_QEMU_unavailable'
fi
