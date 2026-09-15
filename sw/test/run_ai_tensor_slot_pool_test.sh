#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/../.." && pwd)
test_tmp=$(mktemp -d /tmp/sixteen-camera-slot-pool.XXXXXX)
trap 'rm -rf "$test_tmp"' EXIT

cc -std=c11 -Wall -Wextra -Werror -I"$root/sw/src" \
    "$root/sw/src/ai_tensor_slot_pool.c" \
    "$root/sw/test/test_ai_tensor_slot_pool.c" \
    -o "$test_tmp/test_ai_tensor_slot_pool"
"$test_tmp/test_ai_tensor_slot_pool"
