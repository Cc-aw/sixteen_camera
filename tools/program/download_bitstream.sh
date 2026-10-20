#!/usr/bin/env bash
set -Eeuo pipefail
repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
action=program-bitstream
for arg in "$@"; do
    case "$arg" in
        --check) action=preflight ;;
        -h|--help) make -C "$repo" help; exit 0 ;;
        *) echo "Use the selected S1 artifact via make program-bitstream; unsupported argument: $arg" >&2; exit 2 ;;
    esac
done
exec make -C "$repo" "$action" "RUN=${RUN:-s1_bit_01}"
