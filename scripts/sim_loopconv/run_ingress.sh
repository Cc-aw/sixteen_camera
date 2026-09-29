#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
cd "$root"
python3 scripts/sim_loopconv/prepare_ingress.py
verilator --cc --exe --build -j 4 --no-timing -Wno-fatal --output-split 10000 \
 --top-module GemminiIngressTest --Mdir build/sim_loopconv/obj_ingress \
 -f build/sim_loopconv/rtl_ingress.f build/sim_loopconv/GemminiIngressTest.sv \
 "$root/build/sim_loopconv/main_ingress.cpp" > build/sim_loopconv/build_ingress.log 2>&1
for h in 16 480; do
 log="build/sim_loopconv/${h}_ingress.log"
 build/sim_loopconv/obj_ingress/VGemminiIngressTest "build/sim_loopconv/commands_gemmini_$h.txt" 8 0 > "$log" 2>&1
 tail -2 "$log"
done
