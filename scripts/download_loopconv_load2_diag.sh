#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
DEMO_DIR="$ROOT_DIR/demo/twoGemmini"
BUILD_SCRIPT="$DEMO_DIR/scripts/build_gemmini16_loopconv_load2_diag_board.sh"
RUN_SCRIPT="$DEMO_DIR/scripts/run_dual_gemmini16_board.sh"
ELF_FILE="${GEMMINI16_LOAD2_ELF:-$DEMO_DIR/build16/load2-diag/gemmini16_loopconv_load2_diag_board.riscv}"

if [[ "${1:-}" == "--build" ]]; then
  "$BUILD_SCRIPT"
  shift
fi
if (($# != 0)); then
  echo "用法: $0 [--build]" >&2
  exit 2
fi
[[ -r "$ELF_FILE" ]] || "$BUILD_SCRIPT"

echo "下载 Gemmini16 LoopConv LOAD2/mvin2 对照诊断 ELF（不下载 bitstream）..."
export DUAL_GEMMINI16_BOARD_ELF="$ELF_FILE"
export GDB_REMOTE_TIMEOUT="${GDB_REMOTE_TIMEOUT:-600}"
exec "$RUN_SCRIPT"
