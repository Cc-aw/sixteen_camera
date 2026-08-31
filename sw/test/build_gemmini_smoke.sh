#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
CC="${RISCV_CC:-/home/wzr/chipyard/.conda-env/riscv-tools/bin/riscv64-unknown-elf-gcc}"
ROCC="${GEMMINI_ROCC_DIR:-/home/gky/ai-compiler/runtime/gemmini/rocc}"
OUT="$ROOT/sw/build/gemmini_smoke"
mkdir -p "$OUT"
"$CC" -O2 -march=rv64gcv -mabi=lp64d -mcmodel=medany -ffreestanding -fno-builtin \
  -I"$ROCC" -I"$ROOT/sw/src" -I"$ROOT/sw/test/include" -c "$ROOT/sw/test/gemmini_smoke.c" -o "$OUT/gemmini_smoke.o"
"$CC" -march=rv64gcv -mabi=lp64d -mcmodel=medany -nostdlib -nostartfiles -static \
  -I"$ROOT/sw/src" -I"$ROOT/sw/test/include" -T "$ROOT/sw/linker_ai_video.ld" "$ROOT/sw/src/startup.S" "$OUT/gemmini_smoke.o" \
  -lgcc -o "$OUT/gemmini_smoke.elf"
"${CC%-gcc}-objcopy" -O binary "$OUT/gemmini_smoke.elf" "$OUT/gemmini_smoke.bin"
echo "GEMMINI_SMOKE_BUILD=PASS"
echo "ELF=$OUT/gemmini_smoke.elf"
