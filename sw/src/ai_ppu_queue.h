#ifndef AI_PPU_QUEUE_H
#define AI_PPU_QUEUE_H
#include "ai_head_slot_queue.h"
typedef struct {
    uint32_t bank, generation, stream, version, count, status, cycles;
    uint64_t frame;
} AiPpuQueueResult;
int ai_ppu_queue_init(void);
int ai_ppu_queue_active(void);
void ai_ppu_queue_expect(uint32_t stream, uint64_t frame, uint32_t version);
int ai_ppu_queue_ready(void);
int ai_ppu_queue_submit(const AiHeadSlotDescriptor *descriptor);
int ai_ppu_queue_peek(AiPpuQueueResult *result);
void ai_ppu_queue_pop(void);
#endif
