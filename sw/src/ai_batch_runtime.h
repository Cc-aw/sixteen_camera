#ifndef AI_BATCH_RUNTIME_H
#define AI_BATCH_RUNTIME_H

#include <stdint.h>

#include "ai_frame_snapshot.h"

typedef enum {
    AI_BATCH_FREE = 0,
    AI_BATCH_READY,
    AI_BATCH_RUNNING,
    AI_BATCH_POSTPROCESS,
    AI_BATCH_DONE
} AiBatchState;

typedef struct {
    uint32_t arena;
    uint32_t tensor_base;
    uint64_t batch_id;
    uint16_t valid_mask;
    uint16_t fresh_mask;
    AiFrameMetadata members[VIDEO_CHANNEL_COUNT];
    uint64_t admit_cycle;
    uint64_t preprocess_end_cycle;
    uint64_t compute_start_cycle;
    uint64_t compute_end_cycle;
    uint64_t postprocess_end_cycle;
    uint32_t preprocess_cycles;
    uint32_t preprocess_read_bytes;
    uint32_t preprocess_write_bytes;
    int32_t error;
    AiBatchState state;
} AiBatchContext;

typedef struct {
    uint32_t enabled;
    uint32_t phase;
    uint32_t snapshot_count;
    uint32_t preprocess_count;
    uint32_t consumed_count;
    uint32_t error_count;
    uint32_t release_retry_count;
    uint32_t recycle_error_count;
    int32_t last_error;
    uint64_t last_batch_id;
    uint32_t last_valid_mask;
    uint32_t last_fresh_mask;
    uint32_t last_preprocess_cycles;
} AiBatchRuntimeStatus;

void ai_batch_runtime_init(void);
void ai_batch_runtime_set_enabled(uint32_t enabled);
uint32_t ai_batch_runtime_is_enabled(void);
uint32_t ai_batch_runtime_is_idle(void);
void ai_batch_runtime_poll(void);
void ai_batch_runtime_print_status(void);
void ai_batch_runtime_get_status(AiBatchRuntimeStatus *status);
const AiBatchContext *ai_batch_runtime_context(uint32_t arena);

#endif
