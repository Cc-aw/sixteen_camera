#!/usr/bin/env bash
set -euo pipefail
project_root=$(cd "$(dirname "$0")/../.." && pwd)
test_tmp=$(mktemp -d /tmp/sixteen-camera-tensor-device.XXXXXX)
trap 'rm -rf "$test_tmp"' EXIT
cc -std=c11 -O2 -Wall -Wextra -Werror \
  -I"$project_root/tests/host/tensor_device_include" -I"$project_root/sw/src" \
  -I"$project_root/tests/data/runtime/r0" \
  "$project_root/sw/src/drivers/tensor/ai_tensor_device.c" \
  "$project_root/tests/host/test_ai_tensor_device.c" -o "$test_tmp/test"
"$test_tmp/test"
