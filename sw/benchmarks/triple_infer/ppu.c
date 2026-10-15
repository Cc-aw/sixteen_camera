/* Reuse production URAM publication, ping-pong slots and PPU queue drivers.
 * No CPU classification, DFL, decode, NMS, or software fallback. */
#include <string.h>
#include "ppu.h"
#include "yolo32.h"
#include "mmio.h"
#include "platform.h"
#include "console.h"
#include "ai/postprocess/ai_ppu_publication.h"
#include "ai/postprocess/ai_ppu_queue.h"
#include "ai/runtime/ai_head_slot_queue.h"

static AiHeadSlotQueue queue;
static uint32_t keys[3];
static uint64_t admitted[3];
static unsigned done[3];
static Yolo32PpuResult results[3];
static uint64_t frame_base;
static uint32_t get(uint32_t offset) { return mmio_read32(POSTPROCESS_DIAG_BASE+offset); }
static void put(uint32_t offset, uint32_t value) { mmio_write32(POSTPROCESS_DIAG_BASE+offset,value); }
static uint64_t get_frame(uint32_t low) {
    uint32_t high, next, value;
    do { high=get(low+4); value=get(low); next=get(low+4); } while (high!=next);
    return ((uint64_t)high<<32)|value;
}
#if defined(YOLO32_PPU_EARLY) && YOLO32_PPU_EARLY
#include "independent.h"
#include "ppu_early.inc"
#endif
static void field(const char *name, uint64_t value) {
    console_putc(' '); console_puts(name); console_putc('='); console_put_hex64(value);
}
static void report_result_error(const AiPpuQueueResult *r, const AiHeadSlot *slot) {
    console_puts("YOLO32_PPU_ERROR");
    field("status",r->status); field("engine_error",r->status&1U);
    field("stale_flag",(r->status>>1)&1U);
    field("bank",r->bank); field("stream",r->stream); field("frame",r->frame);
    field("version",r->version); field("generation",r->generation);
    if (slot) {
        field("expected_stream",slot->descriptor.stream_id);
        field("expected_frame",slot->descriptor.frame_id);
        field("expected_version",slot->descriptor.version);
        field("expected_generation",ai_ppu_publication_generation(slot->descriptor.base_addr));
    }
    field("engine_status",get(0x11c)); field("reader_status",get(0x148));
    field("queue_status",get(0x208)); field("result_status",get(0x240));
    field("stale_count",get(0x270)); console_puts("\r\n");
}

