#ifndef AI_TENSOR_SLOT_POOL_H
#define AI_TENSOR_SLOT_POOL_H

#include <stdint.h>

#include "platform.h"

#define AI_TENSOR_SLOT_COUNT (VIDEO_CHANNEL_COUNT * 2U)
#define AI_TENSOR_SLOT_INVALID UINT32_MAX

typedef enum {
    AI_TENSOR_SLOT_FREE = 0,
    AI_TENSOR_SLOT_WRITING,
    AI_TENSOR_SLOT_READY,
    AI_TENSOR_SLOT_RUNNING,
    AI_TENSOR_SLOT_ERROR
} AiTensorSlotState;

typedef struct {
    uint32_t index;
    uint32_t generation;
} AiTensorSlotHandle;

typedef struct {
    uint32_t tensor_addr;
    uint32_t stream_id;
    uint64_t frame_id;
    uint64_t timestamp;
    uint32_t version;
    uint32_t byte_count;
    uint32_t owner_worker;
    uint32_t generation;
    AiTensorSlotState state;
} AiTensorSlot;

typedef struct {
    AiTensorSlot slots[AI_TENSOR_SLOT_COUNT];
    uint32_t latest_ready[VIDEO_CHANNEL_COUNT];
} AiTensorSlotPool;

void ai_tensor_slot_pool_init(AiTensorSlotPool *pool);
int ai_tensor_slot_begin_write(AiTensorSlotPool *pool, uint32_t stream_id,
                               uint64_t frame_id, uint64_t timestamp,
                               uint32_t version, AiTensorSlotHandle *handle);
int ai_tensor_slot_finish_write(AiTensorSlotPool *pool,
                                AiTensorSlotHandle handle,
                                uint32_t byte_count, int write_error);
int ai_tensor_slot_acquire_latest(AiTensorSlotPool *pool, uint32_t stream_id,
                                  uint32_t worker_id,
                                  AiTensorSlotHandle *handle);
int ai_tensor_slot_release(AiTensorSlotPool *pool,
                           AiTensorSlotHandle handle);
const AiTensorSlot *ai_tensor_slot_get(const AiTensorSlotPool *pool,
                                       AiTensorSlotHandle handle);

#endif
