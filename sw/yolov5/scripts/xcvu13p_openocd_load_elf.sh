#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <program.elf> [entry-address]" >&2
  echo "Example: $0 generators/gemmini/software/gemmini-rocc-tests/build/bareMetalC/template-baremetal" >&2
  exit 1
fi

ELF="$1"
if [[ ! -f "${ELF}" ]]; then
  echo "ERROR: ELF not found: ${ELF}" >&2
  exit 1
fi

if [[ -z "${RISCV:-}" && -r "${ROOT_DIR}/env.sh" ]]; then
  # shellcheck disable=SC1091
  source "${ROOT_DIR}/env.sh" >/dev/null 2>&1 || true
fi

OPENOCD="${OPENOCD:-${RISCV:-${ROOT_DIR}/.conda-env/riscv-tools}/bin/openocd}"
GDB="${GDB:-${RISCV:-${ROOT_DIR}/.conda-env/riscv-tools}/bin/riscv64-unknown-elf-gdb}"
READELF="${READELF:-${RISCV:-${ROOT_DIR}/.conda-env/riscv-tools}/bin/riscv64-unknown-elf-readelf}"
OPENOCD_CFG="${OPENOCD_CFG:-${ROOT_DIR}/fpga/xcvu13p/openocd/xcvu13p-ft2232h.cfg}"
# This FT2232H/FMC path has repeatedly returned dmstatus=0 at 1 MHz while the
# same target examines correctly at 5 MHz.  Keep the empirically working rate;
# the mandatory read-back verification prevents a bad image from running.
JTAG_SPEED_KHZ="${JTAG_SPEED_KHZ:-5000}"
GDB_PORT="${GDB_PORT:-3333}"
LOG_DIR="${LOG_DIR:-${ROOT_DIR}/logs/xcvu13p}"
MEM_ACCESS="${XCVU13P_MEM_ACCESS:-progbuf}"
VERIFY_LOAD="${XCVU13P_VERIFY_LOAD:-1}"
INIT_UART="${XCVU13P_INIT_UART:-1}"
GDB_TIMEOUT_SEC="${XCVU13P_GDB_TIMEOUT_SEC:-60}"
export FTDI_SERIAL="${FTDI_SERIAL:-FTBED6DV}"
export FTDI_CHANNEL="${FTDI_CHANNEL:-0}"

# The Debug Module system-bus master is not coherent with Rocket's private
# caches.  Re-loading an ELF through SBA while the hart is merely halted can
# therefore leave old instructions/data visible to the hart.  Require normal
# hart loads/stores through the program buffer unless explicitly overridden.
for method in ${MEM_ACCESS}; do
  case "${method}" in
    progbuf|sysbus|abstract) ;;
    *)
      echo "ERROR: invalid XCVU13P_MEM_ACCESS method: ${method}" >&2
      echo "Allowed methods: progbuf sysbus abstract" >&2
      exit 1
      ;;
  esac
done

case "${VERIFY_LOAD}" in
  0|1) ;;
  *)
    echo "ERROR: XCVU13P_VERIFY_LOAD must be 0 or 1." >&2
    exit 1
    ;;
esac

case "${INIT_UART}" in
  0|1) ;;
  *)
    echo "ERROR: XCVU13P_INIT_UART must be 0 or 1." >&2
    exit 1
    ;;
esac

if [[ ! "${GDB_TIMEOUT_SEC}" =~ ^[1-9][0-9]*$ ]]; then
  echo "ERROR: XCVU13P_GDB_TIMEOUT_SEC must be a positive integer." >&2
  exit 1
fi

if [[ ! -x "${OPENOCD}" ]]; then
  echo "ERROR: openocd not found or not executable: ${OPENOCD}" >&2
  exit 1
fi

if [[ ! -x "${GDB}" ]]; then
  echo "ERROR: riscv64-unknown-elf-gdb not found or not executable: ${GDB}" >&2
  exit 1
