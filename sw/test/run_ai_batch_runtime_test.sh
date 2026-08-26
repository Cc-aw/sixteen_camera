#!/usr/bin/env bash
set -euo pipefail

project_root=$(cd "$(dirname "$0")/../.." && pwd)
test_bin=/tmp/sixteen_camera_ai_batch_runtime_test

cc -std=c11 -Wall -Wextra -Werror \
  -I"$project_root/sw/test/include" -I"$project_root/sw/src" \
  "$project_root/sw/src/ai_batch_runtime.c" \
  "$project_root/sw/src/ai_model_backend_stub.c" \
  "$project_root/sw/test/test_ai_batch_runtime.c" \
  -o "$test_bin"
"$test_bin"
