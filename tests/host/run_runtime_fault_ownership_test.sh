#!/usr/bin/env bash
set -euo pipefail
project_root=$(cd "$(dirname "$0")/../.." && pwd)
source "$project_root/tests/host/runtime_module_sources.sh"
test_tmp=$(mktemp -d /tmp/sixteen-camera-runtime-fault.XXXXXX)
trap 'rm -rf "$test_tmp"' EXIT
for workers in 1 2 3; do
  cc -std=c11 -Wall -Wextra -Werror -DAI_RUNTIME_STATE_TEST=1 -DAI_STREAM_RUNTIME_HOST_TEST -DAI_STREAM_RUNTIME_HEALTHY_TRACE=1 \
    -DAI_MODEL_WORKER_COUNT=${workers}U -I"$project_root/tests/host/include" -I"$project_root/sw/src" \
    "$project_root/sw/src/ai/runtime/ai_batch_runtime_stream.c" "${runtime_module_sources[@]}" \
    "$project_root/sw/src/ai/runtime/resources/rt_job.c" \
    "$project_root/sw/src/ai/runtime/resources/rt_tensor_manager.c" \
    "$project_root/sw/src/drivers/tensor/ai_tensor_device.c" \
    "$project_root/sw/src/ai/postprocess/ai_result_manager.c" \
    "$project_root/tests/host/test_runtime_fault_ownership.c" -o "$test_tmp/test"
  for scenario in error-only error-enable release-retry late-ack release-pending reused-after-timeout error-zero timeout bad-compute uncertain-submit; do
    "$test_tmp/test" "$scenario"
  done
  echo "R2_RUNTIME_FAULTS=PASS workers=$workers scenarios=10"
done
