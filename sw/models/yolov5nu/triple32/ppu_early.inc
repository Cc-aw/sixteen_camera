/* Software-only PPU overlap. Included into ppu.c; the production queue,
 * publication clean and result freshness checks retain ownership. */
static unsigned early_enabled, early_analysis;
static uint64_t early_base;
static Yolo32PpuEarlyStats early;
static unsigned progress_seen[3], previous_positions[3];
#if YOLO32_PPU_HEAD_CLEAN
static Yolo32PpuHeadStats head_stats;
static unsigned head_finished_mask;
#endif

static unsigned early_graph_mask(void) {
    return yolo32_independent_enabled ? yolo32_independent_stats()->done_mask : 7U;
}

/* This SoC has one outstanding uncached CPU transaction. The read response
 * follows prior PPU write responses, without Rocket's global RoCC fence.
 * Data coherence is provided separately by local DMA completion and hardware
 * Flush64 publication, never by this read. No task can yield in this function. */
__attribute__((noinline)) static void early_io_commit(void) {
    __asm__ volatile("" ::: "memory");
    if (get(0x1a0)!=UINT32_C(0x50505532)) yolo32_fail("ppu_io_commit");
    __asm__ volatile("" ::: "memory");
}
void yolo32_ppu_io_barrier(void) {
    if (early_enabled && yolo32_independent_enabled) early_io_commit();
    else __asm__ volatile("fence" ::: "memory");
}

void yolo32_ppu_early_begin(uint64_t batch_start, unsigned analysis) {
    if (yolo32_independent_enabled) yolo32_fail("ppu_early_nested");
    memset(&early,0,sizeof(early));
    memset(progress_seen,0,sizeof(progress_seen));
    memset(previous_positions,0,sizeof(previous_positions));
    early_base=batch_start; early_analysis=analysis; early_enabled=1;
#if YOLO32_PPU_HEAD_CLEAN
    memset(&head_stats,0,sizeof(head_stats));head_finished_mask=0;
#endif
}

#if !YOLO32_PPU_HEAD_CLEAN
static void early_publication_commit(unsigned w, const AiHeadSlot *slot) {
    if (early.published_mask & (1U<<w)) yolo32_fail("ppu_duplicate_publication");
    uint32_t generation=ai_ppu_publication_generation(slot->descriptor.base_addr);
    uint64_t start=read_cycle();
    /* The producer latch can lag the AXI write response by a clock. Poll the
     * publication receipt, not ready_heads or the long-running cache clean. */
    for (;;) {
        if (get(0x1bc)!=generation || (get(0x1b4)&5U)!=1U)
            yolo32_fail("ppu_publication_metadata");
        if (((get(0x1b8)>>8)&63U)==63U) break;
        if (read_cycle()-start>UINT64_C(1000000)) yolo32_fail("ppu_publication_commit_timeout");
    }
    early.workers[w].publication_cycle=read_cycle();
    early.published_mask |= 1U<<w;
}
#else
#include "ppu_head_clean.inc"
#endif

static void early_sample_progress(void) {
    unsigned mask=early_graph_mask();
    if (!early_analysis || mask==7U || !early.enqueued_mask || !(get(0x208)&64U)) return;
    uint32_t tag=get(0x224), version=get(0x230);
    uint64_t frame=get_frame(0x228);
    unsigned w=tag&15U;
    if (w>=3 || !(early.enqueued_mask&(1U<<w)) || (early.result_mask&(1U<<w))) return;
    const AiHeadSlot *slot=ai_head_slot_get(&queue,keys[w]);
    if (!slot || ((tag>>4)&7U)!=keys[w] || version!=slot->descriptor.version ||
        frame!=slot->descriptor.frame_id) return;
    unsigned positions=get(0x138);
    /* Recheck identity. Active registers may advance between CSR reads. */
    if (tag!=get(0x224) || version!=get(0x230) || frame!=get_frame(0x228) || positions>6300U) return;
    /* A new descriptor can retain the preceding core's final counters while
     * WAIT_READY. Only an increase across samples proves processing. */
    if (progress_seen[w] && positions>previous_positions[w] && !(early.progress_mask&(1U<<w))) {
        early.workers[w].progress_cycle=read_cycle();
        early.workers[w].progress_done_mask=mask;
        early.progress_mask |= 1U<<w;
    }
    progress_seen[w]=1; previous_positions[w]=positions;
}

void yolo32_ppu_early_service(void) {
    if (!early_enabled || !yolo32_independent_enabled) yolo32_fail("ppu_early_not_started");
    uint64_t start=early_analysis ? read_cycle() : 0;
    ++early.service_calls;
    const Yolo32IndependentStats *s=yolo32_independent_stats();
#if YOLO32_PPU_HEAD_CLEAN
    head_publish_pending(s);
    unsigned pending=s->done_mask & ~head_finished_mask;
#else
    unsigned pending=s->done_mask & ~early.published_mask;
#endif
    for (unsigned w=0; w<3; ++w) if (pending&(1U<<w)) {
        if (!yolo32_independent_finished(w)) yolo32_fail("ppu_producer_incomplete");
        if (!s->graph_done_cycle[w] || s->graph_done_cycle[w]<early_base)
            yolo32_fail("ppu_graph_done_timestamp");
        early.workers[w].graph_done_cycle=s->graph_done_cycle[w];
        yolo32_ppu_graph_done(w);
#if YOLO32_PPU_HEAD_CLEAN
        head_finished_mask |= 1U<<w;
#endif
    }
#if YOLO32_PPU_HEAD_CLEAN
    if (early_analysis) head_sample_ready();
    if (early.enqueued_mask || queue.ready_count) yolo32_ppu_service();
#else
    yolo32_ppu_service();
#endif
    early_sample_progress();
    if (early_analysis) early.service_cycles+=read_cycle()-start;
}
const Yolo32PpuEarlyStats *yolo32_ppu_early_stats(void) {
    if (early.published_mask!=7U || early.enqueued_mask!=7U || early.result_mask!=7U)
        yolo32_fail("ppu_early_incomplete");
    return &early;
}
