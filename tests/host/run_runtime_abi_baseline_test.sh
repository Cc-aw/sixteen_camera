#!/usr/bin/env bash
set -euo pipefail
project_root=$(cd "$(dirname "$0")/../.." && pwd)
test_tmp=$(mktemp -d /tmp/sixteen-camera-runtime-abi-r0.XXXXXX)
trap 'rm -rf "$test_tmp"' EXIT
flags=(-std=c11 -O2 -Wall -Wextra -Werror -I"$project_root/sw/src"
  -I"$project_root/sw/models/yolov5nu/include/runtime")
linux_prefix="${TOOLCHAIN:-riscv64-unknown-elf-}"
linux_cc="${RISCV_LINUX_CC:-${linux_prefix%riscv64-unknown-elf-}riscv64-unknown-linux-gnu-gcc}"
for workers in 1 2 3; do
  cc "${flags[@]}" -DAI_MODEL_WORKER_COUNT=${workers}U \
    "$project_root/tests/host/test_runtime_abi_baseline.c" -o "$test_tmp/host-$workers"
  "$test_tmp/host-$workers"
  if command -v "$linux_cc" >/dev/null && command -v qemu-riscv64 >/dev/null; then
    "$linux_cc" -static -march=rv64gcv -mabi=lp64d "${flags[@]}" \
      -DAI_MODEL_WORKER_COUNT=${workers}U \
      "$project_root/tests/host/test_runtime_abi_baseline.c" -o "$test_tmp/rv64-$workers"
    qemu-riscv64 -cpu rv64,v=true,vlen=256 "$test_tmp/rv64-$workers"
  else
    echo "R0_RV64_ABI=SKIP workers=$workers (RISC-V Linux compiler/QEMU unavailable)"
  fi
done
