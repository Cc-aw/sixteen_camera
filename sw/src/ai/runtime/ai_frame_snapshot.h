#ifndef AI_FRAME_SNAPSHOT_H
#define AI_FRAME_SNAPSHOT_H

#include <stdint.h>

/* Frame metadata shared by the stream scheduler and public batch status. */
typedef struct {
    uint32_t stream_id;
    uint32_t frame_addr;
    uint64_t frame_id;
    uint32_t source_frame_id;
    uint64_t timestamp;
    uint32_t version;
} AiFrameMetadata;

#endif
