#!/usr/bin/env bash
set -euo pipefail
project_root=$(cd "$(dirname "$0")/../.." && pwd)
test_tmp=$(mktemp -d /tmp/sixteen-camera-application.XXXXXX)
trap 'rm -rf "$test_tmp"' EXIT
mkdir -p "$test_tmp/ai/runtime"
cp "$project_root/tests/data/runtime/r4b/bridge-reference.h.inc" "$test_tmp/ai/runtime/ai_runtime_bridge.h"
cp "$project_root/tests/data/runtime/r4b/main-reference.c.inc" "$test_tmp/reference.c"
scenarios=(commands runtime-bw read-only raw-concurrent write-only tensor-soak enable-rejected
  release-timeout metadata-timeout startup-stale startup-timeout reader-errors idle-gates)
for config in 1:0:0 1:1:0 2:0:0 2:1:0 3:0:0 3:1:0 2:1:1; do
  IFS=: read -r workers stats dedicated <<< "$config"
  live=0; [[ "$workers" != 3 ]] || live=1
  flags=(-std=c11 -O2 -Wall -Wextra -Werror -DAI_MODEL_WORKER_COUNT=${workers}U -DYOLO32_LIVE=$live
    -I"$project_root/tests/host/app_include" -I"$test_tmp" -I"$project_root/sw/src"
    -I"$project_root/sw/third_party/board/include")
  [[ "$stats" == 0 ]] || flags+=(-DTENSOR_INGRESS_STATS=1)
  [[ "$dedicated" == 0 ]] || flags+=(-DFBUS_BANDWIDTH_DIAGNOSTIC=1)
  for mode in reference current; do
    source="$test_tmp/reference.c"; extras=()
    if [[ "$mode" == current ]]; then
      source="$project_root/sw/src/main.c"
      extras=("$project_root/sw/src/board/board_boot.c" "$project_root/sw/src/app/app.c"
        "$project_root/sw/src/app/command.c" "$project_root/sw/src/app/mode_manager.c"
        "$project_root/sw/src/diagnostics/board_bandwidth.c" "$project_root/sw/src/diagnostics/tensor_production.c")
    fi
    cc "${flags[@]}" -Dmain=test_application_entry -c "$source" -o "$test_tmp/main.o"
    cc "${flags[@]}" "$project_root/tests/host/test_application_trace.c" "${extras[@]}" "$test_tmp/main.o" -o "$test_tmp/$mode"
    for scenario in "${scenarios[@]}"; do "$test_tmp/$mode" "$scenario" > "$test_tmp/$mode-$scenario.trace"; done
  done
  for scenario in "${scenarios[@]}"; do
    diff -u "$test_tmp/reference-$scenario.trace" "$test_tmp/current-$scenario.trace"
    echo "R5_APP_TRACE=PASS workers=$workers live=$live ingress_stats=$stats dedicated=$dedicated scenario=$scenario events=$(wc -l < "$test_tmp/current-$scenario.trace") startup_poll_order_MMIO_fences_cycles_UART_API_calls=identical"
  done
done
