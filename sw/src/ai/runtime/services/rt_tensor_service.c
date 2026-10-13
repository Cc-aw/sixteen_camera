#include "ai/runtime/core/rt_internal.h"
#include "platform/cycle.h"
#include "platform/platform.h"
#include <string.h>

uint32_t rt_tensor_ready(AiRtCore *rt)
{
    rt->tensors.ready = ai_tensor_device_ready();
    return rt->tensors.ready;
}

uint32_t rt_tensor_error(AiRtCore *rt)
{
    rt->tensors.error = ai_tensor_device_error();
    return rt->tensors.error;
}

uint32_t rt_tensor_writing(AiRtCore *rt)
{
    rt->tensors.writing = ai_tensor_device_writing();
    return rt->tensors.writing;
}

int rt_tensor_read_slot(uint32_t slot, AiTensorSlot *metadata)
{
    AiTensorDeviceDescriptor descriptor;
    if (metadata == 0 || ai_tensor_device_read_slot(slot, &descriptor) != 0)
        return -1;
    metadata->tensor_addr = descriptor.tensor_addr;
    metadata->stream_id = descriptor.stream_id;
    metadata->frame_id = descriptor.frame_id;
    metadata->timestamp = descriptor.timestamp;
    metadata->version = descriptor.version;
    metadata->byte_count = descriptor.byte_count;
    metadata->error_code = descriptor.error_code;
    metadata->owner_worker = AI_TENSOR_SLOT_INVALID;
    metadata->generation = descriptor.version;
    metadata->state = AI_TENSOR_SLOT_READY;
    return 0;
}

int rt_tensor_release_slot(AiRtCore *rt, uint32_t slot)
{
    return ai_tensor_device_release(slot, rt_control_enabled(&rt->control));
}

void rt_tensor_track_ready(AiRtCore *rt, uint32_t ready)
{
    uint64_t now = platform_read_cycle();
    for (uint32_t slot = 0U; slot < AI_TENSOR_SLOT_COUNT; ++slot) {
        uint32_t bit = UINT32_C(1) << slot;
        if ((ready & bit) != 0U) {
            if (rt->ready_seen_cycle[slot] == 0U)
                rt->ready_seen_cycle[slot] = now;
        } else {
            rt->ready_seen_cycle[slot] = 0U;
            rt->head_wait_start[slot] = 0U;
        }
    }
}

void rt_tensor_service_stale(AiRtCore *rt, uint32_t ready)
{
    if (rt_control_faulted(&rt->control) != 0U)
        return;
    uint32_t free_ready = ready & ~rt->tensors.held;
    for (uint32_t stream = 0U; stream < VIDEO_CHANNEL_COUNT; ++stream) {
        uint32_t bit0 = UINT32_C(1) << stream;
        uint32_t bit1 = UINT32_C(1) << (stream + VIDEO_CHANNEL_COUNT);
        uint32_t pair = free_ready & (bit0 | bit1);
        uint32_t stale_slot = AI_TENSOR_SLOT_INVALID;
        if (pair == (bit0 | bit1)) {
            AiTensorSlot slot0, slot1;
            if (rt_tensor_read_slot(stream, &slot0) != 0 ||
                rt_tensor_read_slot(stream + VIDEO_CHANNEL_COUNT, &slot1) != 0)
                continue;
            stale_slot = slot0.version <= slot1.version ? stream :
                         stream + VIDEO_CHANNEL_COUNT;
        } else if (pair != 0U &&
                   rt->streams[stream].last_frame_valid != 0U) {
            uint32_t slot = (pair & bit0) != 0U ? stream :
                            stream + VIDEO_CHANNEL_COUNT;
            AiTensorSlot metadata;
            if (rt_tensor_read_slot(slot, &metadata) == 0 &&
                metadata.version <= rt->streams[stream].last_version)
                stale_slot = slot;
        }
        if (stale_slot != AI_TENSOR_SLOT_INVALID) {
            if (rt_tensor_release_slot(rt, stale_slot) == 0)
                rt->streams[stream].superseded_count++;
            else {
                rt_record_error(rt, -46);
                rt_control_fault(&rt->control);
            }
            return;
        }
    }
}

uint32_t rt_tensor_drain_one(AiRtCore *rt, uint32_t ready)
{
    uint32_t releasable = (ready | rt_tensor_error(rt)) & ~rt->tensors.held;
    if (releasable != 0U) {
        for (uint32_t slot = 0U; slot < 32U; ++slot)
            if ((releasable & (UINT32_C(1) << slot)) != 0U) {
                if (rt_tensor_release_slot(rt, slot) != 0)
                    rt_record_error(rt, -50);
                break;
            }
        return 1U;
    }
    return 0U;
}
