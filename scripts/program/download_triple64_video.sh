#!/usr/bin/env bash
set -Eeuo pipefail

# Reusable board download for the triple 64x64 Gemmini RGB565 video firmware.
# The FPGA bitstream must already be programmed.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
ELF_FILE="${ELF_FILE:-$ROOT_DIR/build/firmware/gemmini_triple64_video_yolov5nu.elf}"
export ELF_FILE
export VIDEO_VARIANT=triple64

case "${1:-}" in
    ""|--check|--build|--no-build)
        exec "$ROOT_DIR/sw/run.sh" "$@"
        ;;
    -h|--help)
        cat <<EOF
用法: $0 [--build|--no-build] [--check]

下载三路 64x64 Gemmini 的 RGB565 视频 YOLOv5nu + PPU 二阶段 ELF。
默认 ELF: $ELF_FILE
先运行 scripts/program/download_bitstream.sh，串口用 tio-start。
可用 ELF_FILE 覆盖默认 ELF；--check 只检查文件和工具。
EOF
        ;;
    *)
        echo "未知参数: $1" >&2
        exit 2
        ;;
esac
