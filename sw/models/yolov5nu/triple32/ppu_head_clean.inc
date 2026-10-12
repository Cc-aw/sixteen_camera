/* Included by ppu_early.inc: publish immutable heads without occupying the
 * hardware command queue. Head0 admission is a separate A/B build option. */
static uint32_t head_state(unsigned w, unsigned *allocated) {
    const AiHeadSlot *slot=ai_head_slot_get(&queue,keys[w]);
    if (!slot || ai_ppu_publication_select(slot->descriptor.base_addr)!=1)
        yolo32_fail("ppu_head_select");
    early_io_commit();
    uint32_t status=get(0x1b4);
    if (get(0x1bc)!=ai_ppu_publication_generation(slot->descriptor.base_addr) || (status&4U))
        yolo32_fail("ppu_publication_metadata");
    *allocated=status&1U;
    /* Hardware can retire before CPU result service; in B even before
     * FINISHED. Only our fully published, admitted descriptor may release. */
    if (!*allocated && (head_stats.published_heads[w]!=63U ||
                        !(early.enqueued_mask&(1U<<w))))
        yolo32_fail("ppu_head_ownership");
    return get(0x1b8);
}

static void head_record_ready(unsigned w, unsigned ready) {
    for (unsigned h=0;h<6;++h) if ((ready&(1U<<h)) && !head_stats.heads[w][h].ready_cycle)
        head_stats.heads[w][h].ready_cycle=read_cycle();
}

static void head_publish_pending(const Yolo32IndependentStats *s) {
    for (unsigned w=0;w<3;++w) {
        unsigned delta=s->head_produced_mask[w] & ~head_stats.published_heads[w];
        if (!delta) continue;
        if ((delta & ~yolo32_independent_head_mask(w)) || (s->head_produced_mask[w]&~63U))
            yolo32_fail("ppu_head_event_mask");
        AiHeadSlot *slot=ai_head_slot_get(&queue,keys[w]);
        if (!slot || slot->producer_complete || slot->state==AI_HEAD_SLOT_FREE)
            yolo32_fail("ppu_head_slot_state");
        unsigned cumulative=head_stats.published_heads[w]|delta;
        for (unsigned h=0;h<6;++h) if (delta&(1U<<h)) {
            uint64_t c=s->head_completed_cycle[w][h];
            if (!c || c<early_base || !s->head_requests[w][h]) yolo32_fail("ppu_head_event_proof");
            head_stats.heads[w][h].completed_cycle=c;
            head_stats.heads[w][h].requests=s->head_requests[w][h];
        }
        ai_ppu_publication_publish(slot->descriptor.base_addr,delta);
        ++head_stats.publication_transactions;
        uint64_t start=read_cycle();
        for (;;) {
            unsigned allocated;
            /* This selection is already committed by the driver's ordering
             * hook. Do not repeat writes on every acknowledgement poll. */
            uint32_t status=get(0x1b4), generation=get(0x1bc), masks=get(0x1b8);
            if (generation!=ai_ppu_publication_generation(slot->descriptor.base_addr) || (status&4U))
                yolo32_fail("ppu_publication_metadata");
            allocated=status&1U;
            if (allocated && ((masks>>8)&63U)==cumulative) break;
            if (!allocated) {
                /* Completion/RELEASE requires all six ready bits. A fast B
                 * command may retire before the final producer CSR read. */
                if (!YOLO32_PPU_HEAD_ADMIT || cumulative!=63U || !(early.enqueued_mask&(1U<<w)))
                    yolo32_fail("ppu_head_ownership");
                break;
            }
            if (read_cycle()-start>UINT64_C(1000000)) yolo32_fail("ppu_publication_commit_timeout");
        }
        uint64_t committed=read_cycle();
        for (unsigned h=0;h<6;++h) if (delta&(1U<<h)) head_stats.heads[w][h].publication_cycle=committed;
        head_stats.published_heads[w]=cumulative;
        if (cumulative==63U) {
            early.published_mask |= 1U<<w;
            early.workers[w].publication_cycle=committed;
        }
        if (YOLO32_PPU_HEAD_ADMIT && (cumulative&1U) && slot->state==AI_HEAD_SLOT_WRITING) {
            admitted[w]=read_cycle();
            if (ai_head_slot_admit(&queue,keys[w])) yolo32_fail("ppu_admit");
        }
    }
}

static void head_sample_ready(void) {
    for (unsigned w=0;w<3;++w) if (head_stats.published_heads[w] && !(early.result_mask&(1U<<w))) {
        unsigned allocated;uint32_t masks=head_state(w,&allocated);
        if (allocated) head_record_ready(w,masks&63U);
    }
}

static void head_graph_snapshot(unsigned w) {
    if (head_stats.published_heads[w]!=63U || !(early.published_mask&(1U<<w)))
        yolo32_fail("ppu_unpublished_heads");
    unsigned allocated;uint32_t masks=head_state(w,&allocated);
    head_stats.ready_at_finish[w]=masks&63U;
    head_stats.allocated_at_finish[w]=allocated;
    head_stats.finish_sample_cycle[w]=read_cycle();
    if (early_analysis && allocated) head_record_ready(w,masks&63U);
}

const Yolo32PpuHeadStats *yolo32_ppu_head_stats(void) {
    if (head_finished_mask!=7U || early.published_mask!=7U) yolo32_fail("ppu_heads_incomplete");
    return &head_stats;
}
