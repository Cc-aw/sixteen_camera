#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GEMMINI_DIR="${ROOT_DIR}/generators/gemmini/software/gemmini-rocc-tests"
BUILD_DIR="${GEMMINI_DIR}/build/bareMetalC"
SRC="${GEMMINI_DIR}/bareMetalC/yolov5nu_stage41_rvv_smoke.c"
RISCV="${RISCV:-${ROOT_DIR}/.conda-env/riscv-tools}"
BENCH_COMMON="${GEMMINI_DIR}/riscv-tests/benchmarks/common"
TARGET="${RVV_TARGET:-sim}"
QUICK="${STAGE5_SMOKE_QUICK:-0}"

case "${TARGET}" in
  fpga)
    OUT="${BUILD_DIR}/yolov5nu-stage41-rvv-smoke-baremetal-uart"
    TARGET_DEFINES=(-DFPGA_MMIO_UART=1 -DFPGA_UART_BASE=0x10020000UL -DFPGA_UART_DIVISOR=434)
    ;;
  sim)
    OUT="${BUILD_DIR}/yolov5nu-stage41-rvv-smoke-baremetal"
    TARGET_DEFINES=()
    ;;
  *) echo "Unsupported RVV_TARGET=${TARGET}; use fpga or sim" >&2; exit 2 ;;
esac

mkdir -p "${BUILD_DIR}"
"${RISCV}/bin/riscv64-unknown-elf-gcc" \
  -DPREALLOCATE=1 -DMULTITHREAD=1 -mcmodel=medany -std=gnu99 -O2 \
  -ffast-math -fno-common -fno-builtin-printf \
  -fno-tree-loop-distribute-patterns -march=rv64gcv -Wa,-march=rv64gcv \
  -mabi=lp64d -nostdlib -nostartfiles -static -T "${BENCH_COMMON}/test.ld" \
  -DBAREMETAL=1 "${TARGET_DEFINES[@]}" \
  -DSTAGE5_RTL_QUICK="${QUICK}" \
  -I"${GEMMINI_DIR}/riscv-tests" -I"${GEMMINI_DIR}/riscv-tests/env" \
  -I"${GEMMINI_DIR}" -I"${BENCH_COMMON}" \
  "${SRC}" "${BENCH_COMMON}"/*.c "${BENCH_COMMON}"/*.S -lm -lgcc -o "${OUT}"

DUMP="${OUT}.dump"
"${RISCV}/bin/riscv64-unknown-elf-objdump" -d "${OUT}" > "${DUMP}"
for instruction in vredmax.vs vfirst.m vfadd.vv vfcvt.x.f.v vnclip.wi; do
  if ! rg -q "${instruction//./\.}" "${DUMP}"; then
    echo "error: ${OUT} does not contain ${instruction}" >&2
    exit 1
  fi
done
echo "Built and checked: ${OUT}"
