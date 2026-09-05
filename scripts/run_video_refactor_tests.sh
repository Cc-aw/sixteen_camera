#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_tmp="$(mktemp -d /tmp/sixteen-camera-video-tests.XXXXXX)"
trap 'rm -rf -- "$test_tmp"' EXIT
cd "$repo_dir"

run_iverilog() {
    local top="$1"
    shift
    echo "[IVERILOG] $top"
    iverilog -g2012 -s "$top" -o "$test_tmp/$top.vvp" "$@"
    vvp "$test_tmp/$top.vvp"
}

run_verilator() {
    local top="$1"
    shift
    echo "[VERILATOR] $top"
    verilator --binary --timing -Wno-fatal --top-module "$top" \
        --Mdir "$test_tmp/$top" "$@"
    "$test_tmp/$top/V$top"
}

run_iverilog tb_dvp_pclk_recovery \
    rtl/video/camera/dvp_pclk_recovery.sv \
    sim/tb_dvp_pclk_recovery.sv

run_iverilog tb_dvp_href_line_guard \
    rtl/video/camera/dvp_href_line_guard.sv \
    sim/tb_dvp_href_line_guard.sv

run_verilator tb_camera_axis_cdc_line_boundary \
    rtl/interfaces/axis_video_if.sv \
    sim/xpm_fifo_async_model.sv \
    rtl/video/camera/camera_axis_cdc.sv \
    sim/tb_camera_axis_cdc_line_boundary.sv

run_verilator tb_camera_axis_to_stream_recovery \
    rtl/interfaces/axis_video_if.sv \
    rtl/interfaces/video_stream_if.sv \
    rtl/video/camera/camera_axis_to_stream.sv \
    sim/tb_camera_axis_to_stream_recovery.sv

run_iverilog tb_multi_channel_frame_manager_writer_handshake \
    rtl/video/framebuffer/multi_channel_frame_manager.sv \
    sim/tb_multi_channel_frame_manager_writer_handshake.sv

run_iverilog tb_multi_channel_frame_manager_ai_snapshot \
    rtl/video/framebuffer/multi_channel_frame_manager.sv \
    sim/tb_multi_channel_frame_manager_ai_snapshot.sv

run_verilator tb_mosaic_frame_reader_16ch \
    rtl/interfaces/axi4_if.sv \
    rtl/interfaces/axis_video_if.sv \
    rtl/video/framebuffer/mosaic_frame_reader.sv \
    sim/tb_mosaic_frame_reader_8ch.sv

echo "VIDEO_REFACTOR_TESTS=PASS"
