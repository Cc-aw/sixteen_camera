#!/usr/bin/env bash
set -euo pipefail

project_root=$(cd "$(dirname "$0")/../.." && pwd)
source "$project_root/tests/host/runtime_module_sources.sh"
test_tmp=$(mktemp -d /tmp/sixteen-camera-stream-runtime.XXXXXX)
trap 'rm -rf "$test_tmp"' EXIT

for workers in 2 3; do
  runtime_select_backend "$workers"
cc -std=c11 -Wall -Wextra -Werror -DAI_STREAM_RUNTIME_HOST_TEST "${runtime_backend_flags[@]}" -DAI_MODEL_WORKER_COUNT=${workers}U \
  -I"$project_root/tests/host/include" -I"$project_root/sw/src" \
  "$project_root/sw/src/ai/runtime/ai_batch_runtime_stream.c" "${runtime_module_sources[@]}" "${runtime_backend_sources[@]}" \
  "$project_root/sw/src/drivers/tensor/ai_tensor_device.c" \
  "$project_root/sw/src/ai/runtime/resources/rt_job.c" \
      "$project_root/sw/src/ai/runtime/resources/rt_tensor_manager.c" \
      "$project_root/sw/src/ai/postprocess/ai_result_manager.c" \
  "$project_root/tests/host/test_ai_batch_runtime_stream.c" \
  -o "$test_tmp/test_ai_batch_runtime_stream"
"$test_tmp/test_ai_batch_runtime_stream"
done
