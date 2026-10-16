#!/usr/bin/env bash
# Explicit operator entry only; build/test never invokes this script.
set -Eeuo pipefail
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
project=$(cd -- "$here/../../.." && pwd)
loader_args=(--no-build)
build=0
for arg in "$@"; do
    case $arg in
        --build) build=1 ;;
        --check) loader_args+=(--check) ;;
        --no-build) ;;
        -h|--help) echo 'Usage: download-sw-p3.sh [--build] [--check]'; exit 0 ;;
        *) echo "Unknown argument: $arg" >&2; exit 2 ;;
    esac
done
if ((build)); then make -C "$project" benchmark-sw-p3; fi
make -C "$project" audit-sw-p3
case "${SW_P3_MODE:-reference}" in
    reference) output=sw-p3 ;;
    compare) output=sw-p3-compare ;;
    *) echo "SW_P3_MODE must be reference or compare" >&2; exit 2 ;;
esac
export ELF_FILE="$project/build/firmware/$output/yolov5_sw_p3_suite_12.elf"
exec bash "$project/tools/program/run_firmware.sh" "${loader_args[@]}"
