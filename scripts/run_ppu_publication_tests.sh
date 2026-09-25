#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
test_tmp="${PPU_TEST_CACHE:-$root/build/ppu_phase2/cache}/publication"
mkdir -p "$test_tmp"
for bytes in 128 0; do
  verilator --binary --build-jobs "${VERILATOR_JOBS:-8}" --timing -Wno-fatal \
    --Mdir "$test_tmp/manager_$bytes" --top-module tb_head_publication_manager -GTEST_HEAD_BYTES="$bytes" \
    "$root/rtl/interfaces/axi4_if.sv" \
    "$root/rtl/ai/postprocess/head_publication_manager.sv" \
    "$root/rtl/ai/postprocess/ppu_cache_publish_engine.sv" \
    "$root/sim/tb_head_publication_manager.sv"
  "$test_tmp/manager_$bytes/Vtb_head_publication_manager"
done
iverilog -g2012 -s tb_ppu_publication_gate -o "$test_tmp/gate" \
  "$root/rtl/ai/postprocess/ppu_publication_gate.sv" \
  "$root/sim/tb_ppu_publication_gate.sv"
vvp "$test_tmp/gate"
verilator --binary --build-jobs "${VERILATOR_JOBS:-8}" --timing -Wno-fatal \
  --Mdir "$test_tmp/write_mux" --top-module tb_ppu_publication_write_mux \
  "$root/rtl/interfaces/axi4_if.sv" \
  "$root/rtl/ai/postprocess/ppu_cache_publish_engine.sv" \
  "$root/rtl/ai/postprocess/ppu_publication_write_mux.sv" \
  "$root/sim/tb_ppu_publication_write_mux.sv"
"$test_tmp/write_mux/Vtb_ppu_publication_write_mux"
python3 "$root/scripts/run_ppu_cache_control_test.py"
for test_case in 0 1 2 3; do
abort_case=$((test_case == 1)); queued_case=$((test_case == 2)); multi_case=$((test_case == 3))
verilator --binary --build-jobs "${VERILATOR_JOBS:-8}" --timing -Wno-fatal \
  -GABORT_CASE="$abort_case" -GQUEUED_CASE="$queued_case" -GMULTI_CASE="$multi_case" --Mdir "$test_tmp/integration_$test_case" --top-module tb_ppu_publication_integration \
  "$root/rtl/interfaces/axi4_if.sv" "$root/rtl/interfaces/axi_lite_if.sv" \
  "$root/rtl/bus/axi4_channel_join.sv" "$root"/rtl/ai/postprocess/*.sv \
  "$root/rtl/memory/postprocess_memory_bridge.sv" \
  "$root/sim/tb_ppu_publication_integration.sv"
"$test_tmp/integration_$test_case/Vtb_ppu_publication_integration"
done
echo "PPU_PUBLICATION_TESTS=PASS"
