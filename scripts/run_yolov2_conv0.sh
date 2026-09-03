#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHIPYARD="${CHIPYARD_ROOT:-/home/wzr/chipyard}"
OPENOCD="${OPENOCD:-/home/wzr/riscv-openocd/src/openocd}"
GDB="${RISCV_GDB:-$CHIPYARD/.conda-env/riscv-tools/bin/riscv64-unknown-elf-gdb}"
ELF="${YOLOV2_CONV0_ELF:-$ROOT/sw/build/yolov2-conv0/yolov2-conv0.elf}"
LOG="${YOLOV2_CONV0_OPENOCD_LOG:-/tmp/yolov2-conv0-openocd.log}"

if [[ "${1:-}" != "--no-build" ]]; then
  "$ROOT/scripts/build_yolov2_conv0.sh"
fi
[[ -f "$ELF" ]] || { echo "ERROR: missing ELF: $ELF" >&2; exit 1; }
[[ -x "$OPENOCD" && -x "$GDB" ]] || { echo "ERROR: missing OpenOCD or GDB" >&2; exit 1; }

OPENOCD_CFG_REAL="${OPENOCD_CFG:-${YOLOV2_CONV0_OPENOCD_CFG:-/home/wzr/chipyard/fpga/src/main/resources/myboard/openocd-bscan.cfg}}"
[[ -f "$OPENOCD_CFG_REAL" ]] || { echo "ERROR: missing OpenOCD config: $OPENOCD_CFG_REAL" >&2; exit 1; }

: >"$LOG"
"$OPENOCD" -f "$OPENOCD_CFG_REAL" >"$LOG" 2>&1 &
OPENOCD_PID=$!
cleanup() { kill "$OPENOCD_PID" 2>/dev/null || true; wait "$OPENOCD_PID" 2>/dev/null || true; }
trap cleanup EXIT INT TERM

for _ in $(seq 1 100); do
  grep -q "Listening on port 3333" "$LOG" && break
  kill -0 "$OPENOCD_PID" 2>/dev/null || break
  sleep 0.2
done
grep -q "Listening on port 3333" "$LOG" || {
  echo "ERROR: OpenOCD did not become ready; see $LOG" >&2
  sed -n '1,80p' "$LOG" >&2
  exit 1
}

PYTHONHOME="$CHIPYARD/.conda-env" "$GDB" --batch "$ELF" \
  -ex "set pagination off" -ex "set confirm off" \
  -ex "set remotetimeout 600" \
  -ex "target extended-remote localhost:3333" \
  -ex "monitor reset halt" -ex "load" \
  -ex "set \$pc = 0x80000000" \
  -ex "monitor resume 0x80000000" -ex "disconnect"

echo "YOLOv2 conv0 started; monitor UART at 115200 baud for CONV0 FENCE DONE or CONV0 TRAP."
