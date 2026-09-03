#!/usr/bin/env bash
set -Eeuo pipefail

# Program the already-built bitstream through Vivado Hardware Manager.
# This script does not rebuild the Vivado project and does not touch the
# Rocket ELF download path; run sw/run.sh separately after programming.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
PRJ_DIR="$ROOT_DIR/prj"
VIVADO_BIN="${VIVADO_BIN:-/mnt/data/Vivado/Vivado/2023.2/bin/vivado}"
BITSTREAM_FILE="${BITSTREAM_FILE:-$PRJ_DIR/sixteen_camera.runs/impl_1/top_wrapper.bit}"
TCL_SCRIPT="${TCL_SCRIPT:-$PRJ_DIR/program_bitstream.tcl}"
LOG_FILE="${LOG_FILE:-$ROOT_DIR/build/program_bitstream.log}"
CHECK_ONLY=0

usage() {
    cat <<EOF
用法: $0 [选项]

通过 Vivado Hardware Manager 下载已有 bitstream 到 FPGA，不重新构建工程。

选项:
  --bitstream PATH  指定 bitstream 文件
  --vivado PATH     指定 Vivado 可执行文件
  --check           只检查路径，不连接开发板
  -h, --help        显示帮助

默认值:
  bitstream: $BITSTREAM_FILE
  Vivado:    $VIVADO_BIN

环境变量 BITSTREAM_FILE、VIVADO_BIN、TCL_SCRIPT、LOG_FILE 也可覆盖默认值。
下载前请关闭 Vivado Hardware Manager 中已打开的硬件连接，避免 JTAG 被占用。
EOF
}

while (($#)); do
    case "$1" in
        --bitstream)
            (($# >= 2)) || { echo "--bitstream 需要一个路径" >&2; exit 2; }
            BITSTREAM_FILE="$2"
            shift
            ;;
        --vivado)
            (($# >= 2)) || { echo "--vivado 需要一个路径" >&2; exit 2; }
            VIVADO_BIN="$2"
            shift
            ;;
        --check) CHECK_ONLY=1 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "未知参数: $1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

[[ -x "$VIVADO_BIN" ]] || {
    echo "找不到可执行 Vivado: $VIVADO_BIN" >&2
    echo "可用 --vivado PATH 或 VIVADO_BIN=PATH 覆盖。" >&2
    exit 1
}
[[ -r "$TCL_SCRIPT" ]] || { echo "找不到 Vivado TCL: $TCL_SCRIPT" >&2; exit 1; }
[[ -s "$BITSTREAM_FILE" ]] || {
    echo "找不到 bitstream 或文件为空: $BITSTREAM_FILE" >&2
    echo "可用 --bitstream PATH 或 BITSTREAM_FILE=PATH 覆盖。" >&2
    exit 1
}

if ((CHECK_ONLY)); then
    echo "DOWNLOAD_BITSTREAM_CHECK=PASS"
    echo "VIVADO=$VIVADO_BIN"
    echo "BITSTREAM=$BITSTREAM_FILE"
    echo "TCL=$TCL_SCRIPT"
    exit 0
fi

mkdir -p "$(dirname -- "$LOG_FILE")"
echo "下载 bitstream 到 FPGA..."
echo "  Vivado:    $VIVADO_BIN"
echo "  Bitstream: $BITSTREAM_FILE"
echo "  日志:      $LOG_FILE"

# program_bitstream.tcl reads BITSTREAM_FILE from the environment and handles
# hardware target/device discovery, programming, refresh, and cleanup.
BITSTREAM_FILE="$BITSTREAM_FILE" \
    "$VIVADO_BIN" -mode batch \
    -log "$LOG_FILE" -source "$TCL_SCRIPT"

echo "BITSTREAM_DOWNLOAD=PASS"
echo "FPGA bitstream 下载完成。"
echo "下一步下载软件："
echo "  cd $ROOT_DIR/sw && ./run.sh --no-build"
