#!/usr/bin/env bash
set -euo pipefail
project_root=$(cd "$(dirname "$0")/../.." && pwd)
test_bin=$(mktemp /tmp/ai_head_slot_queue.XXXXXX)
trap 'rm -f "$test_bin"' EXIT
cc -std=c11 -Wall -Wextra -Werror -DAI_MODEL_YOLOV5NU \
  -I"$project_root/sw/src" \
  -I"$project_root/sw/yolov5/dim16_dual" \
  "$project_root/sw/src/ai_head_slot_queue.c" \
  "$project_root/sw/test/test_ai_head_slot_queue.c" -o "$test_bin"
"$test_bin"
