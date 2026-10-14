#define _XOPEN_SOURCE 700
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifndef __riscv
#include <ucontext.h>
#endif
#include "independent.h"
#include "yolo32.h"

uint64_t tick;
static unsigned selected, stage[3], heads[3], submitted[3], baseline[3];
static unsigned retired[3], allow_retire[3], publications[3], starts[3];
static unsigned new_flush[3];
#if YOLO32_CREDIT_LIMIT
static unsigned allow_entry[3] = {1, 1, 1};
uint32_t yolo32_independent_credit_pending(unsigned w, uint32_t issued) {
    if (allow_retire[w]) retired[w] = submitted[w];
    uint32_t pending = baseline[w] + issued - retired[w];
    assert(pending <= YOLO32_CREDIT_LIMIT);
    return pending;
}
unsigned yolo32_independent_credit_status(unsigned w) {
    return allow_entry[w];
}
#endif
#ifndef __riscv
static struct { Yolo32TaskContext *key; ucontext_t uc; uintptr_t top; } ctx[4];
static unsigned used;
#endif
void yolo32_fail(const char *s) { fprintf(stderr, "%s\n", s); abort(); }
unsigned yolo32_stage(unsigned w) { return stage[w]; }
unsigned yolo32_independent_head_mask(unsigned w) { return heads[w]; }
unsigned yolo32_independent_busy_mask(void) {
    unsigned mask = 0;
    for (unsigned w = 0; w < 3; ++w)
        if (retired[w] != submitted[w]) mask |= 1U << w;
    return mask;
}
void yolo32_independent_select(unsigned w) { selected = w; }
void yolo32_independent_snapshot(unsigned w) { baseline[w] = submitted[w]; }
unsigned yolo32_independent_ready(unsigned w, uint32_t n) {
    if (new_flush[w]) return 0;
    if (allow_retire[w]) retired[w] = submitted[w];
    return retired[w] == submitted[w] && submitted[w] == baseline[w] + n;
}
void yolo32_ppu_early_service(void) {
    const Yolo32IndependentStats *s = yolo32_independent_stats();
    for (unsigned w = 0; w < 3; ++w) {
        unsigned delta = s->head_produced_mask[w] & ~publications[w];
        if (delta) assert(retired[w] == submitted[w]);
        publications[w] |= delta;
    }
}
#ifndef __riscv
static __attribute__((noinline)) unsigned index_of(Yolo32TaskContext *p) {
    for (unsigned i = 0; i < used; ++i) if (ctx[i].key == p) return i;
    assert(used < 4);
    unsigned i = used++;
    ctx[i].key = p;
    return i;
}
void yolo32_task_switch(Yolo32TaskContext *from, const Yolo32TaskContext *to) {
    unsigned f = index_of(from), t = index_of((Yolo32TaskContext *)to);
    if (to->ra && (!ctx[t].top || to->sp == ctx[t].top)) {
        ctx[t].top = to->sp;
        getcontext(&ctx[t].uc);
        ctx[t].uc.uc_stack.ss_sp = (void *)(to->sp - 16384 + 64);
        ctx[t].uc.uc_stack.ss_size = 16384 - 64;
        ctx[t].uc.uc_link = NULL;
        makecontext(&ctx[t].uc, (void (*)(void))to->ra, 0);
    }
    uintptr_t marker = 0;
    from->sp = (uintptr_t)&marker;
    assert(swapcontext(&ctx[f].uc, &ctx[t].uc) == 0);
}
#endif
int yolo32_graph_poll(unsigned w, Yolo32Result *r) {
    (void)r;
    assert(w == selected);
    unsigned s = stage[w];
    if (s == 0) {
#if YOLO32_WAIT_REUSE
        assert(!yolo32_independent_try_reuse_wait(s)); /* No old-frame proof. */
#endif
#if YOLO32_CREDIT_LIMIT
        /* Fill the budget while accepted/retired lag CPU issue. */
        for (unsigned i = 0; i < 6; ++i) {
            yolo32_independent_admit_conv();
#endif
        ++submitted[w];
        yolo32_independent_command_return(15);
        assert(w == selected);
#if YOLO32_CREDIT_LIMIT
        }
#endif
    }
#if YOLO32_MEMORY_OPS
    if (s == 2) {
        yolo32_independent_memory_submit();
        assert(!yolo32_independent_try_reuse_wait(s));
    }
#endif
    static const unsigned head_stage[6] = {124,147,164,123,146,163};
    for (unsigned h = 0; h < 6; ++h) if (s == head_stage[h]) {
#if YOLO32_CREDIT_LIMIT
        yolo32_independent_admit_conv();
#endif
        ++submitted[w];
        yolo32_independent_arm_tail_wait(15);
        yolo32_independent_command_return(15);
        yolo32_independent_wait();
        assert(w == selected && retired[w] == submitted[w]);
#if YOLO32_WAIT_REUSE
        assert(yolo32_independent_try_reuse_wait(s));
#endif
        yolo32_independent_head_ready(w, h);
        heads[w] |= 1U << h;
    }
    stage[w] = s + 1;
    if (s == 165) {
        yolo32_independent_wait();
        return YOLOV5NU_DIM16_HEAD_READY;
    }
    /* A CPU-only stage must return even when no peer is runnable. */
    tick += 250;
    return YOLOV5NU_DIM16_RUNNING;
}
static void start(unsigned w) {
    yolo32_independent_live_start(w);
    stage[w] = heads[w] = publications[w] = 0;
    ++starts[w];
}
static void finish(unsigned mask) {
    for (unsigned i = 0; i < 10000; ++i) {
        (void)yolo32_independent_step();
        if ((yolo32_independent_stats()->done_mask & mask) == mask) return;
    }
    assert(!"scheduler failed to finish");
}
int main(void) {
    for (unsigned w = 0; w < 3; ++w) submitted[w] = retired[w] = UINT32_MAX - 2;
    yolo32_independent_live_init();
    assert(yolo32_independent_step() == 0);
    start(2); /* Worker 0/1 absent; do not require a three-frame batch. */
#if YOLO32_CREDIT_LIMIT
    allow_entry[2] = 0;
    for (unsigned i = 0; i < 20; ++i) yolo32_independent_step();
    assert(submitted[2] == baseline[2]); /* Fresh inlet permission required. */
    allow_entry[2] = 1;
    for (unsigned i = 0; i < 1000; ++i) yolo32_independent_step();
    assert(stage[2] == 0 && submitted[2] - retired[2] == YOLO32_CREDIT_LIMIT);
    assert(yolo32_independent_stats()->credit_max_pending[2] == YOLO32_CREDIT_LIMIT);
#else
    for (unsigned i = 0; i < 1000 && stage[2] < 123; ++i) yolo32_independent_step();
    assert(stage[2] == 123 && heads[2] == 0);
#endif
    uint64_t before = tick;
    for (unsigned i = 0; i < 5; ++i) yolo32_independent_step();
    assert(tick - before < 100); /* All WAITING returns to the video loop. */
    start(0); allow_retire[0] = 1; finish(1);
    assert(publications[0] == 63 && publications[2] == 0);
    assert(yolo32_independent_finished(0));
    unsigned suspended = stage[2];
    yolo32_independent_live_release(0);
    new_flush[0] = 1; /* New-frame initialization must not recheck old proof. */
    start(0); assert(stage[2] == suspended); /* Reuse only one producer. */
    new_flush[0] = 0;
    assert(yolo32_independent_stats()->head_produced_mask[0] == 0);
    start(1); allow_retire[1] = allow_retire[2] = 1; finish(7);
    for (unsigned w = 0; w < 3; ++w) {
        assert(publications[w] == 63 && yolo32_independent_finished(w));
        const Yolo32IndependentStats *stats = yolo32_independent_stats();
        assert(stats->conv_requests[w] == (YOLO32_CREDIT_LIMIT ? 12 : 7));
#if YOLO32_CREDIT_LIMIT
        assert(stats->credit_admitted[w] == stats->conv_requests[w]);
        assert(stats->credit_max_pending[w] <= YOLO32_CREDIT_LIMIT);
        assert(stats->credit_yields[w] == stats->credit_resumes[w]);
#endif
    }
    tick += UINT64_C(1000000000); /* Persistent idle pool has no batch timeout. */
    yolo32_independent_step();
    yolo32_independent_live_release(1);
    start(1); finish(7); assert(starts[1] == 2);
    puts("PASS: sparse workers, bounded idle return, local head proof, wraparound, independent reuse and long idle");
    return 0;
}
