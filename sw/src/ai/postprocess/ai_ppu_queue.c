#include "ai/postprocess/ai_ppu_queue.h"

/* See the publication adapter: retain the existing translation-unit boundary
 * so ordered MMIO cannot spread to Tensor, model or generic backend objects. */
#include "../../drivers/ppu/ai_ppu_device_queue.c"

int ai_ppu_queue_init(void) { return ai_ppu_device_queue_init(); }
int ai_ppu_queue_active(void) { return ai_ppu_device_queue_active(); }
void ai_ppu_queue_expect(uint32_t stream, uint64_t frame, uint32_t version)
{
    ai_ppu_device_queue_expect(stream, frame, version);
}
int ai_ppu_queue_ready(void) { return ai_ppu_device_queue_ready(); }
int ai_ppu_queue_submit(const AiHeadSlotDescriptor *descriptor)
{
    /* Preserve the legacy readiness short circuit before reading metadata. */
    if (!ai_ppu_device_queue_ready()) return 0;
    const AiPpuDeviceDescriptor device = {
        .base_addr = descriptor->base_addr,
        .class_addr = {descriptor->class_addr[0], descriptor->class_addr[1],
                       descriptor->class_addr[2]},
        .dfl_addr = {descriptor->dfl_addr[0], descriptor->dfl_addr[1],
                     descriptor->dfl_addr[2]},
        .stream = descriptor->stream_id,
        .frame = descriptor->frame_id,
        .version = descriptor->version
    };
    return ai_ppu_device_queue_submit_ready(&device);
}
int ai_ppu_queue_peek(AiPpuQueueResult *result)
{
    AiPpuDeviceResult device;
    int status = ai_ppu_device_queue_peek(&device);
    if (status > 0) {
        result->bank = device.bank;
        result->generation = device.generation;
        result->stream = device.stream;
        result->version = device.version;
        result->count = device.count;
        result->status = device.status;
        result->cycles = device.cycles;
        result->frame = device.frame;
    }
    return status;
}
void ai_ppu_queue_pop(void) { ai_ppu_device_queue_pop(); }
