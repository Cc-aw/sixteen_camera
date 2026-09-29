#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
if [[ ${1:-} == --build ]]; then
  bash "$root/scripts/build/build_gemmini_standalone.sh"
  shift
fi
diag=${STANDALONE_INTERNAL_DIAGNOSTICS:-0}
[[ "$diag" == 0 || "$diag" == 1 ]] || { echo "STANDALONE_INTERNAL_DIAGNOSTICS must be 0 or 1" >&2; exit 2; }
no_reuse=${STANDALONE_DISABLE_B_REUSE:-0}
[[ "$no_reuse" == 0 || "$no_reuse" == 1 ]] || { echo 'STANDALONE_DISABLE_B_REUSE must be 0 or 1' >&2; exit 2; }
limit=${STANDALONE_CREDIT_LIMIT:-4}
[[ "$limit" == 1 || "$limit" == 4 ]] || { echo 'STANDALONE_CREDIT_LIMIT must be 1 or 4' >&2; exit 2; }
export ELF_FILE="$root/build/firmware/gemmini_standalone/test.elf"
if [[ "$limit" == 1 ]]; then ELF_FILE="$root/build/firmware/gemmini_standalone_serial/test.elf"; fi
if [[ "$no_reuse" == 1 ]]; then ELF_FILE="${ELF_FILE%/test.elf}_noreuse/test.elf"; fi
if [[ "$diag" == 1 ]]; then ELF_FILE="${ELF_FILE%/test.elf}_diag9/test.elf"; fi
exec bash "$root/sw/run.sh" --no-build "$@"
