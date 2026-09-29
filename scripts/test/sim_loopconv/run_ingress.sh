#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
cd "$root"
python3 scripts/test/sim_loopconv/prepare_ingress.py
verilator --cc --exe --build -j 4 --no-timing -Wno-fatal --output-split 10000 \
 --top-module GemminiIngressTest --Mdir build/sim/loopconv/obj_ingress \
 -f build/sim/loopconv/rtl_ingress.f build/sim/loopconv/GemminiIngressTest.sv \
 "$root/build/sim/loopconv/main_ingress.cpp" > build/sim/loopconv/build_ingress.log 2>&1
for h in 16 480; do
 log="build/sim/loopconv/${h}_ingress.log"
 build/sim/loopconv/obj_ingress/VGemminiIngressTest "build/sim/loopconv/commands_gemmini_$h.txt" 8 0 > "$log" 2>&1
 tail -2 "$log"
done
