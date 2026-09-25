#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
OPENOCD_BIN="${OPENOCD_BIN:-/home/wzr/riscv-openocd/src/openocd}"
OPENOCD_CFG="${OPENOCD_CFG:-/home/wzr/chipyard/fpga/src/main/resources/myboard/openocd-bscan.cfg}"
GDB_BIN="${GDB_BIN:-/home/wzr/chipyard/.conda-env/riscv-tools/bin/riscv64-unknown-elf-gdb}"
GDB_PYTHONHOME="${GDB_PYTHONHOME:-/home/wzr/chipyard/.conda-env}"
VIDEO_VARIANT="${VIDEO_VARIANT:-single4}"
case "$VIDEO_VARIANT" in
    single4) DEFAULT_ELF="$SCRIPT_DIR/build/gemmini_single4_video_yolov5nu.elf" ;;
    dual16) DEFAULT_ELF="$SCRIPT_DIR/build/gemmini_dual16_video_yolov5nu.elf" ;;
    *) echo "VIDEO_VARIANT 必须为 single4 或 dual16" >&2; exit 2 ;;
esac
ELF_FILE="${ELF_FILE:-$DEFAULT_ELF}"
GDB_COMMANDS="$SCRIPT_DIR/openocd/load-hdmi-tx.gdb"
OPENOCD_LOG="$SCRIPT_DIR/build/openocd.log"
OPENOCD_PID=""
BUILD_FIRMWARE=0
CHECK_ONLY=0

usage()
{
    cat <<EOF
用法: $0 [--build|--no-build] [--check]

  --build     下载前构建所选 SoC 的 PPU 视频固件
  --no-build  使用已有 ELF，不执行 make（默认）
  --check     只检查工具、配置和 ELF，不连接开发板

默认单 4×4；双 16×16 使用 VIDEO_VARIANT=dual16。
可通过 OPENOCD_BIN、OPENOCD_CFG、GDB_BIN、GDB_PYTHONHOME 和 ELF_FILE
环境变量覆盖默认路径。
EOF
}

while (($# != 0)); do
    case "$1" in
    --build)
        BUILD_FIRMWARE=1
        ;;
    --no-build)
        BUILD_FIRMWARE=0
        ;;
    --check)
        CHECK_ONLY=1
        ;;
    -h|--help)
        usage
        exit 0
        ;;
    *)
        echo "未知参数: $1" >&2
        usage >&2
        exit 2
        ;;
    esac
    shift
done

cleanup()
{
    if [[ -n "$OPENOCD_PID" ]] && kill -0 "$OPENOCD_PID" 2>/dev/null; then
        kill "$OPENOCD_PID" 2>/dev/null || true
        wait "$OPENOCD_PID" 2>/dev/null || true
    fi
}
trap cleanup EXIT INT TERM

[[ -x "$OPENOCD_BIN" ]] || { echo "找不到 OpenOCD: $OPENOCD_BIN" >&2; exit 1; }
[[ -x "$GDB_BIN" ]] || { echo "找不到 GDB: $GDB_BIN" >&2; exit 1; }
[[ -r "$OPENOCD_CFG" ]] || { echo "找不到 OpenOCD 配置: $OPENOCD_CFG" >&2; exit 1; }
[[ -r "$GDB_COMMANDS" ]] || { echo "找不到 GDB 命令文件: $GDB_COMMANDS" >&2; exit 1; }

if ((BUILD_FIRMWARE)); then
    echo "[1/4] 编译当前视频固件..."
    python3 "$SCRIPT_DIR/../scripts/build_${VIDEO_VARIANT}_video_yolov5nu.py" --output "$ELF_FILE"
else
    echo "[1/4] 使用已有固件。"
fi
[[ -r "$ELF_FILE" ]] || { echo "ELF 不存在: $ELF_FILE" >&2; exit 1; }

if ((CHECK_ONLY)); then
    echo "DOWNLOAD_SW_CHECK=PASS"
    echo "ELF=$ELF_FILE"
    exit 0
fi

if ss -ltn 2>/dev/null | grep -qE '[:.]3333[[:space:]]'; then
    echo "TCP 3333 已被占用，请关闭已有 OpenOCD。" >&2
    exit 1
fi

echo "[2/4] 启动 OpenOCD（请先确保本工程 bitstream 已下载）..."
mkdir -p "$SCRIPT_DIR/build"
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
    if grep -q "LIBUSB_ERROR_BUSY" "$OPENOCD_LOG"; then
        echo "JTAG 正被 Vivado Hardware Manager 或另一个 OpenOCD 占用。" >&2
    fi
    tail -n 40 "$OPENOCD_LOG" >&2
    exit 1
fi

echo "[3/4] 下载并启动固件: $ELF_FILE"
set +e
PYTHONHOME="$GDB_PYTHONHOME" "$GDB_BIN" -q -batch "$ELF_FILE" -x "$GDB_COMMANDS"
gdb_status=$?
set -e

if ((gdb_status != 0)); then
    echo "GDB 下载失败，OpenOCD 日志: $OPENOCD_LOG" >&2
    exit "$gdb_status"
fi

echo "[4/4] 固件已启动，OpenOCD 已退出。"
echo "串口: 115200 8N1；日志: $OPENOCD_LOG"
