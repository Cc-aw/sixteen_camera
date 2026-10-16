#!/usr/bin/env bash
set -Eeuo pipefail
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
project=$(cd -- "$here/../../.." && pwd)
loader_args=(--no-build)
build=0
for arg in "$@"; do
    case "$arg" in
        --build) build=1 ;;
        --check) loader_args+=(--check) ;;
        --no-build) ;;
        -h|--help) echo 'Usage: download-v34.sh [--build] [--check]'; exit 0 ;;
        *) echo "Unknown argument: $arg" >&2; exit 2 ;;
    esac
done
if ((build)); then make -C "$project" benchmark-v34; fi
make -C "$project" audit-v34
export ELF_FILE="$project/build/firmware/frontend-v34/yolov5_frontend_boundary_diag_12.elf"
exec bash "$project/tools/program/run_firmware.sh" "${loader_args[@]}"
