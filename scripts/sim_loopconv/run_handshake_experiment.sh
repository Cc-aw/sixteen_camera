#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
cd "$root"
python3 scripts/sim_loopconv/prepare_handshake_experiment.py
verilator --cc --exe --build -j 4 --no-timing -Wno-fatal --output-split 10000 \
 --top-module GemminiTest --Mdir build/sim_loopconv/obj_handshake \
 -f build/sim_loopconv/rtl_handshake.f build/sim_loopconv/GemminiTest.sv \
 "$root/scripts/sim_loopconv/main_gemmini.cpp" > build/sim_loopconv/build_handshake.log 2>&1
sim=build/sim_loopconv/obj_handshake/VGemminiTest
for condition in '8 0' '100 13'; do
 read -r delay stall <<< "$condition"
 log="build/sim_loopconv/handshake_first_${delay}_${stall}.log"
 "$sim" build/sim_loopconv/commands_gemmini_480.txt "$delay" "$stall" 1 +trace_internal > "$log" 2>&1
 python3 scripts/sim_loopconv/analyze_scratchpad.py "$log"
 python3 scripts/sim_loopconv/analyze_mesh_steps.py "$log"
 python3 scripts/sim_loopconv/analyze_accumulator.py "$log"
 tail -3 "$log"
done
for h in 16 480; do
 log="build/sim_loopconv/handshake_${h}.log"
 "$sim" "build/sim_loopconv/commands_gemmini_${h}.txt" 8 0 > "$log" 2>&1
 tail -3 "$log"
done
