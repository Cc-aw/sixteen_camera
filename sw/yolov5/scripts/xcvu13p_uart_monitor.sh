#!/usr/bin/env bash

set -euo pipefail

UART_DEV="${UART_DEV:-${1:-}}"
BAUD="${BAUD:-115200}"
TIMEOUT_SEC="${TIMEOUT_SEC:-0}"

if [[ -z "${UART_DEV}" ]]; then
  echo "Usage: UART_DEV=/dev/ttyUSBx $0" >&2
  echo "   or: $0 /dev/ttyUSBx" >&2
  exit 1
fi

if [[ ! -e "${UART_DEV}" ]]; then
  echo "ERROR: UART device does not exist: ${UART_DEV}" >&2
  exit 1
fi

stty -F "${UART_DEV}" "${BAUD}" cs8 -cstopb -parenb -ixon -ixoff -crtscts raw -echo

echo "Monitoring ${UART_DEV} at ${BAUD} baud. Press Ctrl-C to stop."
echo

if [[ "${TIMEOUT_SEC}" == "0" ]]; then
  cat "${UART_DEV}"
else
  timeout "${TIMEOUT_SEC}" cat "${UART_DEV}"
fi
