#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
cd "$root"
python3 scripts/test/sim_loopconv/prepare_gemmini.py
verilator --cc --exe --build -j 4 --no-timing -Wno-fatal --output-split 10000 \
 --top-module GemminiTest --Mdir build/sim/loopconv/obj_gemmini \
 -f build/sim/loopconv/rtl_gemmini.f build/sim/loopconv/GemminiTest.sv \
 "$root/scripts/test/sim_loopconv/main_gemmini.cpp" > build/sim/loopconv/build_gemmini.log 2>&1
for h in 16 480; do
 log="build/sim/loopconv/${h}_gemmini.log"
 build/sim/loopconv/obj_gemmini/VGemminiTest "build/sim/loopconv/commands_gemmini_$h.txt" 8 0 > "$log" 2>&1
 tail -1 "$log"
done
