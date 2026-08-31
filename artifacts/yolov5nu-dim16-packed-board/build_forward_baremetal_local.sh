#!/bin/bash
# Link the whole-graph @forward object as a Spike/board no-pk ELF.
# Requires compile_forward.sh first.  Does not read graph.json or @layerN.
# Usage: ./build_forward_baremetal.sh
#        BOARD=1 ./build_forward_baremetal.sh   # UART ELF; do not Spike
set -euo pipefail

ROOT="/home/gky/ai-compiler"
OUT="${GEMCC_OUT:-$ROOT/tests/runtime/yolov5n/out}"
CODEGEN="${GEMCC_CODEGEN:-library}"
ELF_GCC="${GEMCC_RISCV_ELF_GCC:-${RISCV_TOOLCHAIN_ROOT:-/home/edgeai/edge-ai-lab/chipyard/.conda-env/riscv-tools}/bin/riscv64-unknown-elf-gcc}"
OBJCOPY="${ELF_GCC%-gcc}-objcopy"
GEMCC_LLC="${GEMCC_LLC:-$ROOT/build/bin/gemcc-llc}"
ROCC_TESTS="${GEMMINI_ROCC_TESTS:-/home/edgeai/edge-ai-lab/chipyard/generators/gemmini/software/gemmini-rocc-tests}"
ROCC_COMMON="${GEMMINI_ROCC_COMMON:-$ROCC_TESTS/riscv-tests/benchmarks/common}"
MYBOARD_BARE="$ROOT/runtime/myboard/software/baremetal"

pick() {
  local name="$1"
  if [[ -f $MYBOARD_BARE/$name ]]; then echo "$MYBOARD_BARE/$name"
  else echo "$ROCC_COMMON/$name"
  fi
}
CRT_S="$(pick crt.S)"
SYSCALLS_C="$(pick syscalls.c)"
TEST_LD="$(pick test.ld)"

if [[ -n "${GEMCC_PYTHON:-}" ]]; then
  PYTHON="$GEMCC_PYTHON"
elif [[ -x "$ROOT/../build/scheme-a-venv/bin/python" ]]; then
  PYTHON="$ROOT/../build/scheme-a-venv/bin/python"
else
  PYTHON="python3"
fi

for p in "$OUT/forward.ll" "$OUT/forward_constants.S" "$OUT/forward_trampoline.c" \
         "$OUT/model_abi.h" "$OUT/forward_input.bin" "$ELF_GCC" "$CRT_S" \
         "$SYSCALLS_C" "$TEST_LD"; do
  [[ -e $p ]] || { echo "missing $p (run compile_forward.sh first)" >&2; exit 2; }
done

