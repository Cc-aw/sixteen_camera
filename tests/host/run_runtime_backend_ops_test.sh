#!/usr/bin/env bash
set -euo pipefail
project_root=$(cd "$(dirname "$0")/../.." && pwd)
source "$project_root/tests/host/runtime_module_sources.sh"
test_tmp=$(mktemp -d /tmp/sixteen-camera-backend-ops.XXXXXX)
trap 'rm -rf "$test_tmp"' EXIT
linux_prefix="${TOOLCHAIN:-riscv64-unknown-elf-}"
linux_cc="${RISCV_LINUX_CC:-${linux_prefix%riscv64-unknown-elf-}riscv64-unknown-linux-gnu-gcc}"
for workers in 1 2 3; do
  runtime_select_backend "$workers"
  dim=16; [[ "$workers" != 1 ]] || dim=4; [[ "$workers" != 3 ]] || dim=32
  flags=(-std=c11 -O2 -Wall -Wextra -Werror -I"$project_root/sw/src" -DAI_MODEL_WORKER_COUNT=${workers}U
    -DYOLOV5NU_GEMMINI_DIM=$dim "${runtime_backend_flags[@]}")
  cc "${flags[@]}" "${runtime_backend_sources[@]}" "$project_root/tests/host/test_runtime_backend_ops.c" -o "$test_tmp/host"
  "$test_tmp/host"
  if command -v "$linux_cc" > /dev/null && command -v qemu-riscv64 > /dev/null; then
    "$linux_cc" -static -march=rv64gcv -mabi=lp64d "${flags[@]}" "${runtime_backend_sources[@]}" \
      "$project_root/tests/host/test_runtime_backend_ops.c" -o "$test_tmp/rv64"
    qemu-riscv64 "$test_tmp/rv64"
  else
    echo 'R4A_OPS_RV64=SKIP compiler_or_QEMU_unavailable'
  fi
done
# Wrong profiles/shapes must fail during compilation rather than select a fallback.
legacy="$project_root/sw/src/ai/backend/adapters/legacy/rt_backend_legacy.c"
v17a="$project_root/sw/src/ai/backend/adapters/v17a/rt_backend_v17a.c"
reject_profile() {
  local source=$1
  shift
  if cc -std=c11 -Wall -Wextra -Werror -I"$project_root/sw/src" "$@" -c "$source" -o "$test_tmp/rejected.o" > "$test_tmp/rejected.log" 2>&1; then
    cat "$test_tmp/rejected.log"; echo 'Incorrect backend profile unexpectedly compiled' >&2; exit 1
  fi
}
reject_profile "$legacy"
reject_profile "$legacy" -DAI_RT_BACKEND_PROFILE=2
reject_profile "$legacy" -DAI_RT_BACKEND_PROFILE=1 -DYOLO32_LIVE=1
reject_profile "$legacy" -DAI_RT_BACKEND_PROFILE=1 -DAI_MODEL_WORKER_COUNT=3
reject_profile "$legacy" -DAI_RT_BACKEND_PROFILE=1 -DYOLOV5NU_GEMMINI_DIM=4
reject_profile "$v17a" -DAI_RT_BACKEND_PROFILE=2 -DYOLO32_LIVE=0 -DAI_MODEL_WORKER_COUNT=3
reject_profile "$v17a" -DAI_RT_BACKEND_PROFILE=2 -DYOLO32_LIVE=1 -DAI_MODEL_WORKER_COUNT=2
reject_profile "$v17a" -DAI_RT_BACKEND_PROFILE=2 -DYOLO32_LIVE=1 -DAI_MODEL_WORKER_COUNT=3 -DYOLOV5NU_GEMMINI_DIM=16
echo 'R4A_PROFILE_GUARDS=PASS missing_profile wrong_profile live_worker_DIM_mismatch_rejected cases=8'
