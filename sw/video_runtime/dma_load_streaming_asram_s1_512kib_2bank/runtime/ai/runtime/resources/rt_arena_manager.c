#include "ai/runtime/resources/rt_arena_manager.h"
#include "platform/platform.h"
#include <string.h>

void rt_arena_manager_init(AiRtArenaManager *m, uint32_t workers)
{
    if (!m)
        return;
    memset(m, 0, sizeof(*m));
    m->worker_count = workers <= AI_RT_MAX_WORKERS ? workers : AI_RT_MAX_WORKERS;
    for (uint32_t w = 0; w < m->worker_count; ++w)
        m->workers[w].head_pool_base = AI_MODEL_OUTPUT0_PHYS_BASE + w * AI_MODEL_OUTPUT_ARENA_BYTES;
}

int rt_arena_claim(AiRtArenaManager *m, const AiRtJobIdentity *id)
{
    if (!m || !id || id->worker_id >= m->worker_count || m->workers[id->worker_id].state != AI_RT_FREE)
        return -1;
    m->workers[id->worker_id].identity = *id;
    m->workers[id->worker_id].state = AI_RT_OWNED;
    return 0;
}

int rt_arena_compute_done(AiRtArenaManager *m, const AiRtJobIdentity *id)
{
    if (!m || !id || id->worker_id >= m->worker_count)
        return -1;
    AiRtArenaLease *s = &m->workers[id->worker_id];
    if (s->state != AI_RT_OWNED || !rt_job_identity_matches(&s->identity, id))
        return -1;
    s->state = AI_RT_FREE;
    return 0;
}

void rt_arena_fault(AiRtArenaManager *m, uint32_t worker)
{
    if (m && worker < m->worker_count && m->workers[worker].state != AI_RT_FREE && m->workers[worker].state != AI_RT_FAULT_HELD) {
        m->workers[worker].state = AI_RT_FAULT_HELD;
        ++m->unsafe_fault;
    }
}
