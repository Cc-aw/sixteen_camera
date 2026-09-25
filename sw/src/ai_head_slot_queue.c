#include "ai_head_slot_queue.h"

#include <string.h>

_Static_assert(YOLOV5NU_HEAD_SLOTS_PER_WORKER == 2U,
               "head slot selection expects ping-pong pairs");

static uint32_t slot_capacity(const AiHeadSlotQueue *queue)
{
    return queue->worker_count * YOLOV5NU_HEAD_SLOTS_PER_WORKER;
}

static uint32_t make_slot_key(uint32_t worker_id, uint32_t slot_id)
{
    return worker_id * YOLOV5NU_HEAD_SLOTS_PER_WORKER + slot_id;
}

AiHeadSlot *ai_head_slot_get(AiHeadSlotQueue *queue, uint32_t slot_key)
{
    if (queue == 0 || slot_key >= slot_capacity(queue))
        return 0;
    return &queue->slots[slot_key];
}

const AiHeadSlot *ai_head_slot_get_const(const AiHeadSlotQueue *queue,
                                         uint32_t slot_key)
{
    if (queue == 0 || slot_key >= slot_capacity(queue))
        return 0;
    return &queue->slots[slot_key];
}

void ai_head_slot_queue_init(AiHeadSlotQueue *queue, uint32_t worker_count)
{
    if (queue == 0)
        return;
    memset(queue, 0, sizeof(*queue));
    queue->worker_count = worker_count <= AI_HEAD_SLOT_QUEUE_MAX_WORKERS ?
                          worker_count : AI_HEAD_SLOT_QUEUE_MAX_WORKERS;
    queue->active = AI_HEAD_SLOT_INVALID;
    for (uint32_t worker = 0U; worker < queue->worker_count; ++worker)
        for (uint32_t slot = 0U;
             slot < YOLOV5NU_HEAD_SLOTS_PER_WORKER; ++slot)
            queue->slots[make_slot_key(worker, slot)].slot_id = slot;
}

int ai_head_slot_acquire(AiHeadSlotQueue *queue, uint32_t worker_id,
                         uintptr_t output_base,
                         const AiModelFrameRequest *request,
                         uint32_t *slot_key)
{
    AiHeadSlot *slot;
    uint32_t selected;
    uint32_t alternate;
    if (queue == 0 || request == 0 || slot_key == 0 ||
        worker_id >= queue->worker_count)
        return -1;
    selected = queue->next_slot[worker_id];
    alternate = selected ^ 1U;
    slot = &queue->slots[make_slot_key(worker_id, selected)];
    if (slot->state != AI_HEAD_SLOT_FREE) {
        slot = &queue->slots[make_slot_key(worker_id, alternate)];
        selected = alternate;
        if (slot->state != AI_HEAD_SLOT_FREE)
            return -2;
    }
    memset(&slot->descriptor, 0, sizeof(slot->descriptor));
    slot->descriptor.job_id = request->job_id;
    slot->descriptor.worker_id = worker_id;
    slot->descriptor.stream_id = request->stream_id;
    slot->descriptor.frame_id = request->frame_id;
    slot->descriptor.timestamp = request->timestamp;
    slot->descriptor.version = request->version;
    slot->descriptor.base_addr = output_base +
        selected * YOLOV5NU_HEAD_SLOT_STRIDE;
    slot->descriptor.class_addr[0] = slot->descriptor.base_addr +
        YOLOV5NU_HEAD_CLASS0_OFFSET;
    slot->descriptor.class_addr[1] = slot->descriptor.base_addr +
        YOLOV5NU_HEAD_CLASS1_OFFSET;
    slot->descriptor.class_addr[2] = slot->descriptor.base_addr +
        YOLOV5NU_HEAD_CLASS2_OFFSET;
    slot->descriptor.dfl_addr[0] = slot->descriptor.base_addr +
        YOLOV5NU_HEAD_DFL0_OFFSET;
    slot->descriptor.dfl_addr[1] = slot->descriptor.base_addr +
        YOLOV5NU_HEAD_DFL1_OFFSET;
    slot->descriptor.dfl_addr[2] = slot->descriptor.base_addr +
        YOLOV5NU_HEAD_DFL2_OFFSET;
    slot->error_status = 0U;
    slot->producer_complete = 0U;
    slot->state = AI_HEAD_SLOT_WRITING;
    *slot_key = make_slot_key(worker_id, selected);
    return 0;
}

int ai_head_slot_admit(AiHeadSlotQueue *queue, uint32_t slot_key)
{
    AiHeadSlot *slot = ai_head_slot_get(queue, slot_key);
    uint32_t capacity;
    if (slot == 0 || slot->state != AI_HEAD_SLOT_WRITING)
        return -1;
    capacity = slot_capacity(queue);
    if (queue->ready_count >= capacity)
        return -2;
    slot->state = AI_HEAD_SLOT_READY;
    queue->ready[queue->ready_tail] = slot_key;
    queue->ready_tail = (queue->ready_tail + 1U) % capacity;
    queue->ready_count++;
    return 0;
}

int ai_head_slot_publish(AiHeadSlotQueue *queue, uint32_t slot_key)
{
    AiHeadSlot *slot = ai_head_slot_get(queue, slot_key);
    if (!slot || slot->producer_complete || slot->state == AI_HEAD_SLOT_FREE) return -1;
    if (slot->state == AI_HEAD_SLOT_WRITING && ai_head_slot_admit(queue, slot_key) != 0) return -2;
    slot->producer_complete = 1U;
    return 0;
}

int ai_head_slot_start_next(AiHeadSlotQueue *queue, AiHeadSlot **slot)
{
    uint32_t slot_key;
    uint32_t capacity;
    AiHeadSlot *selected;
    if (queue == 0 || slot == 0)
        return -1;
    *slot = 0;
    if (queue->active != AI_HEAD_SLOT_INVALID)
        return -2;
    if (queue->ready_count == 0U)
        return 0;
    capacity = slot_capacity(queue);
    slot_key = queue->ready[queue->ready_head];
    queue->ready_head = (queue->ready_head + 1U) % capacity;
    queue->ready_count--;
    selected = ai_head_slot_get(queue, slot_key);
    if (selected == 0 || selected->state != AI_HEAD_SLOT_READY)
        return -3;
    selected->state = AI_HEAD_SLOT_PROCESSING;
    queue->active = slot_key;
    *slot = selected;
    return 1;
}

int ai_head_slot_complete(AiHeadSlotQueue *queue, uint32_t error_status)
{
    AiHeadSlot *slot;
    uint32_t worker_id;
    if (queue == 0 || queue->active == AI_HEAD_SLOT_INVALID)
        return -1;
    slot = ai_head_slot_get(queue, queue->active);
    if (slot == 0 || slot->state != AI_HEAD_SLOT_PROCESSING || !slot->producer_complete)
        return -2;
    worker_id = slot->descriptor.worker_id;
    slot->error_status = error_status;
    slot->state = AI_HEAD_SLOT_FREE;
    queue->next_slot[worker_id] = slot->slot_id ^ 1U;
    queue->active = AI_HEAD_SLOT_INVALID;
    return 0;
}

int ai_head_slot_release_writing(AiHeadSlotQueue *queue, uint32_t slot_key)
{
    AiHeadSlot *slot = ai_head_slot_get(queue, slot_key);
    if (slot == 0 || slot->state != AI_HEAD_SLOT_WRITING)
        return -1;
    slot->state = AI_HEAD_SLOT_FREE;
    return 0;
}
