#!/usr/bin/env bash
set -euo pipefail
project_root=$(cd "$(dirname "$0")/../.." && pwd)
source "$project_root/tests/host/runtime_module_sources.sh"
test_tmp=$(mktemp -d /tmp/sixteen-camera-runtime-version-r0.XXXXXX)
trap 'rm -rf "$test_tmp"' EXIT
cc -std=c11 -Wall -Wextra -Werror -DAI_STREAM_RUNTIME_HOST_TEST -DAI_MODEL_WORKER_COUNT=2U \
  -I"$project_root/tests/host/include" -I"$project_root/sw/src" \
  "$project_root/sw/src/ai/runtime/ai_batch_runtime_stream.c" "${runtime_module_sources[@]}" \
  "$project_root/sw/src/drivers/tensor/ai_tensor_device.c" \
  "$project_root/sw/src/ai/runtime/resources/rt_job.c" \
      "$project_root/sw/src/ai/runtime/resources/rt_tensor_manager.c" \
      "$project_root/sw/src/ai/postprocess/ai_result_manager.c" \
  "$project_root/tests/host/test_runtime_version_baseline.c" -o "$test_tmp/test"
"$test_tmp/test"
