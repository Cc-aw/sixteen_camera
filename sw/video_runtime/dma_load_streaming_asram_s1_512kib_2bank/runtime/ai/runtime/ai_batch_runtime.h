#ifndef AI_BATCH_RUNTIME_H
#define AI_BATCH_RUNTIME_H

#include <stdint.h>
#include "ai/runtime/rt_types.h"

#include "ai/postprocess/ai_detection.h"
#include "ai/runtime/ai_frame_snapshot.h"
#include "platform/platform.h"
#include "ai/runtime/resources/rt_resources.h"

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
    uint16_t dispatched_mask;
    uint16_t completed_mask;
    AiFrameMetadata members[VIDEO_CHANNEL_COUNT];
    uint64_t admit_cycle;
    uint64_t preprocess_end_cycle;
    uint64_t compute_start_cycle;
    uint64_t compute_end_cycle;
    uint64_t postprocess_end_cycle;
    uint32_t preprocess_cycles;
    uint32_t preprocess_read_bytes;
    uint32_t preprocess_write_bytes;
    uint32_t snapshot_released;
    int32_t error;
    AiBatchState state;
} AiBatchContext;

/* Migration aliases: layout and legacy field meanings are preserved. */
typedef AiRtStreamStatus AiStreamRuntimeStatus;
typedef AiRtStatus AiBatchRuntimeStatus;

/* Compatibility shim for existing diagnostics/tests. New applications use rt.h. */
void ai_batch_runtime_init(void);
void ai_batch_runtime_set_enabled(uint32_t enabled);
uint32_t ai_batch_runtime_is_enabled(void);
uint32_t ai_batch_runtime_is_idle(void);
/* Pure control-state observation; idle separately proves resource/device quiescence. */
AiRtState ai_batch_runtime_state(void);
void ai_batch_runtime_poll(void);
void ai_batch_runtime_print_status(void);
void ai_batch_runtime_print_frame_profiles(void);
void ai_batch_runtime_get_status(AiBatchRuntimeStatus *status);
void ai_batch_runtime_get_resources(AiRtResourceSnapshot *snapshot);
const AiBatchContext *ai_batch_runtime_context(uint32_t arena);
const AiDetectionResult *ai_batch_runtime_latest_result(uint32_t stream_id);
int ai_batch_runtime_get_stream_status(uint32_t stream_id,
                                       AiStreamRuntimeStatus *status);

#endif
