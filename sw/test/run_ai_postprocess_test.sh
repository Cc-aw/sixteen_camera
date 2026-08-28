#!/usr/bin/env bash
set -euo pipefail

project_root=$(cd "$(dirname "$0")/../.." && pwd)
test_bin=/tmp/sixteen_camera_ai_postprocess_test

cc -std=c11 -Wall -Wextra -Werror \
  -I"$project_root/sw/src" \
  "$project_root/sw/src/ai_postprocess_scalar.c" \
  "$project_root/sw/src/ai_result_manager.c" \
  "$project_root/sw/src/ai_display_map.c" \
  "$project_root/sw/test/test_ai_postprocess.c" \
  -o "$test_bin"
"$test_bin"
