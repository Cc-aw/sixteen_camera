#!/usr/bin/env bash
# Run after run_gemmini.sh builds the current, unmodified generated RTL.
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
cd "$root"
for condition in '8 0' '100 13'; do
  read -r delay stall <<< "$condition"
  commands="build/sim_loopconv/commands_rtl480_first_${delay}_${stall}.txt"
  cp build/sim_loopconv/commands_gemmini_480.txt "$commands"
  log="build/sim_loopconv/rtl_first_${delay}_${stall}.log"
  build/sim_loopconv/obj_gemmini/VGemminiTest "$commands" "$delay" "$stall" 1 +trace_internal > "$log" 2>&1
  python3 scripts/sim_loopconv/analyze_scratchpad.py "$log"
  python3 scripts/sim_loopconv/analyze_mesh_steps.py "$log"
  python3 scripts/sim_loopconv/analyze_accumulator.py "$log"
  tail -4 "$log"
done