fi

if [[ $# -ge 2 ]]; then
  ENTRY="$2"
else
  if [[ ! -x "${READELF}" ]]; then
    echo "ERROR: readelf not found or not executable: ${READELF}" >&2
    echo "Pass entry address explicitly, for example: $0 ${ELF} 0x80000000" >&2
    exit 1
  fi
  ENTRY="$("${READELF}" -h "${ELF}" | awk '/Entry point address:/ {print $4}')"
fi

if [[ -z "${ENTRY}" || "${ENTRY}" == "0x0" ]]; then
  echo "ERROR: could not determine a useful ELF entry address." >&2
  echo "Pass it explicitly, for example: $0 ${ELF} 0x80000000" >&2
  exit 1
fi

mkdir -p "${LOG_DIR}"
RUN_TAG="$(date +%Y%m%d-%H%M%S)"
OPENOCD_LOG="${LOG_DIR}/openocd-load-${RUN_TAG}.log"
GDB_LOG="${LOG_DIR}/gdb-load-${RUN_TAG}.log"
GDB_CMDS="$(mktemp)"

cleanup() {
  local status=$?
  [[ -n "${OPENOCD_PID:-}" ]] && kill "${OPENOCD_PID}" >/dev/null 2>&1 || true
  rm -f "${GDB_CMDS}"
  exit "${status}"
}
trap cleanup EXIT INT TERM

cd "${ROOT_DIR}"

"${OPENOCD}" \
  -s "${ROOT_DIR}" \
  -f "${OPENOCD_CFG}" \
  -c "adapter speed ${JTAG_SPEED_KHZ}" \
  -c "riscv set_mem_access ${MEM_ACCESS}" \
  -c "gdb_port ${GDB_PORT}" \
  -c "init" \
  -c "halt" \
  >"${OPENOCD_LOG}" 2>&1 &
OPENOCD_PID=$!

for _ in $(seq 1 100); do
  if (echo >"/dev/tcp/127.0.0.1/${GDB_PORT}") >/dev/null 2>&1; then
    break
  fi
  if ! kill -0 "${OPENOCD_PID}" >/dev/null 2>&1; then
    echo "ERROR: OpenOCD exited early. Log: ${OPENOCD_LOG}" >&2
    exit 1
  fi
  sleep 0.1
done

if ! (echo >"/dev/tcp/127.0.0.1/${GDB_PORT}") >/dev/null 2>&1; then
  echo "ERROR: timed out waiting for OpenOCD GDB port ${GDB_PORT}. Log: ${OPENOCD_LOG}" >&2
  exit 1
fi

if [[ "${INIT_UART}" == "1" ]]; then
  GDB_UART_CMDS=$'set {unsigned int}0x10020018 = 434\nset {unsigned int}0x10020008 = 1\nset {unsigned int}0x1002000c = 1'
else
  GDB_UART_CMDS="# UART initialization disabled"
fi

echo "Using OpenOCD : ${OPENOCD}"
echo "Using GDB     : ${GDB}"
echo "ELF           : ${ELF}"
echo "Entry         : ${ENTRY}"
echo "FTDI serial   : ${FTDI_SERIAL}"
echo "FTDI channel  : ${FTDI_CHANNEL}"
echo "JTAG speed    : ${JTAG_SPEED_KHZ} kHz"
echo "Memory access : ${MEM_ACCESS}"
echo "Verify load   : ${VERIFY_LOAD}"
echo "Initialize UART: ${INIT_UART}"
echo "GDB timeout   : ${GDB_TIMEOUT_SEC} s"
echo "OpenOCD log   : ${OPENOCD_LOG}"
echo "GDB log       : ${GDB_LOG}"
echo

if [[ "${VERIFY_LOAD}" == "1" ]]; then
  GDB_VERIFY_CMD="compare-sections"
else
  GDB_VERIFY_CMD="# ELF read-back verification disabled"
fi

cat >"${GDB_CMDS}" <<EOF
set confirm off
set pagination off
set remotetimeout 120
file ${ELF}
target extended-remote 127.0.0.1:${GDB_PORT}
monitor halt
# Write and verify the ELF through normal hart accesses.  SBA/sysbus is not
# coherent with Rocket's private D-cache and can report stale DDR contents even
# when the hart-visible image is correct.
monitor riscv set_mem_access progbuf
monitor riscv exec_progbuf 0x0330000f 0x0000100f
load
monitor riscv exec_progbuf 0x0330000f 0x0000100f
${GDB_VERIFY_CMD}
# Keep the hart halted. Resume occurs in a separate GDB session only after the
# shell has parsed the compare-sections output and checked OpenOCD liveness.
disconnect
quit
EOF

echo "Loading and verifying ELF at ${JTAG_SPEED_KHZ} kHz"
set +e
GDB_OUTPUT="$(timeout --foreground "${GDB_TIMEOUT_SEC}" "${GDB}" -q -x "${GDB_CMDS}" 2>&1)"
GDB_STATUS=$?
set -e
printf '%s\n' "${GDB_OUTPUT}" | tee -a "${GDB_LOG}"

if (( GDB_STATUS == 124 )); then
  echo "ERROR: GDB timed out after ${GDB_TIMEOUT_SEC} seconds; hart was not resumed." >&2
  echo "Reprogram the FPGA before the next load attempt." >&2
  exit 1
elif (( GDB_STATUS != 0 )); then
  echo "ERROR: GDB load failed with status ${GDB_STATUS}; hart was not resumed." >&2
  exit 1
elif [[ "${VERIFY_LOAD}" == "1" ]] && \
     { [[ "${GDB_OUTPUT}" == *"MIS-MATCHED"* ]] || \
       [[ "${GDB_OUTPUT}" == *"does not match the loaded file"* ]]; }; then
  echo "ERROR: ELF verification failed; hart was not resumed." >&2
  echo "Reprogram the FPGA before the next load attempt." >&2
  echo "Inspect: ${GDB_LOG}" >&2
  exit 1
elif ! kill -0 "${OPENOCD_PID}" >/dev/null 2>&1; then
  echo "ERROR: OpenOCD exited during load/verification; hart was not resumed." >&2
  echo "Reprogram the FPGA before the next load attempt." >&2
  exit 1
fi

echo "ELF load verified." | tee -a "${GDB_LOG}"

cat >"${GDB_CMDS}" <<EOF
set confirm off
set pagination off
set remotetimeout 120
file ${ELF}
target extended-remote 127.0.0.1:${GDB_PORT}
monitor halt
# Synchronize the verified image with instruction fetch immediately before run.
monitor riscv set_mem_access progbuf
monitor riscv exec_progbuf 0x0330000f 0x0000100f
# The benchmark runtime does not clear its entire .bss.  Reprogramming the FPGA
# resets the UART peripheral but can leave its software "initialized" flag set.
${GDB_UART_CMDS}
set \$pc = ${ENTRY}
monitor resume
disconnect
quit
EOF

set +e
GDB_OUTPUT="$(timeout --foreground "${GDB_TIMEOUT_SEC}" "${GDB}" -q -x "${GDB_CMDS}" 2>&1)"
GDB_STATUS=$?
set -e
printf '%s\n' "${GDB_OUTPUT}" | tee -a "${GDB_LOG}"
if (( GDB_STATUS == 124 )); then
  echo "ERROR: GDB timed out while resuming the verified ELF." >&2
  echo "Inspect: ${GDB_LOG}" >&2
  exit 1
elif (( GDB_STATUS != 0 )); then
  echo "ERROR: verified ELF was not resumed; GDB status ${GDB_STATUS}." >&2
  echo "Inspect: ${GDB_LOG}" >&2
  exit 1
fi

echo
echo "ELF verified and core resumed. Watch UART for program output."
