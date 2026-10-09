#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
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
    hw/rtl/video/camera/dvp_pclk_recovery.sv \
    hw/rtl/video/camera/dvp_pclk_telemetry.sv \
    tests/rtl/benches/video/tb_dvp_pclk_recovery.sv

run_iverilog tb_dvp_href_line_guard \
    hw/rtl/video/camera/dvp_href_line_guard.sv \
    tests/rtl/benches/video/tb_dvp_href_line_guard.sv

run_verilator tb_camera_telemetry \
    hw/rtl/common/cdc/cdc_mailbox.sv \
    hw/rtl/video/camera/camera_telemetry.sv \
    tests/rtl/benches/video/tb_camera_telemetry.sv

run_verilator tb_camera_axis_cdc_line_boundary \
    hw/rtl/interfaces/axis_video_if.sv \
    hw/rtl/video/camera/camera_axis_cdc.sv \
    tests/rtl/benches/video/tb_camera_axis_cdc_line_boundary.sv

run_verilator tb_camera_axis_cdc_backpressure \
    hw/rtl/interfaces/axis_video_if.sv \
    hw/rtl/video/camera/camera_axis_cdc.sv \
    tests/rtl/benches/video/tb_camera_axis_cdc_backpressure.sv

run_verilator tb_dvp_event_bridge_assembler \
    hw/rtl/video/camera/dvp_event_bridge.sv \
    hw/rtl/video/camera/camera_pixel_assembler.sv \
    tests/rtl/benches/video/tb_dvp_event_bridge_assembler.sv

run_verilator tb_video_stream_cdc \
    hw/rtl/interfaces/video_stream_if.sv \
    hw/rtl/video/camera/video_stream_cdc.sv \
    tests/rtl/benches/video/tb_video_stream_cdc.sv

run_verilator tb_axi4_ui_cdc_mixed \
    hw/rtl/interfaces/axi4_if.sv \
    hw/rtl/bus/cdc_payload_fifo.sv \
    hw/rtl/bus/axi4_ui_write_cdc.sv \
    hw/rtl/bus/axi4_ui_read_cdc.sv \
    tests/rtl/benches/memory/tb_axi4_ui_cdc_mixed.sv

run_verilator tb_multi_channel_video_dma_completion \
    hw/rtl/interfaces/axi4_if.sv \
    hw/rtl/interfaces/video_stream_if.sv \
    hw/rtl/video/framebuffer/channel_write_fifo.sv \
    hw/rtl/video/framebuffer/multi_channel_video_dma.sv \
    tests/rtl/benches/video/tb_multi_channel_video_dma_completion.sv

run_verilator tb_camera_axis_to_stream_recovery \
    hw/rtl/interfaces/axis_video_if.sv \
    hw/rtl/interfaces/video_stream_if.sv \
    hw/rtl/video/camera/camera_axis_to_stream.sv \
    tests/rtl/benches/video/tb_camera_axis_to_stream_recovery.sv

run_verilator tb_video_control_bridge \
    hw/rtl/interfaces/axi_lite_if.sv \
    hw/rtl/common/cdc/cdc_mailbox.sv \
    hw/rtl/control/csr/video_csr.sv \
    hw/rtl/control/csr/frame_csr.sv \
    hw/rtl/control/csr/tensor_csr.sv \
    hw/rtl/control/csr/overlay_csr.sv \
    hw/rtl/control/csr/telemetry_csr.sv \
    hw/rtl/control/telemetry/tensor_telemetry_cdc.sv \
    hw/rtl/video/framebuffer/multi_channel_framebuffer_ctrl.sv \
    hw/rtl/video/video_control_bridge.sv \
    tests/rtl/benches/video/tb_video_control_bridge.sv

run_verilator tb_video_csr_partition \
    hw/rtl/interfaces/axi_lite_if.sv \
    hw/rtl/control/csr/video_csr.sv \
    hw/rtl/control/csr/frame_csr.sv \
    hw/rtl/control/csr/tensor_csr.sv \
    hw/rtl/control/csr/overlay_csr.sv \
    hw/rtl/control/csr/telemetry_csr.sv \
    hw/rtl/video/framebuffer/multi_channel_framebuffer_ctrl.sv \
    tests/rtl/benches/video/tb_video_csr_partition.sv

run_iverilog tb_multi_channel_frame_manager_writer_handshake \
    hw/rtl/video/framebuffer/multi_channel_frame_manager.sv \
    tests/rtl/benches/video/tb_multi_channel_frame_manager_writer_handshake.sv

run_verilator tb_mosaic_frame_reader_16ch \
    hw/rtl/interfaces/axi4_if.sv \
    hw/rtl/interfaces/axis_video_if.sv \
    hw/rtl/video/framebuffer/mosaic_frame_reader.sv \
    tests/rtl/benches/video/tb_mosaic_frame_reader_8ch.sv

echo "VIDEO_REFACTOR_TESTS=PASS"
