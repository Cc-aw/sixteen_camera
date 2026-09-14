#!/usr/bin/env bash
set -euo pipefail

package_root=$(cd "$(dirname "$0")/.." && pwd)
test_bin=/tmp/sixteen_camera_ai_postprocess_test

cc -std=c11 -Wall -Wextra -Werror \
  -I"$package_root/software/src" \
  "$package_root/software/src/ai_postprocess_scalar.c" \
  "$package_root/software/src/ai_result_manager.c" \
  "$package_root/software/src/ai_display_map.c" \
  "$package_root/tests/test_ai_postprocess.c" \
  -o "$test_bin"
"$test_bin"
