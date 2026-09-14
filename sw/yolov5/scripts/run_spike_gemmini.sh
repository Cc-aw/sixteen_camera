#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPIKE="${SPIKE:-${ROOT_DIR}/.conda-env/riscv-tools/bin/spike}"
GEMMINI_EXT="${GEMMINI_EXT:-${ROOT_DIR}/generators/gemmini/software/libgemmini}"

if [[ ! -x "${SPIKE}" ]]; then
  SPIKE="$(command -v spike || true)"
fi
if [[ -z "${SPIKE}" || ! -x "${SPIKE}" ]]; then
  echo "error: Gemmini-capable Spike was not found" >&2
  exit 2
fi
if [[ ! -f "${GEMMINI_EXT}/libgemmini.so" ]]; then
  echo "error: Gemmini Spike extension not found at ${GEMMINI_EXT}/libgemmini.so" >&2
  echo "hint: env RISCV=${ROOT_DIR}/.conda-env/riscv-tools make -B -C generators/gemmini/software/libgemmini" >&2
  exit 2
fi
if [[ "$#" -eq 0 ]]; then
  echo "usage: $0 [spike options] <elf> [target options]" >&2
  exit 2
fi

export LD_LIBRARY_PATH="${GEMMINI_EXT}:${ROOT_DIR}/.conda-env/riscv-tools/lib:${LD_LIBRARY_PATH:-}"
exec "${SPIKE}" --extension=gemmini "$@"
