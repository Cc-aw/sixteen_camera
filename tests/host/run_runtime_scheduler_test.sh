#!/usr/bin/env bash
set -euo pipefail
project_root=$(cd "$(dirname "$0")/../.." && pwd)
test_tmp=$(mktemp -d /tmp/sixteen-camera-scheduler.XXXXXX)
trap 'rm -rf "$test_tmp"' EXIT
sources=("$project_root/sw/src/ai/runtime/scheduler/rt_frame_scheduler.c" "$project_root/tests/host/test_runtime_scheduler.c")
flags=(-std=c11 -O2 -Wall -Wextra -Werror -I"$project_root/sw/src")
cc "${flags[@]}" "${sources[@]}" -o "$test_tmp/host"
"$test_tmp/host"
linux_prefix="${TOOLCHAIN:-riscv64-unknown-elf-}"
linux_cc="${RISCV_LINUX_CC:-${linux_prefix%riscv64-unknown-elf-}riscv64-unknown-linux-gnu-gcc}"
if command -v "$linux_cc" > /dev/null && command -v qemu-riscv64 > /dev/null; then
  "$linux_cc" -static -march=rv64gcv -mabi=lp64d "${flags[@]}" "${sources[@]}" -o "$test_tmp/rv64"
  qemu-riscv64 "$test_tmp/rv64"
else
  echo 'R3_POLICY_RV64=SKIP compiler_or_QEMU_unavailable'
fi
