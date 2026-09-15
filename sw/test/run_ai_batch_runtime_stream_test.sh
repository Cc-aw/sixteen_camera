#!/usr/bin/env bash
set -euo pipefail

project_root=$(cd "$(dirname "$0")/../.." && pwd)
test_tmp=$(mktemp -d /tmp/sixteen-camera-stream-runtime.XXXXXX)
trap 'rm -rf "$test_tmp"' EXIT

cc -std=c11 -Wall -Wextra -Werror -DAI_STREAM_RUNTIME_HOST_TEST \
  -I"$project_root/sw/test/include" -I"$project_root/sw/src" \
  "$project_root/sw/src/ai_batch_runtime_stream.c" \
  "$project_root/sw/src/ai_result_manager.c" \
  "$project_root/sw/test/test_ai_batch_runtime_stream.c" \
  -o "$test_tmp/test_ai_batch_runtime_stream"
"$test_tmp/test_ai_batch_runtime_stream"
