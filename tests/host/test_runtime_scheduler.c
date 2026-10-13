#include <assert.h>
#include <stdio.h>
#include <string.h>
#include "ai/runtime/core/rt_state.h"
#include "ai/runtime/scheduler/rt_frame_scheduler.h"

int main(void)
{
    for (uint32_t stream = 0; stream < VIDEO_CHANNEL_COUNT; ++stream) {
        uint32_t lo = UINT32_C(1) << stream;
        uint32_t hi = UINT32_C(1) << (stream + VIDEO_CHANNEL_COUNT);
        assert(rt_frame_candidate_slot(lo, 0, 0, stream) == stream);
        assert(rt_frame_candidate_slot(hi, 0, 0, stream) == stream + VIDEO_CHANNEL_COUNT);
        assert(rt_frame_candidate_slot(lo | hi, 0, 0, stream) == stream + VIDEO_CHANNEL_COUNT);
        assert(rt_frame_candidate_slot(lo | hi, hi, 0, stream) == stream);
        assert(rt_frame_candidate_slot(lo | hi, lo | hi, 0, stream) == AI_TENSOR_SLOT_INVALID);
        assert(rt_frame_candidate_slot(lo | hi, 0, lo, stream) == AI_TENSOR_SLOT_INVALID);
    }
    assert(rt_frame_candidate_slot(UINT32_MAX, 0, 0, 16) == AI_TENSOR_SLOT_INVALID);
    AiRtFrameSnapshot snapshot = {0};
    AiRtFrameCandidate selection;
    memset(&selection, 0x5a, sizeof(selection));
    AiRtFrameCandidate untouched = selection;
    assert(!rt_frame_select(&snapshot, &selection));
    assert(!memcmp(&selection, &untouched, sizeof(selection)));
    snapshot.valid = 15;
    snapshot.candidates[0] = (AiRtFrameCandidate){.slot = 0, .stream = 0,
        .metadata = {.version = 11, .frame_id = 40}, .deadline = 100, .last_version = 10, .last_frame_valid = 1};
    snapshot.candidates[1] = (AiRtFrameCandidate){.slot = 1, .stream = 1,
        .metadata = {.version = 12, .frame_id = 20}, .deadline = 90};
    snapshot.candidates[2] = (AiRtFrameCandidate){.slot = 2, .stream = 2,
        .metadata = {.version = 8, .frame_id = 100}, .deadline = 80, .last_version = 10, .last_frame_valid = 1};
    snapshot.candidates[3] = (AiRtFrameCandidate){.slot = 19, .stream = 3,
        .metadata = {.version = 8, .frame_id = 30}, .deadline = 90};
    assert(rt_frame_select(&snapshot, &selection) && selection.stream == 3);
    snapshot.candidates[3].metadata.frame_id = 20;
    assert(rt_frame_select(&snapshot, &selection) && selection.stream == 1); /* Stable equal tie. */
    snapshot.candidates[0].deadline = 0;
    assert(rt_frame_select(&snapshot, &selection) && selection.stream == 0);
    snapshot.valid = 1;
    snapshot.candidates[0].last_version = UINT32_MAX;
    snapshot.candidates[0].metadata.version = 1;
    assert(!rt_frame_select(&snapshot, &selection)); /* Preserve characterized wrap gap. */

    AiRtControl control = {0};
    assert(rt_control_state(&control) == AI_RT_STATE_STOPPED);
    assert(rt_control_start(&control) == 0 && rt_control_enabled(&control));
    assert(rt_control_start(&control) < 0);
    rt_control_fault(&control);
    assert(rt_control_state(&control) == AI_RT_STATE_FAULTED && rt_control_enabled(&control));
    rt_control_stop(&control);
    assert(!rt_control_enabled(&control) && rt_control_draining(&control));
    rt_control_drained(&control);
    assert(!rt_control_draining(&control) && rt_control_faulted(&control));
    assert(rt_control_start(&control) < 0);
    AiRtControl healthy = {0};
    rt_control_stop(&healthy);
    assert(rt_control_state(&healthy) == AI_RT_STATE_DRAINING);
    rt_control_drained(&healthy);
    assert(rt_control_state(&healthy) == AI_RT_STATE_STOPPED && rt_control_start(&healthy) == 0);
    puts("R3_POLICY_STATE=PASS slots=32 EDF_frame_tie_stale_busy_held phase_fault_latch no_IO_clock_dependencies");
    return 0;
}
