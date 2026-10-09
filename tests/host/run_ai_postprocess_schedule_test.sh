#!/usr/bin/env bash
set -euo pipefail
project_root=$(cd "$(dirname "$0")/../.." && pwd)
test_bin=$(mktemp /tmp/ai_postprocess_schedule.XXXXXX)
trap 'rm -f "$test_bin"' EXIT
cc -std=c11 -Wall -Wextra -Werror -DAI_MODEL_YOLOV5NU \
  -I"$project_root/tests/host/include" -I"$project_root/sw/src" \
  -I"$project_root/sw/models/yolov5nu/runtime" \
  "$project_root/tests/host/test_ai_postprocess_schedule.c" -o "$test_bin"
"$test_bin"
