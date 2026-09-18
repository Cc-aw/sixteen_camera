#include "ai_tensor_slot_pool.h"

#include "ai_model_backend.h"

#include <stddef.h>

static AiTensorSlot *mutable_slot(AiTensorSlotPool *pool,
                                  AiTensorSlotHandle handle)
{
    if (pool == NULL || handle.index >= AI_TENSOR_SLOT_COUNT)
        return NULL;
    AiTensorSlot *slot = &pool->slots[handle.index];
    return slot->generation == handle.generation ? slot : NULL;
}

const AiTensorSlot *ai_tensor_slot_get(const AiTensorSlotPool *pool,
                                       AiTensorSlotHandle handle)
{
    if (pool == NULL || handle.index >= AI_TENSOR_SLOT_COUNT)
        return NULL;
    const AiTensorSlot *slot = &pool->slots[handle.index];
    return slot->generation == handle.generation ? slot : NULL;
}

void ai_tensor_slot_pool_init(AiTensorSlotPool *pool)
{
    if (pool == NULL)
        return;
    for (uint32_t stream = 0; stream < VIDEO_CHANNEL_COUNT; ++stream)
        pool->latest_ready[stream] = AI_TENSOR_SLOT_INVALID;
    for (uint32_t index = 0; index < AI_TENSOR_SLOT_COUNT; ++index) {
        AiTensorSlot *slot = &pool->slots[index];
        uint32_t arena = index / VIDEO_CHANNEL_COUNT;
        uint32_t member = index % VIDEO_CHANNEL_COUNT;
        slot->tensor_addr = (arena == 0U ? TENSOR_ARENA0_PHYS_BASE :
                                            TENSOR_ARENA1_PHYS_BASE) +
                            member * TENSOR_MEMBER_STRIDE;
        slot->stream_id = 0U;
        slot->frame_id = 0U;
        slot->timestamp = 0U;
        slot->version = 0U;
        slot->byte_count = 0U;
        slot->error_code = 0U;
        slot->owner_worker = AI_TENSOR_SLOT_INVALID;
        slot->generation = 0U;
        slot->state = AI_TENSOR_SLOT_FREE;
    }
}

int ai_tensor_slot_begin_write(AiTensorSlotPool *pool, uint32_t stream_id,
                               uint64_t frame_id, uint64_t timestamp,
                               uint32_t version, AiTensorSlotHandle *handle)
{
    if (pool == NULL || handle == NULL || stream_id >= VIDEO_CHANNEL_COUNT)
        return -1;
    uint32_t selected = AI_TENSOR_SLOT_INVALID;
    for (uint32_t index = 0; index < AI_TENSOR_SLOT_COUNT; ++index) {
        if (pool->slots[index].state == AI_TENSOR_SLOT_FREE) {
            selected = index;
            break;
        }
    }
    if (selected == AI_TENSOR_SLOT_INVALID) {
        selected = pool->latest_ready[stream_id];
        if (selected == AI_TENSOR_SLOT_INVALID)
            return 0;
        if (pool->slots[selected].frame_id >= frame_id)
            return 0;
        pool->latest_ready[stream_id] = AI_TENSOR_SLOT_INVALID;
    }
    AiTensorSlot *slot = &pool->slots[selected];
    slot->generation++;
    slot->stream_id = stream_id;
    slot->frame_id = frame_id;
    slot->timestamp = timestamp;
    slot->version = version;
    slot->byte_count = 0U;
    slot->error_code = 0U;
    slot->owner_worker = AI_TENSOR_SLOT_INVALID;
    slot->state = AI_TENSOR_SLOT_WRITING;
    handle->index = selected;
    handle->generation = slot->generation;
    return 1;
}

int ai_tensor_slot_finish_write(AiTensorSlotPool *pool,
                                AiTensorSlotHandle handle,
                                uint32_t byte_count, int write_error)
{
    AiTensorSlot *slot = mutable_slot(pool, handle);
    if (slot == NULL || slot->state != AI_TENSOR_SLOT_WRITING)
        return -1;
    slot->byte_count = byte_count;
    if (write_error || byte_count != TENSOR_MEMBER_BYTES) {
        slot->error_code = write_error != 0 ? (uint32_t)write_error : 1U;
        slot->state = AI_TENSOR_SLOT_ERROR;
        return -1;
    }
    uint32_t old_index = pool->latest_ready[slot->stream_id];
    if (old_index != AI_TENSOR_SLOT_INVALID) {
        AiTensorSlot *old = &pool->slots[old_index];
        if (old->frame_id >= slot->frame_id) {
            slot->state = AI_TENSOR_SLOT_FREE;
            return 0;
        }
        old->state = AI_TENSOR_SLOT_FREE;
    }
    slot->state = AI_TENSOR_SLOT_READY;
    pool->latest_ready[slot->stream_id] = handle.index;
    return 1;
}

int ai_tensor_slot_acquire_latest(AiTensorSlotPool *pool, uint32_t stream_id,
                                  uint32_t worker_id,
                                  AiTensorSlotHandle *handle)
{
    if (pool == NULL || handle == NULL || stream_id >= VIDEO_CHANNEL_COUNT ||
        worker_id >= AI_MODEL_WORKER_COUNT)
        return -1;
    uint32_t index = pool->latest_ready[stream_id];
    if (index == AI_TENSOR_SLOT_INVALID)
        return 0;
    AiTensorSlot *slot = &pool->slots[index];
    if (slot->state != AI_TENSOR_SLOT_READY)
        return -1;
    slot->state = AI_TENSOR_SLOT_RUNNING;
    slot->owner_worker = worker_id;
    pool->latest_ready[stream_id] = AI_TENSOR_SLOT_INVALID;
    handle->index = index;
    handle->generation = slot->generation;
    return 1;
}

int ai_tensor_slot_release(AiTensorSlotPool *pool,
                           AiTensorSlotHandle handle)
{
    AiTensorSlot *slot = mutable_slot(pool, handle);
    if (slot == NULL || (slot->state != AI_TENSOR_SLOT_RUNNING &&
                         slot->state != AI_TENSOR_SLOT_ERROR))
        return -1;
    slot->state = AI_TENSOR_SLOT_FREE;
    slot->owner_worker = AI_TENSOR_SLOT_INVALID;
    return 0;
}
