#!/usr/bin/env bash
set -euo pipefail

package_root=$(cd "$(dirname "$0")/.." && pwd)
test_bin=/tmp/sixteen_camera_yolov2_fixed_ref_test

cc -std=c11 -Wall -Wextra -Werror \
  -I"$package_root/software/postprocess/fixed_ref" \
  "$package_root/software/postprocess/fixed_ref/yolov2_fixed_ref.c" \
  "$package_root/tests/test_yolov2_fixed_ref.c" \
  -o "$test_bin"
"$test_bin"