void yolo32_ppu_init(void) {
    if (get(0x100) != UINT32_C(0x50505531) || !ai_ppu_publication_available() ||
        !ai_ppu_queue_init()) yolo32_fail("hardware_ppu_missing");
    put(0x148,1U); /* Production local URAM head reader. */
    if (!(get(0x148)&1U)) yolo32_fail("ppu_local_reader");
    /* Result-manager expectations survive software reloads. Starting frame 1
     * again cannot replace an older firmware's larger latest_frame. Continue
     * beyond retained descriptor/observation IDs without weakening freshness. */
    uint64_t configured=get_frame(0x210), active=get_frame(0x228);
    frame_base=read_cycle();
    if (configured>frame_base) frame_base=configured;
    if (active>frame_base) frame_base=active;
    AiPpuQueueResult stale;
    for (unsigned i=0; i<16 && ai_ppu_queue_peek(&stale); ++i) {
        if (stale.frame>frame_base) frame_base=stale.frame;
        ai_ppu_queue_pop();
    }
    if (ai_ppu_queue_peek(&stale)) yolo32_fail("ppu_stale_queue");
    /* Enable CPU observation of completed hardware records, not CPU math. */
    put(0x24c,0U);
    ai_head_slot_queue_init(&queue,3);
    for (unsigned w=0; w<3; ++w) keys[w]=AI_HEAD_SLOT_INVALID;
    console_puts("YOLO32_PPU_SESSION"); field("frame_base",frame_base);
    field("retained_frame",configured); console_puts("\r\n");
}
uintptr_t yolo32_ppu_begin(unsigned w, uint64_t run) {
#if defined(YOLO32_PPU_EARLY) && YOLO32_PPU_EARLY
    if (yolo32_independent_enabled) yolo32_fail("ppu_begin_during_graph");
    early_enabled=0;
#endif
    AiModelFrameRequest request = {0};
    request.job_id=run*3+w; request.worker_id=w; request.stream_id=w;
    if (run>UINT64_MAX-frame_base) yolo32_fail("ppu_frame_overflow");
    request.frame_id=frame_base+run; request.version=(uint32_t)run;
    uintptr_t base=AI_MODEL_OUTPUT0_PHYS_BASE+w*AI_MODEL_OUTPUT_ARENA_BYTES;
    if (w>=3 || ai_head_slot_acquire(&queue,w,base,&request,&keys[w])) yolo32_fail("ppu_slot_acquire");
    AiHeadSlot *slot=ai_head_slot_get(&queue,keys[w]);
    if (ai_ppu_publication_begin(slot->descriptor.base_addr)!=1) yolo32_fail("ppu_publication_begin");
    ai_ppu_queue_expect(w,request.frame_id,request.version);
    done[w]=0; admitted[w]=0; memset(&results[w],0,sizeof(results[w]));
    return AI_DDR_CPU_ALIAS(slot->descriptor.base_addr);
}
void yolo32_ppu_head(unsigned w, unsigned head) {
    if (w>=3 || head>=6) yolo32_fail("ppu_head_id");
    AiHeadSlot *slot=ai_head_slot_get(&queue,keys[w]);
    if (!slot) yolo32_fail("ppu_head_slot");
    ai_ppu_publication_publish(slot->descriptor.base_addr,1U<<head);
    if (head==0 && slot->state==AI_HEAD_SLOT_WRITING) {
        admitted[w]=read_cycle();
        if (ai_head_slot_admit(&queue,keys[w])) yolo32_fail("ppu_admit");
    }
    yolo32_ppu_service();
}
void yolo32_ppu_graph_done(unsigned w) {
    AiHeadSlot *slot=ai_head_slot_get(&queue,keys[w]);
#if defined(YOLO32_PPU_EARLY) && YOLO32_PPU_EARLY
    if (early_enabled && slot && slot->state==AI_HEAD_SLOT_WRITING) admitted[w]=read_cycle();
#endif
    if (!slot || ai_head_slot_publish(&queue,keys[w])) yolo32_fail("ppu_graph_publish");
#if defined(YOLO32_PPU_HEAD_CLEAN) && YOLO32_PPU_HEAD_CLEAN
    if (early_enabled) head_graph_snapshot(w);
    else ai_ppu_publication_publish(slot->descriptor.base_addr,63U);
#else
    ai_ppu_publication_publish(slot->descriptor.base_addr,63U);
#endif
#if defined(YOLO32_PPU_EARLY) && YOLO32_PPU_EARLY
#if !YOLO32_PPU_HEAD_CLEAN
    if (early_enabled) early_publication_commit(w,slot);
#endif
#endif
    yolo32_finish_hardware(w);
    yolo32_ppu_service();
}
void yolo32_ppu_service(void) {
    AiPpuQueueResult r;
    if (ai_ppu_queue_peek(&r)) {
        AiHeadSlot *slot=ai_head_slot_get(&queue,r.bank);
        if (!slot || slot->state!=AI_HEAD_SLOT_PROCESSING || r.stream>=3 || r.count>10 ||
            r.stream!=slot->descriptor.stream_id || r.frame!=slot->descriptor.frame_id ||
            r.version!=slot->descriptor.version ||
            r.generation!=ai_ppu_publication_generation(slot->descriptor.base_addr)) {
            report_result_error(&r,slot); yolo32_fail("ppu_result_metadata");
        }
        if (r.status) {
            report_result_error(&r,slot); yolo32_fail("ppu_result_error_or_stale");
        }
        if (slot->producer_complete) {
            unsigned w=slot->descriptor.worker_id;
            if (done[w]) yolo32_fail("ppu_duplicate_result");
            results[w].count=r.count; results[w].core_cycles=r.cycles;
            /* CSR 0x248 reads one selected 32-bit word of the captured record.
             * Read all ten detection slots before popping this completion. */
            for (unsigned i=0; i<10; ++i) for (unsigned j=0; j<4; ++j) {
                put(0x244,i*4+j); results[w].words[i][j]=get(0x248);
            }
            results[w].completed_cycle=read_cycle();
            results[w].wall_cycles=results[w].completed_cycle-admitted[w];
            done[w]=1;
#if defined(YOLO32_PPU_EARLY) && YOLO32_PPU_EARLY
            if (early_enabled) {
                early.workers[w].result_cycle=results[w].completed_cycle;
                early.workers[w].result_done_mask=early_graph_mask();
                early.result_mask |= 1U<<w;
            }
#endif
            ai_ppu_queue_pop(); queue.active=r.bank;
            if (ai_head_slot_complete(&queue,0)) yolo32_fail("ppu_complete");
        }
    }
    while (queue.ready_count && ai_ppu_queue_ready()) {
        AiHeadSlot *slot;
        if (ai_head_slot_start_next(&queue,&slot)!=1 || ai_ppu_queue_submit(&slot->descriptor)!=1)
            yolo32_fail("ppu_submit");
#if defined(YOLO32_PPU_EARLY) && YOLO32_PPU_EARLY
        if (early_enabled) {
            unsigned w=slot->descriptor.worker_id;
            if (early.enqueued_mask & (1U<<w)) yolo32_fail("ppu_duplicate_submit");
            /* Side-effect-free read waits for the doorbell write response on
             * this platform's single outstanding uncached CPU MMIO path. */
            if (get(0x204)!=UINT32_C(0x50505132)) yolo32_fail("ppu_doorbell_commit");
            early.workers[w].enqueue_cycle=read_cycle();
            early.workers[w].enqueue_done_mask=early_graph_mask();
            early.enqueued_mask |= 1U<<w;
        }
#endif
        queue.active=AI_HEAD_SLOT_INVALID;
    }
}
unsigned yolo32_ppu_done(unsigned w) { return w<3 && done[w]; }
const Yolo32PpuResult *yolo32_ppu_result(unsigned w) { return &results[w]; }
