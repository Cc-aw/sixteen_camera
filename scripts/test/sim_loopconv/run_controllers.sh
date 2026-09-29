#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
cd "$root"
python3 scripts/test/sim_loopconv/prepare_controllers.py
verilator --cc --exe --build -j 4 -Wno-fatal --output-split 10000 \
 --top-module LoopConvControllersTest --Mdir build/sim/loopconv/obj_controllers \
 -f build/sim/loopconv/rtl_controllers.f build/sim/loopconv/LoopConvControllersTest.sv \
 "$root/scripts/test/sim_loopconv/main_controllers.cpp" > build/sim/loopconv/build_controllers.log 2>&1
for h in 16 480; do
 log="build/sim/loopconv/${h}_controllers.log"
 build/sim/loopconv/obj_controllers/VLoopConvControllersTest "build/sim/loopconv/commands_$h.txt" 8 0 > "$log" 2>&1
 tail -1 "$log"
done
