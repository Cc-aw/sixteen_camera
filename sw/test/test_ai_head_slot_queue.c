#include <assert.h>
#include <stdint.h>
#include <stdio.h>

#include "ai_head_slot_queue.h"

static AiModelFrameRequest make_request(uint32_t worker, uint64_t job)
{
    AiModelFrameRequest request = {
        .job_id = job,
        .worker_id = worker,
        .stream_id = worker + 3U,
        .frame_id = job + 100U,
        .timestamp = job + 200U,
        .version = (uint32_t)job + 10U
    };
    return request;
}

int main(void)
{
    AiHeadSlotQueue queue;
    AiHeadSlot *active = 0;
    AiModelFrameRequest worker0 = make_request(0U, 10U);
    AiModelFrameRequest worker1 = make_request(1U, 20U);
    uint32_t key0;
    uint32_t key1;
    uint32_t key2;

    ai_head_slot_queue_init(&queue, 2U);
    assert(queue.active == AI_HEAD_SLOT_INVALID);
    assert(queue.ready_count == 0U);

    assert(ai_head_slot_acquire(&queue, 0U, UINT32_C(0x32000000),
                                &worker0, &key0) == 0);
    assert(key0 == 0U);
    const AiHeadSlot *slot0 = ai_head_slot_get_const(&queue, key0);
    assert(slot0 != 0 && slot0->state == AI_HEAD_SLOT_WRITING);
    assert(slot0->descriptor.job_id == 10U);
    assert(slot0->descriptor.base_addr == UINT32_C(0x32000000));
    assert(slot0->descriptor.class_addr[1] ==
           UINT32_C(0x32000000) + YOLOV5NU_HEAD_CLASS1_OFFSET);
    assert(slot0->descriptor.dfl_addr[2] ==
           UINT32_C(0x32000000) + YOLOV5NU_HEAD_DFL2_OFFSET);

    assert(ai_head_slot_acquire(&queue, 1U, UINT32_C(0x32400000),
                                &worker1, &key1) == 0);
    assert(key1 == 2U);
    /* FIFO order follows publication, not worker polling order. */
    assert(ai_head_slot_publish(&queue, key1) == 0);
    assert(ai_head_slot_publish(&queue, key0) == 0);
    assert(queue.ready_count == 2U);
    assert(ai_head_slot_publish(&queue, key0) < 0);

    assert(ai_head_slot_start_next(&queue, &active) == 1);
    assert(active != 0 && active->descriptor.worker_id == 1U);
    assert(active->state == AI_HEAD_SLOT_PROCESSING);
    assert(ai_head_slot_start_next(&queue, &active) < 0);
    assert(ai_head_slot_complete(&queue, 4U) == 0);
    slot0 = ai_head_slot_get_const(&queue, key1);
    assert(slot0->state == AI_HEAD_SLOT_FREE);
    assert(slot0->error_status == 4U);

    assert(ai_head_slot_start_next(&queue, &active) == 1);
    assert(active != 0 && active->descriptor.worker_id == 0U);
    assert(ai_head_slot_complete(&queue, 0U) == 0);
    assert(queue.ready_count == 0U);
    assert(ai_head_slot_start_next(&queue, &active) == 0);

    /* A completed worker alternates to its other one-MiB slot. */
    worker1.job_id++;
    assert(ai_head_slot_acquire(&queue, 1U, UINT32_C(0x32400000),
                                &worker1, &key2) == 0);
    assert(key2 == 3U);
    slot0 = ai_head_slot_get_const(&queue, key2);
    assert(slot0->slot_id == 1U);
    assert(slot0->descriptor.base_addr == UINT32_C(0x32500000));
    assert(slot0->error_status == 0U);
    assert(ai_head_slot_release_writing(&queue, key2) == 0);
    assert(ai_head_slot_release_writing(&queue, key2) < 0);

    /* Both ping-pong slots can be owned, but a third write is rejected. */
    assert(ai_head_slot_acquire(&queue, 0U, UINT32_C(0x32000000),
                                &worker0, &key0) == 0);
    assert(ai_head_slot_acquire(&queue, 0U, UINT32_C(0x32000000),
                                &worker0, &key1) == 0);
    assert(key0 != key1);
    assert(ai_head_slot_acquire(&queue, 0U, UINT32_C(0x32000000),
                                &worker0, &key2) == -2);
    assert(ai_head_slot_release_writing(&queue, key0) == 0);
    assert(ai_head_slot_release_writing(&queue, key1) == 0);

    puts("AI head slot queue PASS");
    return 0;
}
