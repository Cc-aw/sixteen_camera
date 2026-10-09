#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "$0")/../.." && pwd)
test_bin=$(mktemp /tmp/ppu_queue_driver.XXXXXX)
trap 'rm -f "$test_bin"' EXIT
cc -std=c11 -Wall -Wextra -Werror -DAI_STREAM_RUNTIME_HOST_TEST -DAI_MODEL_YOLOV5NU \
 -I"$root/tests/host/include" -I"$root/sw/src" -I"$root/sw/models/yolov5nu/runtime" \
 "$root/sw/src/ai/postprocess/ai_ppu_queue.c" "$root/sw/src/ai/postprocess/ai_ppu_publication.c" "$root/tests/host/test_ai_ppu_queue.c" -o "$test_bin"
"$test_bin"
