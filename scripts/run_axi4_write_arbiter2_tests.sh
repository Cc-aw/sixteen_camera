#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
test_tmp=$(mktemp -d /tmp/sixteen-camera-write-arbiter.XXXXXX)
trap 'rm -rf "$test_tmp"' EXIT
verilator --binary --timing -Wno-fatal \
    --top-module tb_axi4_write_arbiter2 --Mdir "$test_tmp/obj" \
    "$root/rtl/interfaces/axi4_if.sv" \
    "$root/rtl/rtl_old/yolov5nu_tensor_frame_writer.sv" \
    "$root/rtl/rtl_old/axi4_write_arbiter2.sv" \
    "$root/sim/tb_axi4_write_arbiter2.sv" >"$test_tmp/build.log"
"$test_tmp/obj/Vtb_axi4_write_arbiter2"
"$test_tmp/obj/Vtb_axi4_write_arbiter2" +late_s0
