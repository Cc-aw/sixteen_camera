#!/usr/bin/env bash
set -Eeuo pipefail
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
project=$(cd -- "$here/../../.." && pwd)
loader_args=(--no-build)
build=0
workload=first
for arg in "$@"; do
    case "$arg" in
        --build) build=1 ;;
        --check) loader_args+=(--check) ;;
        --first) workload=first ;;
        --model) workload=model ;;
        --no-build) ;;
        -h|--help) echo 'Usage: DMA_CONTEXT=<candidate context> download-dma-load.sh [--first|--model] [--build] [--check]'; exit 0 ;;
        *) echo "Unknown argument: $arg" >&2; exit 2 ;;
    esac
done
: "${DMA_CONTEXT:?Set DMA_CONTEXT to the private 512KiB/two-bank GENERATION_CONTEXT.json}"
if ((build)); then make -C "$project" benchmark-dma-load DMA_CONTEXT="$DMA_CONTEXT"; fi
make -C "$project" audit-dma-load DMA_CONTEXT="$DMA_CONTEXT"
export ELF_FILE="$project/build/firmware/dma-load-2bank/yolov5_dma_load_${workload}.elf"
exec bash "$project/tools/program/run_firmware.sh" "${loader_args[@]}"
