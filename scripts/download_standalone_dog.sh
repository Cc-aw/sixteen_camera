#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
FROZEN_DIR="$ROOT_DIR/artifacts/dual-gemmini16-dog-ddr"
ELF_FILE="$FROZEN_DIR/gemmini16_tinyyolov2_dog_only_board.riscv"
EXPECTED_SHA256="f52d0eab0750a9bfe0c71a721061ccd874e8385cd5cef2f37d1a35da8c07a914"
CHECK_ONLY=0

usage()
{
    cat <<EOF
用法: $0 [--check]

下载冻结的双 Gemmini16 SoC 单 dog TinyYOLOv2 DDR 基线 ELF。
该镜像固定使用内置 dog 输入和 worker0（custom3 / busy CSR 0x7c2），
不访问视频 MMIO，也不下载或修改 bitstream。

  --check  校验 ELF 架构、入口和 SHA-256，不连接开发板
EOF
}

while (($# != 0)); do
    case "$1" in
    --check) CHECK_ONLY=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "未知参数: $1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

[[ -r "$ELF_FILE" ]] || {
    echo "冻结的 dog ELF 不存在: $ELF_FILE" >&2
    exit 1
}

READELF_BIN="${RISCV_ELF_PREFIX:-/home/wzr/chipyard/.conda-env/riscv-tools/bin/riscv64-unknown-elf-}readelf"
[[ -x "$READELF_BIN" ]] || {
    echo "找不到 readelf: $READELF_BIN" >&2
    exit 1
}

ENTRY="$($READELF_BIN -h "$ELF_FILE" |
    awk '/Entry point address|入口点地址/ {print $NF; exit}')"
MACHINE="$($READELF_BIN -h "$ELF_FILE" |
    awk -F: '/Machine:|系统架构:/ {sub(/^[[:space:]]+/, "", $2); print $2; exit}')"
OBSERVED_SHA256="$(sha256sum "$ELF_FILE" | awk '{print $1}')"

[[ "$ENTRY" == "0x80000000" ]] || {
    echo "ELF 入口错误: $ENTRY" >&2
    exit 1
}
[[ "$MACHINE" == "RISC-V" ]] || {
    echo "ELF 架构错误: $MACHINE" >&2
    exit 1
}
[[ "$OBSERVED_SHA256" == "$EXPECTED_SHA256" ]] || {
    echo "ELF SHA-256 错误: $OBSERVED_SHA256" >&2
    exit 1
}

echo "STANDALONE_DOG_CHECK=PASS"
echo "ELF=$ELF_FILE"
echo "ENTRY=$ENTRY"
echo "SHA256=$OBSERVED_SHA256"

if ((CHECK_ONLY)); then
    exit 0
fi

echo "下载冻结的单 dog DDR 基线 ELF（保留当前 bitstream）..."
ELF_FILE="$ELF_FILE" exec "$ROOT_DIR/sw/run.sh" --no-build
