#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GEMMINI_DIR="${ROOT_DIR}/generators/gemmini/software/gemmini-rocc-tests"
BUILD_DIR="${GEMMINI_DIR}/build/bareMetalC"
SRC="${GEMMINI_DIR}/bareMetalC/yolov5nu_silu_lut_rvv_smoke.c"
RISCV="${RISCV:-${ROOT_DIR}/.conda-env/riscv-tools}"
BENCH_COMMON="${GEMMINI_DIR}/riscv-tests/benchmarks/common"
MARCH="${RVV_MARCH:-rv64gcv}"
TARGET="${RVV_TARGET:-sim}"

case "${TARGET}" in
  fpga)
    SUFFIX="-baremetal-uart"
    TARGET_DEFINES=(
      -DFPGA_MMIO_UART=1
      -DFPGA_UART_BASE=0x10020000UL
      -DFPGA_UART_DIVISOR=434
    )
    ;;
  sim)
    SUFFIX="-baremetal"
    TARGET_DEFINES=()
    ;;
  *)
    echo "Unsupported RVV_TARGET=${TARGET}; use fpga or sim" >&2
    exit 2
    ;;
esac

mkdir -p "${BUILD_DIR}"

for LMUL in 1 2; do
  OUT="${BUILD_DIR}/yolov5nu-silu-lut-rvv-e8m${LMUL}-smoke${SUFFIX}"
  "${RISCV}/bin/riscv64-unknown-elf-gcc" \
    -DPREALLOCATE=1 \
    -DMULTITHREAD=1 \
    -DYOLOV5NU_SILU_RVV_LMUL="${LMUL}" \
    -mcmodel=medany \
    -std=gnu99 \
    -O2 \
    -ffast-math \
    -fno-common \
    -fno-builtin-printf \
    -fno-tree-loop-distribute-patterns \
    -march="${MARCH}" \
    -Wa,-march="${MARCH}" \
    -mabi=lp64d \
    -nostdlib \
    -nostartfiles \
    -static \
    -T "${BENCH_COMMON}/test.ld" \
    -DBAREMETAL=1 \
    "${TARGET_DEFINES[@]}" \
    -I"${GEMMINI_DIR}/riscv-tests" \
    -I"${GEMMINI_DIR}/riscv-tests/env" \
    -I"${GEMMINI_DIR}" \
    -I"${BENCH_COMMON}" \
    "${SRC}" \
    "${BENCH_COMMON}"/*.c \
    "${BENCH_COMMON}"/*.S \
    -lm \
    -lgcc \
    -o "${OUT}"

  if ! "${RISCV}/bin/riscv64-unknown-elf-objdump" -d "${OUT}" | grep -q "vluxei8.v"; then
    echo "error: ${OUT} does not contain vluxei8.v" >&2
    exit 1
  fi
  echo "Built and checked: ${OUT}"
done
