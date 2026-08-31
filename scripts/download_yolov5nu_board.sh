#!/usr/bin/env bash
set -Eeuo pipefail

# Download the local YOLOv5nu DIM16 board ELF through the Rocket JTAG DTM.
# The FPGA bitstream must already be loaded. Serial is intentionally left to
# the user (tio-start uses /dev/ttyACM0 in this project).

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
ELF_FILE="${ELF_FILE:-$ROOT_DIR/artifacts/yolov5nu-dim16-packed-board/forward-board.elf}"
OPENOCD_BIN="${OPENOCD_BIN:-/home/wzr/riscv-openocd/src/openocd}"
OPENOCD_CFG="${OPENOCD_CFG:-/home/wzr/chipyard/fpga/src/main/resources/myboard/openocd-bscan.cfg}"
GDB_BIN="${GDB_BIN:-/home/wzr/chipyard/.conda-env/riscv-tools/bin/riscv64-unknown-elf-gdb}"
GDB_PYTHONHOME="${GDB_PYTHONHOME:-/home/wzr/chipyard/.conda-env}"
LOG_FILE="${LOG_FILE:-$ROOT_DIR/build/yolov5nu-openocd.log}"
OPENOCD_PID=""

usage() {
    cat <<EOF
用法: $0 [--check]

默认只通过 JTAG 下载并启动：
  $ELF_FILE

要求：bitstream 已提前下载，且 Vivado Hardware Manager 未占用 JTAG。
串口请另开终端执行：tio-start（/dev/ttyACM0，115200 8N1）。

环境变量：ELF_FILE OPENOCD_BIN OPENOCD_CFG GDB_BIN GDB_PYTHONHOME LOG_FILE
EOF
}

CHECK_ONLY=0
while (($#)); do
    case "$1" in
        --check) CHECK_ONLY=1 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "未知参数: $1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

[[ -r "$ELF_FILE" ]] || { echo "找不到 ELF: $ELF_FILE" >&2; exit 1; }
[[ -x "$OPENOCD_BIN" ]] || { echo "找不到 OpenOCD: $OPENOCD_BIN" >&2; exit 1; }
[[ -x "$GDB_BIN" ]] || { echo "找不到 GDB: $GDB_BIN" >&2; exit 1; }
[[ -r "$OPENOCD_CFG" ]] || { echo "找不到 OpenOCD 配置: $OPENOCD_CFG" >&2; exit 1; }

if ((CHECK_ONLY)); then
    echo "DOWNLOAD_YOLOV5NU_CHECK=PASS"
    echo "ELF=$ELF_FILE"
    exit 0
fi

mkdir -p "$(dirname -- "$LOG_FILE")"
: >"$LOG_FILE"
cleanup() {
    if [[ -n "$OPENOCD_PID" ]] && kill -0 "$OPENOCD_PID" 2>/dev/null; then
        kill "$OPENOCD_PID" 2>/dev/null || true
        wait "$OPENOCD_PID" 2>/dev/null || true
    fi
}
trap cleanup EXIT INT TERM

if ss -ltn 2>/dev/null | grep -qE '[:.]3333[[:space:]]'; then
    echo "TCP 3333 已被占用，请关闭已有 OpenOCD。" >&2
    exit 1
fi

echo "[1/3] 启动 OpenOCD..."
"$OPENOCD_BIN" -f "$OPENOCD_CFG" >"$LOG_FILE" 2>&1 &
OPENOCD_PID=$!
ready=0
for _ in {1..100}; do
    if ! kill -0 "$OPENOCD_PID" 2>/dev/null; then
        tail -n 40 "$LOG_FILE" >&2
        exit 1
    fi
    if grep -q "Listening on port 3333 for gdb connections" "$LOG_FILE" && \
       grep -q "Target successfully examined" "$LOG_FILE"; then
        ready=1
        break
    fi
    sleep 0.2
done
if ((ready == 0)); then
    echo "等待 Rocket Debug Module 超时。" >&2
    tail -n 40 "$LOG_FILE" >&2
    exit 1
fi

echo "[2/3] 下载并启动 YOLOv5nu DIM16 ELF..."
set +e
PYTHONHOME="$GDB_PYTHONHOME" "$GDB_BIN" -q -batch "$ELF_FILE" \
    -ex 'set pagination off' \
    -ex 'set confirm off' \
    -ex 'set remotetimeout 120' \
    -ex 'target extended-remote localhost:3333' \
    -ex 'monitor reset halt' \
    -ex 'load' \
    -ex 'set $pc = _start' \
    -ex 'monitor resume' \
    -ex 'disconnect' \
    -ex 'quit 0'
GDB_STATUS=$?
set -e
if ((GDB_STATUS != 0)); then
    echo "GDB 下载失败，OpenOCD 日志：$LOG_FILE" >&2
    exit "$GDB_STATUS"
fi

echo "[3/3] 下载完成，CPU 已开始执行。"
echo "串口：tio-start（/dev/ttyACM0，115200 8N1）"
echo "OpenOCD 日志：$LOG_FILE"
