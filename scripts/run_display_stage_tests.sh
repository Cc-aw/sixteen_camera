#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_tmp="$(mktemp -d /tmp/display-stage-tests.XXXXXX)"
trap 'rm -rf -- "$test_tmp"' EXIT
cd "$repo_dir"

verilator --binary --timing -Wno-fatal --top-module tb_display_scaler \
    --Mdir "$test_tmp/scaler" \
    rtl/interfaces/video_stream_if.sv \
    rtl/video/display/rgb888_to_rgb565.sv \
    rtl/video/display/display_scaler.sv \
    sim/tb_display_scaler.sv > "$test_tmp/build.log" 2>&1
"$test_tmp/scaler/Vtb_display_scaler"

verilator --binary --timing -Wno-fatal --top-module tb_display_frame_dma \
    --Mdir "$test_tmp/frame_dma" \
    rtl/interfaces/video_stream_if.sv rtl/interfaces/axi4_if.sv \
    rtl/video/display/display_frame_packer.sv \
    rtl/video/framebuffer/channel_write_fifo.sv \
    rtl/video/framebuffer/multi_channel_video_dma.sv \
    sim/tb_display_frame_dma.sv > "$test_tmp/frame_dma_build.log" 2>&1
"$test_tmp/frame_dma/Vtb_display_frame_dma"

verilator --binary --timing -Wno-fatal --top-module tb_mosaic_rgb565_reader \
    --Mdir "$test_tmp/mosaic" \
    rtl/interfaces/axi4_if.sv rtl/interfaces/axis_video_if.sv \
    rtl/video/display/rgb565_to_rgb888.sv \
    rtl/video/display/mosaic_rgb565_reader.sv \
    sim/tb_mosaic_rgb565_reader.sv > "$test_tmp/mosaic_build.log" 2>&1
"$test_tmp/mosaic/Vtb_mosaic_rgb565_reader"

verilator --binary --timing -Wno-fatal --top-module tb_mosaic_rgb565_reader \
    -GSTALL_TEST=1 --Mdir "$test_tmp/mosaic_stall" \
    rtl/interfaces/axi4_if.sv rtl/interfaces/axis_video_if.sv \
    rtl/video/display/rgb565_to_rgb888.sv \
    rtl/video/display/mosaic_rgb565_reader.sv \
    sim/tb_mosaic_rgb565_reader.sv > "$test_tmp/mosaic_stall_build.log" 2>&1
"$test_tmp/mosaic_stall/Vtb_mosaic_rgb565_reader"

verilator --binary --timing -Wno-fatal --top-module tb_full_rgb565_reader \
    --Mdir "$test_tmp/full" \
    rtl/interfaces/axi4_if.sv rtl/interfaces/axis_video_if.sv \
    rtl/video/display/rgb565_to_rgb888.sv \
    rtl/video/display/full_rgb565_reader.sv \
    sim/tb_full_rgb565_reader.sv > "$test_tmp/full_build.log" 2>&1
"$test_tmp/full/Vtb_full_rgb565_reader"

iverilog -g2012 -Ptb_multi_channel_frame_manager_writer_handshake.COMPACT=1 \
    -s tb_multi_channel_frame_manager_writer_handshake \
    -o "$test_tmp/compact_manager.vvp" \
    rtl/video/framebuffer/multi_channel_frame_manager.sv \
    sim/tb_multi_channel_frame_manager_writer_handshake.sv
vvp "$test_tmp/compact_manager.vvp"

verilator --binary --timing -Wno-fatal --top-module tb_display_reader_compact \
    --Mdir "$test_tmp/reader_integration" \
    rtl/interfaces/axi4_if.sv rtl/interfaces/axis_video_if.sv \
    rtl/video/display/rgb565_to_rgb888.sv \
    rtl/video/display/full_rgb565_reader.sv \
    rtl/video/display/mosaic_rgb565_reader.sv \
    rtl/video/overlay/detection_overlay.sv \
    rtl/video/framebuffer/display_reader_subsystem.sv \
    sim/tb_display_reader_compact.sv > "$test_tmp/reader_integration_build.log" 2>&1
"$test_tmp/reader_integration/Vtb_display_reader_compact"

iverilog -g2012 -s tb_detection_overlay -o "$test_tmp/overlay.vvp" \
    rtl/video/overlay/detection_overlay.sv \
    sim/tb_detection_overlay.sv
vvp "$test_tmp/overlay.vvp"
