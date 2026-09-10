#!/usr/bin/env bash
set -euo pipefail

project_root=$(cd "$(dirname "$0")/../.." && pwd)
test_bin=/tmp/sixteen_camera_yolov2_fixed_ref_test

cc -std=c11 -Wall -Wextra -Werror \
  -I"$project_root/sw/postprocess/fixed_ref" \
  "$project_root/sw/postprocess/fixed_ref/yolov2_fixed_ref.c" \
  "$project_root/sw/test/test_yolov2_fixed_ref.c" \
  -o "$test_bin"
"$test_bin"
