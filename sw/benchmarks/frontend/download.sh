#!/usr/bin/env bash
set -Eeuo pipefail
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
project=$(cd -- "$here/../../.." && pwd)
diagnostic=0
build=0
check=0
while (($#)); do
    case $1 in
        --diagnostic) diagnostic=1 ;;
        --build) build=1 ;;
        --no-build) build=0 ;;
        --check) check=1 ;;
        -h|--help) echo 'Usage: download.sh [--diagnostic] [--build|--no-build] [--check]'; exit 0 ;;
        *) echo "Unknown option: $1" >&2; exit 2 ;;
    esac
    shift
done
python3 "$project/tools/check/check_current_product.py" --benchmark
if ((build)); then make -C "$here" -j"${JOBS:-4}" all; fi
out=${FRONTEND_BUILD:-$project/build/firmware/frontend}
if ((diagnostic)); then
    export ELF_FILE="$out/yolov5_frontend_diag_12.elf"
    python3 -B "$here/scripts/check_elf.py" "$ELF_FILE" --three-way --diagnostic
else
    export ELF_FILE="$out/yolov5_three_way_12.elf"
    python3 -B "$here/scripts/check_elf.py" "$ELF_FILE" --three-way
fi
python3 -B "$here/scripts/manifest.py" --check
loader_args=(--no-build)
if ((check)); then loader_args+=(--check); fi
exec bash "$project/tools/program/run_firmware.sh" "${loader_args[@]}"
