#ifndef RT_HEAD_MANAGER_H
#define RT_HEAD_MANAGER_H
#include "ai/runtime/resources/rt_resources.h"
#include "ai/runtime/ai_head_slot_queue.h"
#include "drivers/ppu/ai_ppu_device.h"
typedef struct {
    AiRtHeadLease slots[AI_RT_HEAD_CAPACITY];
    uint32_t unsafe_fault;
} AiRtHeadManager;

/* Queue transitions remain authoritative. A lease can retire only after
 * matching PPU completion and native queue completion; compute is insufficient. */
void rt_head_manager_init(AiRtHeadManager *manager);
int rt_head_bind(AiRtHeadManager *manager, const AiHeadSlotQueue *queue, uint32_t key, uint32_t generation);
int rt_head_result_matches(const AiRtHeadManager *manager, const AiHeadSlotQueue *queue, const AiPpuDeviceResult *result);
int rt_head_retire(AiRtHeadManager *manager, const AiHeadSlotQueue *queue, AiRtSlotHandle handle, const AiRtJobIdentity *identity);
void rt_head_fault(AiRtHeadManager *manager, uint32_t key);
#endif
