#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHIPYARD="${CHIPYARD_ROOT:-/home/wzr/chipyard}"
CC="${RISCV_ELF_PREFIX:-$CHIPYARD/.conda-env/riscv-tools/bin/riscv64-unknown-elf-}gcc"
NM="${RISCV_ELF_PREFIX:-$CHIPYARD/.conda-env/riscv-tools/bin/riscv64-unknown-elf-}nm"
OBJDUMP="${RISCV_ELF_PREFIX:-$CHIPYARD/.conda-env/riscv-tools/bin/riscv64-unknown-elf-}objdump"
SIZE="${RISCV_ELF_PREFIX:-$CHIPYARD/.conda-env/riscv-tools/bin/riscv64-unknown-elf-}size"
OUT="${YOLOV2_CONV0_BUILD_DIR:-$ROOT/sw/build/yolov2-conv0}"
OBJ="$(mktemp -d /tmp/yolov2-conv0-build.XXXXXX)"
ELF="$OUT/yolov2-conv0.elf"

cleanup() { rm -rf "$OBJ"; }
trap cleanup EXIT

for path in "$CC" "$NM" "$CHIPYARD/tests/htif.ld" \
            "$CHIPYARD/tests/gemmini-myboard-uart.h" \
            "$CHIPYARD/generators/gemmini/software/gemmini-rocc-tests/include/gemmini_testutils.h" \
            "$ROOT/sw/gemcc_runtime/gemmini/lib/gemmini.h" \
            "$ROOT/sw/gemcc_runtime/gemmini/lib/gemmini_nn.h" \
            "$ROOT/sw/gemcc_runtime/gemmini/platform/myboard_cache.c" \
            "$ROOT/demo/ai/sw/test/tinyyolov2_params.h"; do
  [[ -e "$path" ]] || { echo "ERROR: missing dependency: $path" >&2; exit 1; }
done

mkdir -p "$OUT"

COMMON=(
  -g -std=gnu99 -O2 -Wall -Wextra -fno-common -fno-builtin-printf
  -ffunction-sections -fdata-sections
  -march=rv64gcv -mabi=lp64d -mcmodel=medany -specs=htif_nano.specs
  -ffast-math -fno-tree-loop-distribute-patterns -DBAREMETAL=1 -DPRINT_TILE=1
  -I"$CHIPYARD/tests" -I"$ROOT/sw/test/yolov2_conv0"
  -I"$CHIPYARD/generators/gemmini/software/gemmini-rocc-tests"
  -I"$ROOT/demo/ai/sw/test" -I"$ROOT/sw/gemcc_runtime/gemmini/lib"
)
LINK=(
  -g -static -specs=htif_nano.specs -T "$CHIPYARD/tests/htif.ld"
  -Wl,--gc-sections
)

"$CC" "${COMMON[@]}" -c "$ROOT/sw/test/yolov2_conv0_main.c" \
  -o "$OBJ/yolov2_conv0_main.o"
"$CC" "${COMMON[@]}" -c \
  "$ROOT/sw/gemcc_runtime/gemmini/platform/myboard_cache.c" \
  -o "$OBJ/myboard_cache.o"
"$CC" "${LINK[@]}" "$OBJ/yolov2_conv0_main.o" "$OBJ/myboard_cache.o" -lm \
  -o "$ELF"

echo "Built YOLOv2 conv0 ELF: $ELF"
"$SIZE" "$ELF"
for symbol in conv0_input conv0_weights conv0_bias conv0_output; do
  address="$($NM -n "$ELF" | awk -v name="$symbol" '$3 == name {print "0x" $1; exit}')"
  if [[ -z "$address" || $((address)) -lt 0x80000000 ||
        $((address)) -gt 0xffffffff || $(((address) & 63)) -ne 0 ]]; then
    echo "ERROR: $symbol is missing, outside 32-bit DDR, or not 64-byte aligned: $address" >&2
    exit 1
  fi
  echo "$symbol=$address"
done
"$OBJDUMP" -t "$ELF" | awk '$NF == "conv0_input" || $NF == "conv0_output" || $NF == "conv0_weights" || $NF == "conv0_bias" {print}'
