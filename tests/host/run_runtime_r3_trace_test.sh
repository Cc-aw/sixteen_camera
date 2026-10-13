#!/usr/bin/env bash
set -euo pipefail
project_root=$(cd "$(dirname "$0")/../.." && pwd)
source "$project_root/tests/host/runtime_module_sources.sh"
test_tmp=$(mktemp -d /tmp/sixteen-camera-runtime-r3.XXXXXX)
trap 'rm -rf "$test_tmp"' EXIT
flags=(-std=c11 -Wall -Wextra -Werror -DAI_STREAM_RUNTIME_HOST_TEST
  -I"$project_root/tests/host/include" -I"$project_root/sw/src")
shared=("$project_root/sw/src/drivers/tensor/ai_tensor_device.c"
  "$project_root/sw/src/ai/runtime/resources/rt_job.c"
  "$project_root/sw/src/ai/runtime/resources/rt_tensor_manager.c"
  "$project_root/sw/src/ai/postprocess/ai_result_manager.c")
for workers in 1 2 3; do
  for mode in reference current; do
    extras=(); check=()
    if [[ "$mode" == reference ]]; then
      cp "$project_root/tests/data/runtime/r2/stream-runtime-reference.c.inc" "$test_tmp/runtime.c"
    else
      cp "$project_root/sw/src/ai/runtime/ai_batch_runtime_stream.c" "$test_tmp/runtime.c"
      extras=("${runtime_module_sources[@]}"); check=(-DAI_RUNTIME_STATE_TEST=1)
    fi
    cc "${flags[@]}" -DAI_MODEL_WORKER_COUNT=${workers}U "$test_tmp/runtime.c" "${extras[@]}" \
      "${shared[@]}" "$project_root/tests/host/test_runtime_scheduler_trace.c" -o "$test_tmp/$mode-healthy"
    cc "${flags[@]}" "${check[@]}" -DAI_RUNTIME_OWNERSHIP_TRACE=1 -DAI_MODEL_WORKER_COUNT=${workers}U \
      "$test_tmp/runtime.c" "${extras[@]}" "${shared[@]}" \
      "$project_root/tests/host/test_runtime_fault_ownership.c" -o "$test_tmp/$mode-fault"
    for scenario in pipeline backpressure metadata-failure multi-double writing-drain; do
      "$test_tmp/$mode-healthy" "$scenario" > "$test_tmp/$mode-$scenario.trace"
    done
    for scenario in error-only error-enable release-retry late-ack release-pending reused-after-timeout error-zero timeout bad-compute uncertain-submit; do
      "$test_tmp/$mode-fault" "$scenario" > "$test_tmp/$mode-$scenario.trace"
    done
    # Full legacy regression, including bad result identity and UART profiles.
    if [[ "$workers" != 1 ]]; then
      cc "${flags[@]}" -DAI_MODEL_WORKER_COUNT=${workers}U "$test_tmp/runtime.c" "${extras[@]}" \
        "${shared[@]}" "$project_root/tests/host/test_runtime_tensor_hal_trace.c" -o "$test_tmp/$mode-full"
      "$test_tmp/$mode-full" > "$test_tmp/$mode-full.trace"
    fi
  done
  scenarios=(pipeline backpressure metadata-failure multi-double writing-drain error-only error-enable release-retry late-ack
    release-pending reused-after-timeout error-zero timeout bad-compute uncertain-submit)
  [[ "$workers" == 1 ]] || scenarios+=(full)
  for scenario in "${scenarios[@]}"; do
    diff -u "$test_tmp/reference-$scenario.trace" "$test_tmp/current-$scenario.trace"
    echo "R3_RUNTIME_TRACE=PASS workers=$workers scenario=$scenario events=$(wc -l < "$test_tmp/current-$scenario.trace") full_MMIO_fences_cycles_dispatch_compute_release_result_drain_UART=identical"
  done
done
