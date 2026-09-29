#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

if (($#)); then
    case "$1" in
        -h|--help)
            echo "用法: $0"
            echo "只编译并通过 JTAG 下载；不会打开串口或发送 t。"
            exit 0
            ;;
        *)
            echo "未知参数: $1" >&2
            exit 2
            ;;
    esac
fi

echo "[1/2] 构建双 Gemmini16 YOLOv5nu 软件..."
make -C "$ROOT_DIR/software" clean
make -C "$ROOT_DIR/software" -j"${JOBS:-4}"

echo "[2/2] 下载软件（沿用当前 FPGA bitstream）..."
ELF_FILE="$ROOT_DIR/software/build/hdmi_tx_test.elf" \
    "$SCRIPT_DIR/download_yolov5nu_board.sh"

echo "脚本不会打开或读写串口。"
echo "请在你已经打开的串口终端中手动按 t 启动正确性测试。"
echo "通过标志：YOLOV5NU_TEST_RESULT PASS reference=bit_exact dual=bit_exact"
