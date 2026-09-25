#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
test_tmp="${PPU_TEST_CACHE:-$root/build/ppu_phase2/cache}/video"
mkdir -p "$test_tmp"
for top in tb_video_control_bridge tb_video_csr_partition; do
 verilator --binary --build-jobs "${VERILATOR_JOBS:-8}" --timing -Wno-fatal --top-module "$top" --Mdir "$test_tmp/$top" \
 "$root/rtl/interfaces/axi_lite_if.sv" "$root/rtl/common/cdc/cdc_mailbox.sv" \
 "$root/rtl/control/csr/video_csr.sv" "$root/rtl/control/csr/frame_csr.sv" \
 "$root/rtl/control/csr/tensor_csr.sv" "$root/rtl/control/csr/overlay_csr.sv" \
 "$root/rtl/control/csr/telemetry_csr.sv" "$root/rtl/control/telemetry/tensor_telemetry_cdc.sv" \
 "$root/rtl/video/framebuffer/multi_channel_framebuffer_ctrl.sv" \
 "$root/rtl/video/video_control_bridge.sv" "$root/sim/$top.sv"
 "$test_tmp/$top/V$top"
done
echo PPU_VIDEO_INTEGRATION=PASS
