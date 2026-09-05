#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
OPENOCD_BIN="${OPENOCD_BIN:-/home/wzr/riscv-openocd/src/openocd}"
OPENOCD_CFG="${OPENOCD_CFG:-/home/wzr/chipyard/fpga/src/main/resources/myboard/openocd-bscan.cfg}"
GDB_BIN="${GDB_BIN:-/home/wzr/chipyard/.conda-env/riscv-tools/bin/riscv64-unknown-elf-gdb}"
GDB_PYTHONHOME="${GDB_PYTHONHOME:-/home/wzr/chipyard/.conda-env}"
ELF_FILE="${ELF_FILE:-$SCRIPT_DIR/build/hdmi_tx_test_legacy_soc.elf}"
GDB_COMMANDS="$SCRIPT_DIR/openocd/load-ov5645-hdmi.gdb"
OPENOCD_LOG="$SCRIPT_DIR/build/openocd.log"
OPENOCD_PID=""
BUILD_FIRMWARE=0
CHECK_ONLY=0

usage()
{
    cat <<EOF
用法: $0 [--build|--no-build] [--check]

  --build     下载前执行 make（仅在固件源码与当前 SoC 匹配时使用）
  --no-build  使用已有 ELF，不执行 make（默认）
  --check     只检查工具、配置和 ELF，不连接开发板

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
    echo "[1/4] 编译 8x OV7670 -> DDR -> HDMI 固件..."
    make -C "$SCRIPT_DIR"
else
    echo "[1/4] 使用已有固件。"
fi
[[ -r "$ELF_FILE" ]] || { echo "ELF 不存在: $ELF_FILE" >&2; exit 1; }

# SmallRocketVideoDDR256MyBoardConfig has no F/D extension.  Reject a stale
# lp64d ELF before opening JTAG so GDB does not fail with "bfd requires flen".
READELF_BIN="${GDB_BIN%gdb}readelf"
if [[ -x "$READELF_BIN" ]]; then
    ELF_FLAGS="$($READELF_BIN -h "$ELF_FILE" 2>/dev/null | sed -n 's/.*Flags:[[:space:]]*//p; s/.*标志：[[:space:]]*//p')"
    if [[ "$ELF_FLAGS" == *"double-float ABI"* ||
          "$ELF_FLAGS" == *"single-float ABI"* ]]; then
        echo "ELF 与当前无 FPU 的 Rocket 不兼容: $ELF_FILE" >&2
        echo "检测到硬浮点 ABI: $ELF_FLAGS" >&2
        echo "请使用 rv64imac/lp64（soft-float）固件。" >&2
        exit 1
    fi
fi

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

echo "[3/4] 下载并启动摄像头 HDMI 固件..."
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
