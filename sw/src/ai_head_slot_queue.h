#ifndef AI_HEAD_SLOT_QUEUE_H
#define AI_HEAD_SLOT_QUEUE_H

#include <stdint.h>

#include "ai_model_abi.h"
#include "yolov5nu_head_layout.h"

#define AI_HEAD_SLOT_QUEUE_MAX_WORKERS 3U
#define AI_HEAD_SLOT_QUEUE_CAPACITY \
    (AI_HEAD_SLOT_QUEUE_MAX_WORKERS * YOLOV5NU_HEAD_SLOTS_PER_WORKER)
#define AI_HEAD_SLOT_INVALID UINT32_MAX

typedef enum {
    AI_HEAD_SLOT_FREE = 0,
    AI_HEAD_SLOT_WRITING,
    AI_HEAD_SLOT_READY,
    AI_HEAD_SLOT_PROCESSING
} AiHeadSlotState;

typedef struct {
    uint64_t job_id;
    uint32_t worker_id;
    uint32_t stream_id;
    uint64_t frame_id;
    uint64_t timestamp;
    uint32_t version;
    uintptr_t base_addr;
    uintptr_t class_addr[3];
    uintptr_t dfl_addr[3];
} AiHeadSlotDescriptor;

typedef struct {
    AiHeadSlotState state;
    uint32_t slot_id;
    uint32_t error_status;
    uint32_t producer_complete;
    AiHeadSlotDescriptor descriptor;
} AiHeadSlot;

typedef struct {
    AiHeadSlot slots[AI_HEAD_SLOT_QUEUE_CAPACITY];
    uint32_t ready[AI_HEAD_SLOT_QUEUE_CAPACITY];
    uint32_t next_slot[AI_HEAD_SLOT_QUEUE_MAX_WORKERS];
    uint32_t worker_count;
    uint32_t ready_head;
    uint32_t ready_tail;
    uint32_t ready_count;
    uint32_t active;
} AiHeadSlotQueue;

void ai_head_slot_queue_init(AiHeadSlotQueue *queue, uint32_t worker_count);
int ai_head_slot_acquire(AiHeadSlotQueue *queue, uint32_t worker_id,
                         uintptr_t output_base,
                         const AiModelFrameRequest *request,
                         uint32_t *slot_key);
int ai_head_slot_admit(AiHeadSlotQueue *queue, uint32_t slot_key);
int ai_head_slot_publish(AiHeadSlotQueue *queue, uint32_t slot_key);
int ai_head_slot_start_next(AiHeadSlotQueue *queue, AiHeadSlot **slot);
int ai_head_slot_complete(AiHeadSlotQueue *queue, uint32_t error_status);
int ai_head_slot_release_writing(AiHeadSlotQueue *queue, uint32_t slot_key);
AiHeadSlot *ai_head_slot_get(AiHeadSlotQueue *queue, uint32_t slot_key);
const AiHeadSlot *ai_head_slot_get_const(const AiHeadSlotQueue *queue,
                                         uint32_t slot_key);

#endif
