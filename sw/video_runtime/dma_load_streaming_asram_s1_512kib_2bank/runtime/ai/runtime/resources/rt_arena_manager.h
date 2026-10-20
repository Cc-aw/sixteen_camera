#ifndef RT_ARENA_MANAGER_H
#define RT_ARENA_MANAGER_H
#include "ai/runtime/resources/rt_resources.h"
typedef struct {
    AiRtArenaLease workers[AI_RT_MAX_WORKERS];
    uint32_t worker_count, unsafe_fault;
} AiRtArenaManager;

/* Initialize fresh storage; the backend guards reinitialization while owned. */
void rt_arena_manager_init(AiRtArenaManager *manager, uint32_t workers);
int rt_arena_claim(AiRtArenaManager *manager, const AiRtJobIdentity *identity);
int rt_arena_compute_done(AiRtArenaManager *manager, const AiRtJobIdentity *proof);
void rt_arena_fault(AiRtArenaManager *manager, uint32_t worker);
#endif
