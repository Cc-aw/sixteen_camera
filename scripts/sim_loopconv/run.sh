#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
cd "$root"
python3 scripts/sim_loopconv/prepare.py
for suffix in '' _rs; do
  top=LoopConvTest
  main=main.cpp
  [[ -z "$suffix" ]] || { top=LoopConvRSTest; main=main_rs.cpp; }
  verilator --cc --exe --build -j 4 -Wno-fatal --top-module "$top" \
    --Mdir "build/sim_loopconv/obj$suffix" -f "build/sim_loopconv/rtl$suffix.f" \
    "build/sim_loopconv/$top.sv" "$root/scripts/sim_loopconv/$main" \
    > "build/sim_loopconv/build$suffix.log" 2>&1
  for h in 16 480; do
    for condition in '8 0' '100 13' '1000 31'; do
      read -r delay stall <<< "$condition"
      log="build/sim_loopconv/${h}${suffix}_${delay}_${stall}.log"
      "build/sim_loopconv/obj$suffix/V$top" "build/sim_loopconv/commands_$h.txt" "$delay" "$stall" > "$log" 2>&1
      tail -1 "$log"
    done
  done
done
set +e
build/sim_loopconv/obj_rs/VLoopConvRSTest build/sim_loopconv/commands_480.txt 8 0 drop-load-after-fourth +gemmini_timeout=1000000 > build/sim_loopconv/injected_load_stall.log 2>&1
status=$?
set -e
[[ $status == 2 ]]
grep -q 'TIMEOUT retired=3 submitted=4' build/sim_loopconv/injected_load_stall.log
echo 'INJECTED_LOAD_STALL_DETECTED=PASS (intentional fault, not board root-cause proof)'
