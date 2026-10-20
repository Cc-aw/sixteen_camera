#include "ai/runtime/resources/rt_head_manager.h"
#include <string.h>

void rt_head_manager_init(AiRtHeadManager *m)
{
    if (m)
        memset(m, 0, sizeof(*m));
}

int rt_head_bind(AiRtHeadManager *m, const AiHeadSlotQueue *q, uint32_t key, uint32_t hw_generation)
{
    const AiHeadSlot *s = ai_head_slot_get_const(q, key);
    if (!m || !s || key >= AI_RT_HEAD_CAPACITY || s->state != AI_HEAD_SLOT_WRITING ||
        m->slots[key].state != AI_RT_FREE || m->slots[key].generation == UINT64_MAX)
        return -1;
    AiRtHeadLease *h = &m->slots[key];
    const AiHeadSlotDescriptor *d = &s->descriptor;
    ++h->generation;
    h->identity = rt_job_identity(d->job_id, d->worker_id, d->stream_id, d->frame_id, d->version);
    h->hardware_generation = hw_generation;
    h->producer_mask = 0;
    h->state = AI_RT_OWNED;
    h->base = d->base_addr;
    return 0;
}

int rt_head_result_matches(const AiRtHeadManager *m, const AiHeadSlotQueue *q, const AiPpuDeviceResult *r)
{
    if (!m || !r || r->bank >= AI_RT_HEAD_CAPACITY)
        return 0;
    const AiHeadSlot *s = ai_head_slot_get_const(q, r->bank);
    const AiRtHeadLease *h = &m->slots[r->bank];
    if (!s || s->state != AI_HEAD_SLOT_PROCESSING || h->state != AI_RT_OWNED)
        return 0;
    const AiHeadSlotDescriptor *d = &s->descriptor;
    AiRtJobIdentity id = rt_job_identity(d->job_id, d->worker_id, d->stream_id, d->frame_id, d->version);
    return rt_job_identity_matches(&id, &h->identity) && r->generation == h->hardware_generation &&
           r->stream == id.stream_id && r->frame == id.frame_id && r->version == id.version;
}

int rt_head_retire(AiRtHeadManager *m, const AiHeadSlotQueue *q, AiRtSlotHandle handle, const AiRtJobIdentity *id)
{
    uint32_t key = handle.index;
    if (key >= AI_RT_HEAD_CAPACITY || !m || !handle.generation || m->slots[key].generation != handle.generation)
        return -1;
    if (!id || m->slots[key].state != AI_RT_OWNED ||
        !rt_job_identity_matches(&m->slots[key].identity, id))
        return -1;
    const AiHeadSlot *slot = ai_head_slot_get_const(q, key);
    if (!slot || slot->state != AI_HEAD_SLOT_FREE || !slot->producer_complete)
        return -1;
    m->slots[key].state = AI_RT_FREE;
    return 0;
}

void rt_head_fault(AiRtHeadManager *m, uint32_t key)
{
    if (m && key < AI_RT_HEAD_CAPACITY && m->slots[key].state != AI_RT_FREE && m->slots[key].state != AI_RT_FAULT_HELD) {
        m->slots[key].state = AI_RT_FAULT_HELD;
        ++m->unsafe_fault;
    }
}
