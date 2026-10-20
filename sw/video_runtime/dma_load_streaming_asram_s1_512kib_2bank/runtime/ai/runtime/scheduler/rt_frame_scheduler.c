#include "ai/runtime/scheduler/rt_frame_scheduler.h"

uint32_t rt_frame_candidate_slot(uint32_t ready, uint32_t held,
                                 uint32_t busy_streams, uint32_t stream)
{
    if (stream >= VIDEO_CHANNEL_COUNT || (busy_streams & (UINT32_C(1) << stream)))
        return AI_TENSOR_SLOT_INVALID;
    uint32_t slot = AI_TENSOR_SLOT_INVALID;
    uint32_t eligible = ready & ~held;
    if (eligible & (UINT32_C(1) << stream))
        slot = stream;
    /* Preserve the R2 fallback if both slots remain after stale service. */
    if (eligible & (UINT32_C(1) << (stream + VIDEO_CHANNEL_COUNT)))
        slot = stream + VIDEO_CHANNEL_COUNT;
    return slot;
}

int rt_frame_select(const AiRtFrameSnapshot *snapshot, AiRtFrameCandidate *selected)
{
    if (!snapshot || !selected)
        return 0;
    int found = 0;
    for (uint32_t stream = 0; stream < VIDEO_CHANNEL_COUNT; ++stream) {
        if (!(snapshot->valid & (UINT32_C(1) << stream)))
            continue;
        const AiRtFrameCandidate *candidate = &snapshot->candidates[stream];
        if (candidate->last_frame_valid &&
            candidate->metadata.version <= candidate->last_version)
            continue;
        if (!found || candidate->deadline < selected->deadline ||
            (candidate->deadline == selected->deadline &&
             candidate->metadata.frame_id > selected->metadata.frame_id)) {
            *selected = *candidate;
            found = 1;
        }
    }
    return found;
}
