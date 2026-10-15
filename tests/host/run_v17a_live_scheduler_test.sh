#!/usr/bin/env bash
set -euo pipefail
project_root=$(cd "$(dirname "$0")/../.." && pwd)
test_tmp=$(mktemp -d /tmp/sixteen-camera-v17a-live.XXXXXX)
trap 'rm -rf "$test_tmp"' EXIT
model="$project_root/sw/models/yolov5nu"
printf '#include <stdint.h>\nextern uint64_t tick;\nstatic inline uint64_t read_cycle(void) { return ++tick; }\n' > "$test_tmp/mmio.h"
printf '#define SOC_CLOCK_HZ 1000000UL\n' > "$test_tmp/platform.h"
cp "$model/src/independent.c" "$test_tmp/independent.c"
flags=(-std=gnu11 -O2 -Wall -Wextra -Werror -DYOLO32_HOST_TASKS -DYOLO32_LIVE=1 \
  -DYOLOV5NU_DIM16_WORKER_COUNT=3U -DYOLO32_TIMEOUT_SECONDS=600 \
  -DYOLO32_SUBMIT_BURST=1 -DYOLO32_HOT_PATHS=1 -DYOLO32_SCHED_ADAPTIVE=0 \
  -DYOLO32_FIXED_PLANS=1 -DYOLO32_FIXED_PACKETS=1 -DYOLO32_PREPARED_PACKETS=1 \
  -DYOLO32_TAIL_WAIT=1 -DYOLO32_IDLE_PRIORITY=1 -DYOLO32_PPU_EARLY=1 \
  -DYOLO32_PPU_HEAD_CLEAN=1 -I"$test_tmp" -I"$model/include" -I"$model/src" -I"$model/frozen/native" \
  )
cc "${flags[@]}" "$test_tmp/independent.c" "$project_root/tests/host/test_v17a_live_scheduler.c" \
  -o "$test_tmp/test"
"$test_tmp/test"

linux_prefix="${TOOLCHAIN:-riscv64-unknown-elf-}"
linux_cc="${RISCV_LINUX_CC:-${linux_prefix%riscv64-unknown-elf-}riscv64-unknown-linux-gnu-gcc}"
if command -v "$linux_cc" >/dev/null && command -v qemu-riscv64 >/dev/null; then
  "$linux_cc" -static -march=rv64gcv -mabi=lp64d "${flags[@]}" \
    "$test_tmp/independent.c" "$project_root/tests/host/test_v17a_live_scheduler.c" \
    "$model/src/task_switch.S" -o "$test_tmp/riscv-test"
  qemu-riscv64 -cpu rv64,v=true,vlen=256 "$test_tmp/riscv-test"
  echo 'V17A_LIVE_RISCV_CONTEXT=PASS'
else
  echo 'V17A_LIVE_RISCV_CONTEXT=SKIP (RISC-V Linux compiler/QEMU unavailable)'
fi