OUT_ELEMS=$("$PYTHON" -c "
import re
text=open('$OUT/model_abi.h').read()
print(int(re.search(r'GEMCC_OUTPUT_ELEMS (-?[0-9]+)LL', text).group(1)))
")
OUT_EB=$("$PYTHON" -c "
import re
text=open('$OUT/model_abi.h').read()
print(int(re.search(r'GEMCC_OUTPUT_ELEM_BYTES (-?[0-9]+)', text).group(1)))
")
EXPECT_FLAG=()
if [[ -n "${GEMCC_EXPECTED_CHECKSUM:-}" ]]; then
  EXPECT_FLAG=(-DGEMCC_EXPECTED_CHECKSUM="$GEMCC_EXPECTED_CHECKSUM")
fi

echo "=== embed input_data ==="
"$PYTHON" -c "
open('$OUT/forward_input_embed.S','w').write(
'.section .rodata\\n.align 12\\n'
'.globl input_data\\ninput_data:\\n.incbin \"$OUT/forward_input.bin\"\\n'
)
"
"$ELF_GCC" -c "$OUT/forward_input_embed.S" -o "$OUT/forward_input_embed.o"
"$ELF_GCC" -c "$OUT/forward_constants.S" -o "$OUT/forward_constants_bm.o"

echo "=== forward.o code-model=medium ==="
"$GEMCC_LLC" -O2 --march=riscv64 -mcpu=generic-rv64 -mattr=+m,+a,+f,+d,+c,+v \
  -code-model=medium -filetype=obj "$OUT/forward.ll" -o "$OUT/forward_medany.o"

# No -ffast-math: SiLU/sigmoid LUTs call exp/tanh; fast-math + newlib
# changes rounding vs the pk/glibc Spike oracle (YOLOv5n 31305718).
# model_abi.h sizes the arena; generated malloc/free calls reuse it through
# gemcc_model_init and the board harness.
# shellcheck source=../identity_cflags.sh
source "$ROOT/tests/runtime/identity_cflags.sh"
gemcc_identity_cflags "$OUT" "${GEMCC_PYTHON:-python3}"
CFLAGS=(-O2 -std=gnu99 -mcmodel=medany -fno-fast-math -fno-common
        -fno-builtin-printf -fno-tree-loop-distribute-patterns
        -march=rv64gcv -Wa,-march=rv64gcv -mabi=lp64d
        -DBAREMETAL=1
        -DMYBOARD_UART_DIV_115200=868u
        -DGEMCC_HAS_MODEL_ABI
        "${IDENTITY_CFLAGS[@]}"
        -I "$OUT"
        -DGEMCC_BOARD_OUT_ELEMS="$OUT_ELEMS"
        -DGEMCC_BOARD_OUT_ELEM_BYTES="$OUT_EB"
        -DGEMCC_BOARD_TAG='"GEMCC_FORWARD"'
        -I "$ROOT/runtime/gemmini/lib" -I "$ROOT/runtime/gemmini/rocc"
        -I "$ROOT/runtime/ops" -I "$ROOT/runtime/engine" -I "$OUT"
        -I "$ROCC_COMMON" -I "$MYBOARD_BARE"
        -I "$ROCC_TESTS/riscv-tests" -I "$ROCC_TESTS/riscv-tests/env")

"$ELF_GCC" "${CFLAGS[@]}" "${EXPECT_FLAG[@]}" \
  -c "$ROOT/tests/runtime/tinyyolov2/board_main.c" -o "$OUT/forward_board_main.o"
"$ELF_GCC" "${CFLAGS[@]}" -c "$OUT/forward_trampoline.c" -o "$OUT/forward_trampoline_bm.o"
"$ELF_GCC" "${CFLAGS[@]}" -c "$ROOT/runtime/engine/gemcc_model.c" -o "$OUT/gemcc_model_bm.o"
"$ELF_GCC" "${CFLAGS[@]}" -c "$ROOT/runtime/engine/gemcc_device.c" -o "$OUT/gemcc_device_bm.o"
"$ELF_GCC" "${CFLAGS[@]}" -c "$ROOT/runtime/engine/memref_copy.c" -o "$OUT/memref_copy_bm.o"

GEMMINI_RT_OBJS=()
if [[ "$CODEGEN" == "rocc" ]]; then
  "$ELF_GCC" "${CFLAGS[@]}" -c "$ROOT/runtime/gemmini/rocc/gemmini_rocc.c" \
    -o "$OUT/gemmini_rocc_fwd_bm.o"
  GEMMINI_RT_OBJS+=("$OUT/gemmini_rocc_fwd_bm.o")
else
  "$ELF_GCC" "${CFLAGS[@]}" \
    -c "$ROOT/runtime/gemmini/lib/gemmini_wrappers.c" -o "$OUT/gemmini_wrappers_fwd_bm.o"
  GEMMINI_RT_OBJS+=("$OUT/gemmini_wrappers_fwd_bm.o")
fi
for src in buddy_same_upper_maxpool.c buddy_rvv_mem.c buddy_int8_leaky.c \
           buddy_int8_silu.c buddy_int8_sigmoid.c; do
  "$ELF_GCC" "${CFLAGS[@]}" -c "$ROOT/runtime/ops/$src" -o "$OUT/${src%.c}_fwd_bm.o"
done
"$ELF_GCC" "${CFLAGS[@]}" -c "$ROOT/runtime/ops/gemcc_kernel_ops.c" -o "$OUT/gemcc_kernel_ops_fwd_bm.o"

UART_OBJS=()
DIAG_OBJS=()
if [[ ${BOARD:-0} == 1 ]]; then
  echo "=== BOARD UART putchar @ 0x10020000 ==="
  sed 's/^int putchar(int ch)/int putchar_htif(int ch)/' "$SYSCALLS_C" \
    > "$OUT/syscalls_board.c"
  SYSCALLS_C="$OUT/syscalls_board.c"
  "$ELF_GCC" "${CFLAGS[@]}" -c "$MYBOARD_BARE/uart_putchar.c" -o "$OUT/uart_putchar.o"
  UART_OBJS=("$OUT/uart_putchar.o")
  # Optional UART breadcrumbs before the generated model's first printf.
  if [[ ${BOARD_UART_DIAG:-0} == 1 ]]; then
    DIAG_SRC="${BOARD_UART_DIAG_SRC:-/mnt/data/wzr/13p/ov7670/sixteen_camera/artifacts/yolov5nu-dim16-packed-board/uart_diag_main.c}"
    "$ELF_GCC" "${CFLAGS[@]}" -c "$DIAG_SRC" \
      -o "$OUT/uart_diag_main.o"
    DIAG_OBJS=("$OUT/uart_diag_main.o")
  fi
  ELF="$OUT/forward-board.elf"
else
  ELF="$OUT/forward-baremetal.elf"
fi

echo "=== link $ELF ==="
"$ELF_GCC" "${CFLAGS[@]}" -nostdlib -nostartfiles -static -T "$TEST_LD" \
  "$CRT_S" "$SYSCALLS_C" \
  "${UART_OBJS[@]}" \
  "$OUT/forward_medany.o" "$OUT/forward_constants_bm.o" "$OUT/forward_input_embed.o" \
  "$OUT/forward_trampoline_bm.o" "$OUT/gemcc_model_bm.o" "$OUT/gemcc_device_bm.o" "$OUT/memref_copy_bm.o" \
  "$OUT/forward_board_main.o" \
  "${GEMMINI_RT_OBJS[@]}" \
  "$OUT/buddy_same_upper_maxpool_fwd_bm.o" "$OUT/buddy_rvv_mem_fwd_bm.o" \
  "$OUT/buddy_int8_leaky_fwd_bm.o" "$OUT/buddy_int8_silu_fwd_bm.o" \
  "$OUT/buddy_int8_sigmoid_fwd_bm.o" \
  "$OUT/gemcc_kernel_ops_fwd_bm.o" \
  -lm -lgcc "${DIAG_OBJS[@]}" ${BOARD_UART_DIAG:+-Wl,--wrap=main} -o "$ELF"
"$OBJCOPY" --set-section-alignment .rodata=64 "$ELF"
echo "linked $ELF  codegen=${CODEGEN}"
if [[ ${BOARD:-0} == 1 ]]; then
  echo "BOARD UART ELF — do not Spike, do not flash unless authorized"
fi
