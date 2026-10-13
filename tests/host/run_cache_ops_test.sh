#!/usr/bin/env bash
set -euo pipefail
project_root=$(cd "$(dirname "$0")/../.." && pwd)
test_tmp=$(mktemp -d /tmp/sixteen-camera-cache-ops.XXXXXX)
trap 'rm -rf "$test_tmp"' EXIT
flags=(-std=c11 -O2 -Wall -Wextra -Werror -I"$project_root/tests/host/tensor_device_include" -I"$project_root/sw/src")
platforms=(host)
linux_prefix="${TOOLCHAIN:-riscv64-unknown-elf-}"
riscv_compiler="${RISCV_LINUX_CC:-${linux_prefix%riscv64-unknown-elf-}riscv64-unknown-linux-gnu-gcc}"
if command -v "$riscv_compiler" > /dev/null && command -v qemu-riscv64 > /dev/null; then
  platforms+=(rv64)
else
  echo 'R1C_CACHE_RV64=SKIP compiler_or_QEMU_unavailable'
fi
for platform in "${platforms[@]}"; do
  compiler=cc; arch_flags=(); runner=()
  if [[ "$platform" == rv64 ]]; then
    compiler="$riscv_compiler"; arch_flags=(-static -march=rv64gcv -mabi=lp64d); runner=(qemu-riscv64)
  fi
for live in 0 1; do
  for mode in reference current; do
    extras=()
    source="$project_root/sw/src/platform/cache_ops.c"
    if [[ "$mode" == reference ]]; then
      cp "$project_root/tests/data/runtime/r1b/cache-reference.c.inc" "$test_tmp/cache.c"
      source="$test_tmp/cache.c"
    else
      extras=(-DR1C_CURRENT)
    fi
    "$compiler" "${flags[@]}" "${arch_flags[@]}" "${extras[@]}" -DYOLO32_LIVE=$live "$source" "$project_root/tests/host/test_cache_ops.c" -o "$test_tmp/$mode"
    "${runner[@]}" "$test_tmp/$mode" > "$test_tmp/$mode.trace"
  done
  diff -u "$test_tmp/reference.trace" "$test_tmp/current.trace"
  echo "R1C_CACHE_TRACE=PASS platform=$platform live=$live events=$(wc -l < "$test_tmp/current.trace") fence_store64_samples_alias=identical capabilities=PASS"
done
done
if cc "${flags[@]}" -DYOLO32_PPU_ORDERED_MMIO=1 -c "$project_root/sw/src/platform/cache_ops.c" -o "$test_tmp/bad.o" > "$test_tmp/bad.log" 2>&1; then
  echo 'Cache accidentally accepted PPU-only ordering'; exit 1
fi
rg -q 'Cache operations require ordinary fences' "$test_tmp/bad.log"
echo 'R1C_CACHE_COMPILE_GUARD=PASS PPU_only_override_rejected'
