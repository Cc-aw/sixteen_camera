#ifndef AI_FRAME_SNAPSHOT_H
#define AI_FRAME_SNAPSHOT_H

#include <stdint.h>

#include "platform.h"

typedef struct {
    uint32_t stream_id;
    uint32_t frame_addr;
    uint64_t frame_id;
    uint32_t source_frame_id;
    uint64_t timestamp;
    uint32_t version;
} AiFrameMetadata;

typedef struct {
    uint64_t batch_id;
    uint16_t valid_mask;
    uint16_t fresh_mask;
    AiFrameMetadata members[VIDEO_CHANNEL_COUNT];
} AiFrameSnapshot;

int ai_frame_snapshot_acquire(AiFrameSnapshot *snapshot);
int ai_frame_snapshot_release(uint16_t release_mask);
uint16_t ai_frame_snapshot_available_mask(void);

#endif
