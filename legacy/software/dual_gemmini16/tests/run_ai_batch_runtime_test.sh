#!/usr/bin/env bash
set -euo pipefail

package_root=$(cd "$(dirname "$0")/.." && pwd)
test_bin=/tmp/sixteen_camera_ai_batch_runtime_test

cc -std=c11 -Wall -Wextra -Werror -DAI_MODEL_BACKEND_HOST_TEST \
  -I"$package_root/tests/include" \
  -I"$package_root/dependencies/platform/include" \
  -I"$package_root/software/src" \
  "$package_root/software/src/ai_batch_runtime.c" \
  "$package_root/software/src/ai_model_backend_stub.c" \
  "$package_root/software/src/ai_postprocess_scalar.c" \
  "$package_root/software/src/ai_result_manager.c" \
  "$package_root/tests/test_ai_batch_runtime.c" \
  -o "$test_bin"
"$test_bin"
