#include "ai/runtime/resources/rt_tensor_manager.h"
#include "platform/platform.h"
#include <string.h>

static const AiRtTensorLease *lease(const AiRtTensorManager *m, AiRtSlotHandle h)
{
    if (!m || h.index >= AI_TENSOR_DEVICE_SLOT_COUNT || !h.generation ||
        m->slots[h.index].generation != h.generation)
        return 0;
    return &m->slots[h.index];
}

void rt_tensor_manager_init(AiRtTensorManager *m)
{
    if (m)
        memset(m, 0, sizeof(*m));
}

int rt_tensor_claim(AiRtTensorManager *m, uint32_t slot, const AiTensorDeviceDescriptor *d,
                    const AiRtJobIdentity *id, AiRtSlotHandle *h)
{
    if (!m || !d || !id || !h || slot >= AI_TENSOR_DEVICE_SLOT_COUNT)
        return -1;
    AiRtTensorLease *s = &m->slots[slot];
    uint32_t address = (slot < VIDEO_CHANNEL_COUNT ? TENSOR_ARENA0_PHYS_BASE : TENSOR_ARENA1_PHYS_BASE) +
                       (slot % VIDEO_CHANNEL_COUNT) * TENSOR_MEMBER_STRIDE;
    if (s->state != AI_RT_FREE || s->generation == UINT64_MAX || d->state != AI_TENSOR_DEVICE_READY ||
        !d->version || d->stream_id != slot % VIDEO_CHANNEL_COUNT || d->tensor_addr != address ||
        d->byte_count != TENSOR_MEMBER_BYTES || id->worker_id >= AI_RT_MAX_WORKERS ||
        id->stream_id != d->stream_id || id->frame_id != d->frame_id || id->version != d->version)
        return -1;
    ++s->generation;
    s->descriptor = *d;
    s->identity = *id;
    s->state = AI_RT_RESERVED;
    m->held |= UINT32_C(1) << slot;
    *h = (AiRtSlotHandle){slot, s->generation};
    return 0;
}

int rt_tensor_accept(AiRtTensorManager *m, AiRtSlotHandle h, const AiRtJobIdentity *id)
{
    const AiRtTensorLease *s = lease(m, h);
    if (!s || !id || s->state != AI_RT_RESERVED || !rt_job_identity_matches(&s->identity, id))
        return -1;
    m->slots[h.index].state = AI_RT_OWNED;
    return 0;
}

int rt_tensor_reject(AiRtTensorManager *m, AiRtSlotHandle h, const AiRtJobIdentity *id)
{
    const AiRtTensorLease *s = lease(m, h);
    if (!s || !id || s->state != AI_RT_RESERVED || !rt_job_identity_matches(&s->identity, id))
        return -1;
    m->slots[h.index].state = AI_RT_FREE;
    m->held &= ~(UINT32_C(1) << h.index);
    return 0;
}

int rt_tensor_prove_compute(AiRtTensorManager *m, AiRtSlotHandle h, const AiRtJobIdentity *proof)
{
    const AiRtTensorLease *s = lease(m, h);
    if (!s || !proof || s->state != AI_RT_OWNED || !rt_job_identity_matches(&s->identity, proof))
        return -1;
    m->slots[h.index].state = AI_RT_RELEASE_PENDING;
    return 0;
}

int rt_tensor_can_release(const AiRtTensorManager *m, AiRtSlotHandle h, const AiRtJobIdentity *id)
{
    const AiRtTensorLease *s = lease(m, h);
    return s && id && s->state == AI_RT_RELEASE_PENDING && rt_job_identity_matches(&s->identity, id);
}

int rt_tensor_release_ack(AiRtTensorManager *m, AiRtSlotHandle h, const AiRtJobIdentity *id)
{
    if (!rt_tensor_can_release(m, h, id))
        return -1;
    m->slots[h.index].state = AI_RT_FREE;
    m->held &= ~(UINT32_C(1) << h.index);
    return 0;
}

void rt_tensor_release_retry(AiRtTensorManager *m)
{
    if (m)
        ++m->release_retry;
}

void rt_tensor_fault(AiRtTensorManager *m, AiRtSlotHandle h)
{
    const AiRtTensorLease *s = lease(m, h);
    if (s && s->state != AI_RT_FREE && s->state != AI_RT_FAULT_HELD) {
        m->slots[h.index].state = AI_RT_FAULT_HELD;
        ++m->unsafe_fault;
    }
}
