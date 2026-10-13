#!/usr/bin/env bash
set -euo pipefail
project_root=$(cd "$(dirname "$0")/../.." && pwd)
source "$project_root/tests/host/runtime_module_sources.sh"
test_tmp=$(mktemp -d /tmp/sixteen-camera-runtime-metrics.XXXXXX)
trap 'rm -rf "$test_tmp"' EXIT
linux_prefix="${TOOLCHAIN:-riscv64-unknown-elf-}"
linux_cc="${RISCV_LINUX_CC:-${linux_prefix%riscv64-unknown-elf-}riscv64-unknown-linux-gnu-gcc}"
for workers in 2 3; do
  runtime_select_backend "$workers"
  flags=(-std=c11 -O2 -Wall -Wextra -Werror -DAI_STREAM_RUNTIME_HOST_TEST
    -I"$project_root/tests/host/include" -I"$project_root/sw/src" -DAI_MODEL_WORKER_COUNT=${workers}U
    "${runtime_backend_flags[@]}")
  for platform in host rv64; do
    compiler=cc; platform_flags=(); runner=()
    if [[ "$platform" == rv64 ]]; then
      if ! command -v "$linux_cc" > /dev/null || ! command -v qemu-riscv64 > /dev/null; then
        echo 'R5_METRICS_RV64=SKIP compiler_or_QEMU_unavailable'
        continue
      fi
      compiler="$linux_cc"; platform_flags=(-static -march=rv64gcv -mabi=lp64d); runner=(qemu-riscv64)
    fi
    "$compiler" "${flags[@]}" "${platform_flags[@]}" "$project_root/tests/host/test_runtime_facade_metrics.c" \
      "$project_root/sw/src/ai/runtime/ai_batch_runtime_stream.c" "${runtime_module_sources[@]}" "${runtime_backend_sources[@]}" \
      "$project_root/sw/src/drivers/tensor/ai_tensor_device.c" "$project_root/sw/src/ai/runtime/resources/rt_job.c" \
      "$project_root/sw/src/ai/runtime/resources/rt_tensor_manager.c" "$project_root/sw/src/ai/postprocess/ai_result_manager.c" \
      -o "$test_tmp/test"
    "${runner[@]}" "$test_tmp/test"
    echo "R5_METRICS_PLATFORM=PASS workers=$workers platform=$platform"
  done
done
