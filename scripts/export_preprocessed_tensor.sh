#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
OPENOCD_BIN="${OPENOCD_BIN:-/home/wzr/riscv-openocd/src/openocd}"
OPENOCD_CFG="${OPENOCD_CFG:-/home/wzr/chipyard/fpga/src/main/resources/myboard/openocd-bscan.cfg}"
GDB_BIN="${GDB_BIN:-/home/wzr/chipyard/.conda-env/riscv-tools/bin/riscv64-unknown-elf-gdb}"
GDB_PYTHONHOME="${GDB_PYTHONHOME:-/home/wzr/chipyard/.conda-env}"
PYTHON_BIN="${PYTHON_BIN:-/home/wzr/chipyard/.conda-env/bin/python}"
ELF_FILE="${ELF_FILE:-$ROOT_DIR/sw/build/hdmi_tx_test.elf}"
CAPTURE_DIR="${CAPTURE_DIR:-$ROOT_DIR/captures}"

TENSOR_WIDTH=640
TENSOR_HEIGHT=480
TENSOR_CHANNELS=3
TENSOR_BYTES=$((TENSOR_WIDTH * TENSOR_HEIGHT * TENSOR_CHANNELS))
TENSOR_MEMBER_STRIDE=$TENSOR_BYTES
PHYS_BASE="${1:-}"
CHANNEL="${2:-1}"
OPENOCD_LOG="$CAPTURE_DIR/export_tensor_openocd.log"
OPENOCD_PID=""

usage()
{
    cat <<EOF
用法: $0 <tensor_base> [channel]

从当前视频固件的 tensor arena 导出一张 640x480 RGB PNG。

  tensor_base  串口 'AI PRE arena/base' 打印的物理基地址：
               0x30000000 或 0x31000000
  channel      1..16，默认 1

操作前先在串口按 i 关闭 AI，并用 s 确认 enable/drain=0/0、
writing=0。tensor_base 选择最近出现 READY 的 slot 所属 arena。
脚本只会暂停 CPU 读取 DDR，
不会下载 ELF 或 bitstream，读取完成后会恢复 CPU。
EOF
}

if [[ "$PHYS_BASE" == "-h" || "$PHYS_BASE" == "--help" ]]; then
    usage
    exit 0
fi
if [[ -z "$PHYS_BASE" ]]; then
    usage >&2
    exit 2
fi
if [[ "$PHYS_BASE" != "0x30000000" && "$PHYS_BASE" != "0X30000000" &&
      "$PHYS_BASE" != "0x31000000" && "$PHYS_BASE" != "0X31000000" ]]; then
    echo "tensor_base 必须是 0x30000000 或 0x31000000: $PHYS_BASE" >&2
    exit 2
fi
if ! [[ "$CHANNEL" =~ ^[0-9]+$ ]] || ((CHANNEL < 1 || CHANNEL > 16)); then
    echo "channel 必须为 1..16: $CHANNEL" >&2
    exit 2
fi

for path in "$OPENOCD_BIN" "$GDB_BIN" "$PYTHON_BIN"; do
    [[ -x "$path" ]] || { echo "找不到可执行文件: $path" >&2; exit 1; }
done
[[ -r "$OPENOCD_CFG" ]] || { echo "找不到 OpenOCD 配置: $OPENOCD_CFG" >&2; exit 1; }
[[ -r "$ELF_FILE" ]] || { echo "找不到视频 ELF: $ELF_FILE" >&2; exit 1; }

phys_value=$((PHYS_BASE))
channel_offset=$(((CHANNEL - 1) * TENSOR_MEMBER_STRIDE))
coherent_start=$(((phys_value + channel_offset) | 0x80000000))
coherent_end=$((coherent_start + TENSOR_BYTES))
printf -v coherent_start_hex '0x%08x' "$coherent_start"
printf -v coherent_end_hex '0x%08x' "$coherent_end"

mkdir -p "$CAPTURE_DIR"
RAW_FILE="$CAPTURE_DIR/ch${CHANNEL}_tensor_640x480_int8.raw"
PNG_FILE="$CAPTURE_DIR/ch${CHANNEL}_tensor_640x480_rgb.png"

cleanup()
{
    if [[ -n "$OPENOCD_PID" ]] && kill -0 "$OPENOCD_PID" 2>/dev/null; then
        kill "$OPENOCD_PID" 2>/dev/null || true
        wait "$OPENOCD_PID" 2>/dev/null || true
    fi
}
trap cleanup EXIT INT TERM

if ss -ltn 2>/dev/null | grep -qE '[:.]3333[[:space:]]'; then
    echo "TCP 3333 已被占用，请关闭其他 OpenOCD。" >&2
    exit 1
fi

: >"$OPENOCD_LOG"
"$OPENOCD_BIN" -f "$OPENOCD_CFG" >"$OPENOCD_LOG" 2>&1 &
OPENOCD_PID=$!

ready=0
for _ in {1..75}; do
    if ! kill -0 "$OPENOCD_PID" 2>/dev/null; then
        tail -n 40 "$OPENOCD_LOG" >&2
        exit 1
    fi
    if grep -q "Listening on port 3333 for gdb connections" "$OPENOCD_LOG" &&
       grep -q "Target successfully examined" "$OPENOCD_LOG"; then
        ready=1
        break
    fi
    sleep 0.2
done
if ((ready == 0)); then
    echo "等待 Rocket Debug Module 就绪超时。" >&2
    tail -n 40 "$OPENOCD_LOG" >&2
    exit 1
fi

echo "导出 CH$CHANNEL tensor: $coherent_start_hex..$coherent_end_hex"
PYTHONHOME="$GDB_PYTHONHOME" "$GDB_BIN" -q -batch "$ELF_FILE" \
    -ex "set pagination off" \
    -ex "set confirm off" \
    -ex "set remotetimeout 120" \
    -ex "target extended-remote localhost:3333" \
    -ex "monitor halt" \
    -ex "dump binary memory $RAW_FILE $coherent_start_hex $coherent_end_hex" \
    -ex "monitor resume" \
    -ex "disconnect"

[[ -r "$RAW_FILE" ]] || { echo "GDB 未生成 raw tensor" >&2; exit 1; }
raw_size="$(stat -c %s "$RAW_FILE")"
if [[ "$raw_size" -ne "$TENSOR_BYTES" ]]; then
    echo "tensor 大小错误: $raw_size，期望 $TENSOR_BYTES" >&2
    exit 1
fi

"$PYTHON_BIN" - "$RAW_FILE" "$PNG_FILE" <<'PY'
import sys

import numpy as np
from PIL import Image

raw_path, png_path = sys.argv[1:]
tensor = np.fromfile(raw_path, dtype=np.uint8)
if tensor.size != 640 * 480 * 3:
    raise SystemExit(f"unexpected tensor size: {tensor.size}")
tensor = tensor.reshape(480, 640, 3)
# FPGA quantization is unsigned RGB888 >> 1, stored in signed-int8 storage
# but restricted to 0..127.  Expand it for normal PNG viewing.
rgb = np.minimum(tensor.astype(np.uint16) * 2, 255).astype(np.uint8)
Image.fromarray(rgb, "RGB").save(png_path)
print("RGB min/max/mean:",
      [(int(rgb[..., c].min()), int(rgb[..., c].max()),
        round(float(rgb[..., c].mean()), 2)) for c in range(3)])
PY

echo "TENSOR_EXPORT=PASS"
echo "RAW=$RAW_FILE"
echo "PNG=$PNG_FILE"
