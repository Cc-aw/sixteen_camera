#ifndef RT_FRAME_SCHEDULER_H
#define RT_FRAME_SCHEDULER_H

#include "ai/runtime/ai_tensor_slot_pool.h"

typedef struct {
    uint32_t slot, stream;
    AiTensorSlot metadata;
    uint64_t deadline;
    uint32_t last_version, last_frame_valid;
} AiRtFrameCandidate;

typedef struct {
    uint32_t valid;
    AiRtFrameCandidate candidates[VIDEO_CHANNEL_COUNT];
} AiRtFrameSnapshot;

/* Pure policy: no device, backend or cycle access. Sampling and ownership
 * transactions are the dispatcher's responsibility. */
uint32_t rt_frame_candidate_slot(uint32_t ready, uint32_t held,
                                 uint32_t busy_streams, uint32_t stream);
int rt_frame_select(const AiRtFrameSnapshot *snapshot, AiRtFrameCandidate *selected);

#endif
