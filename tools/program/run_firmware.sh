#!/usr/bin/env bash
set -Eeuo pipefail
repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
if [[ -n "${VIDEO_VARIANT:-}" && "$VIDEO_VARIANT" != dma_load_streaming_asram_s1_512kib_2bank ]]; then
    echo "Only the selected S1 video firmware is supported" >&2; exit 2
fi
if [[ -n "${ELF_FILE:-}" && "$(realpath -m -- "$ELF_FILE")" != "$repo/sw/video_runtime/dma_load_streaming_asram_s1_512kib_2bank/build/s1_video_runtime.elf" ]]; then
    echo "ELF_FILE does not match the selected S1 firmware" >&2; exit 2
fi
action=program
for arg in "$@"; do
    case "$arg" in
        --check) action=preflight ;;
        --no-build) ;;
        --build) make -C "$repo" firmware ;;
        -h|--help) make -C "$repo" help; exit 0 ;;
        *) echo "Unknown argument: $arg" >&2; exit 2 ;;
    esac
done
exec make -C "$repo" "$action" "RUN=${RUN:-s1_01}"
