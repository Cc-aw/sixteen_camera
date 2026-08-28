#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
BUILD_FIRMWARE=1
CHECK_ONLY=0

usage() {
    cat <<EOF
用法: $0 [选项]
  --no-build  使用已有 ELF，不重新编译固件
  --check     只检查工具、配置和 ELF，不连接开发板
  -h, --help  显示帮助

本脚本只下载软件，不操作 FPGA bitstream，也不启动串口。
串口请单独执行: tio-start （固定使用 /dev/ttyACM0，115200 8N1）
EOF
}

while (($#)); do
    case "$1" in
        --no-build) BUILD_FIRMWARE=0 ;;
        --check) CHECK_ONLY=1 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "未知参数: $1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

if ((CHECK_ONLY)); then
    if ((BUILD_FIRMWARE)); then
        "$ROOT_DIR/sw/run.sh" --check
    else
        "$ROOT_DIR/sw/run.sh" --no-build --check
    fi
    exit 0
fi

echo "下载软件到 Rocket（假定 FPGA bitstream 已由用户提前下载）..."
if ((BUILD_FIRMWARE)); then
    exec "$ROOT_DIR/sw/run.sh"
else
    exec "$ROOT_DIR/sw/run.sh" --no-build
fi
