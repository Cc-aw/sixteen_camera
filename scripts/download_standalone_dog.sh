#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
DEMO_DIR="$ROOT_DIR/demo/twoGemmini"
BUILD_SCRIPT="$DEMO_DIR/scripts/build_gemmini16_tinyyolov2_counters_board.sh"
RUN_SCRIPT="$DEMO_DIR/scripts/run_dual_gemmini16_board.sh"
ELF_FILE="${STANDALONE_DOG_ELF:-$DEMO_DIR/build16/single-gemmini16-batch2/gemmini16_tinyyolov2_batch1_counters_board.riscv}"
BUILD_ELF=0
CHECK_ONLY=0

usage()
{
    cat <<EOF
用法: $0 [--build] [--check]

下载独立的单 Gemmini16 TinyYOLOv2 dog 测试 ELF。
默认使用 2026-09-06 留存的 batch1/combined1 已测试 ELF；只运行 dog。
该程序只使用 custom3 / busy CSR 0x7c2，不访问视频 MMIO，也不下载 bitstream。

  --build  下载前按最新 batch1/combined1 源码重新构建并覆盖该 ELF
  --check  只检查 ELF，不连接开发板
EOF
}

while (($# != 0)); do
    case "$1" in
    --build) BUILD_ELF=1 ;;
    --check) CHECK_ONLY=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "未知参数: $1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

if ((BUILD_ELF)); then
    "$BUILD_SCRIPT"
fi

[[ -r "$ELF_FILE" ]] || {
    echo "独立 dog ELF 不存在: $ELF_FILE" >&2
    echo "请先执行: $0 --build" >&2
    exit 1
}
[[ -x "$RUN_SCRIPT" ]] || {
    echo "下载入口不存在或不可执行: $RUN_SCRIPT" >&2
    exit 1
}

READELF_BIN="${RISCV_ELF_PREFIX:-/home/wzr/chipyard/.conda-env/riscv-tools/bin/riscv64-unknown-elf-}readelf"
[[ -x "$READELF_BIN" ]] || {
    echo "找不到 readelf: $READELF_BIN" >&2
    exit 1
}
ENTRY="$($READELF_BIN -h "$ELF_FILE" | awk '/Entry point address|入口点地址/ {print $NF; exit}')"
[[ "$ENTRY" == "0x80000000" ]] || {
    echo "ELF 入口错误: $ENTRY" >&2
    exit 1
}

if ((CHECK_ONLY)); then
    echo "STANDALONE_DOG_CHECK=PASS"
    echo "ELF=$ELF_FILE"
    echo "ENTRY=$ENTRY"
    exit 0
fi

echo "下载独立 dog 测试 ELF（保留当前 bitstream）..."
export DUAL_GEMMINI16_BOARD_ELF="$ELF_FILE"
export GDB_REMOTE_TIMEOUT="${GDB_REMOTE_TIMEOUT:-600}"
exec "$RUN_SCRIPT"
