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

run_verilator tb_camera_telemetry \
    rtl/common/cdc/cdc_mailbox.sv \
    rtl/video/camera/camera_telemetry.sv \
    sim/tb_camera_telemetry.sv

run_verilator tb_camera_axis_cdc_line_boundary \
    rtl/interfaces/axis_video_if.sv \
    rtl/video/camera/camera_axis_cdc.sv \
    sim/tb_camera_axis_cdc_line_boundary.sv

run_verilator tb_camera_axis_cdc_backpressure \
    rtl/interfaces/axis_video_if.sv \
    rtl/video/camera/camera_axis_cdc.sv \
    sim/tb_camera_axis_cdc_backpressure.sv

run_verilator tb_dvp_event_bridge_assembler \
    rtl/video/camera/dvp_event_bridge.sv \
    rtl/video/camera/camera_pixel_assembler.sv \
    sim/tb_dvp_event_bridge_assembler.sv

run_verilator tb_video_stream_cdc \
    rtl/interfaces/video_stream_if.sv \
    rtl/video/camera/video_stream_cdc.sv \
    sim/tb_video_stream_cdc.sv

run_verilator tb_axi4_ui_cdc_mixed \
    rtl/interfaces/axi4_if.sv \
    rtl/bus/cdc_payload_fifo.sv \
    rtl/bus/axi4_ui_write_cdc.sv \
    rtl/bus/axi4_ui_read_cdc.sv \
    sim/tb_axi4_ui_cdc_mixed.sv

run_verilator tb_multi_channel_video_dma_completion \
    rtl/interfaces/axi4_if.sv \
    rtl/interfaces/video_stream_if.sv \
    rtl/video/framebuffer/channel_write_fifo.sv \
    rtl/video/framebuffer/multi_channel_video_dma.sv \
    sim/tb_multi_channel_video_dma_completion.sv

run_verilator tb_camera_axis_to_stream_recovery \
    rtl/interfaces/axis_video_if.sv \
    rtl/interfaces/video_stream_if.sv \
    rtl/video/camera/camera_axis_to_stream.sv \
    sim/tb_camera_axis_to_stream_recovery.sv

run_verilator tb_video_control_bridge \
    rtl/interfaces/axi_lite_if.sv \
    rtl/common/cdc/cdc_mailbox.sv \
    rtl/control/csr/video_csr.sv \
    rtl/control/csr/frame_csr.sv \
    rtl/control/csr/tensor_csr.sv \
    rtl/control/csr/overlay_csr.sv \
    rtl/control/csr/telemetry_csr.sv \
    rtl/control/telemetry/tensor_telemetry_cdc.sv \
    rtl/video/framebuffer/multi_channel_framebuffer_ctrl.sv \
    rtl/video/video_control_bridge.sv \
    sim/tb_video_control_bridge.sv

run_verilator tb_video_csr_partition \
    rtl/interfaces/axi_lite_if.sv \
    rtl/control/csr/video_csr.sv \
    rtl/control/csr/frame_csr.sv \
    rtl/control/csr/tensor_csr.sv \
    rtl/control/csr/overlay_csr.sv \
    rtl/control/csr/telemetry_csr.sv \
    rtl/video/framebuffer/multi_channel_framebuffer_ctrl.sv \
    sim/tb_video_csr_partition.sv

run_iverilog tb_multi_channel_frame_manager_writer_handshake \
    rtl/video/framebuffer/multi_channel_frame_manager.sv \
    sim/tb_multi_channel_frame_manager_writer_handshake.sv

run_verilator tb_mosaic_frame_reader_16ch \
    rtl/interfaces/axi4_if.sv \
    rtl/interfaces/axis_video_if.sv \
    rtl/video/framebuffer/mosaic_frame_reader.sv \
    sim/tb_mosaic_frame_reader_8ch.sv

echo "VIDEO_REFACTOR_TESTS=PASS"
