#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ai/backend/ai_model_backend.h"
#include "ai/postprocess/ai_detection.h"
#include "platform/platform.h"
#include "yolo32.h"
#include "independent.h"

uint64_t test_cycle;
unsigned yolo32_independent_enabled;
static Yolo32IndependentStats stats;
static uint32_t regs[256], bank, allocated[6], generation[6], published[6];
static unsigned idle[3], drive_worker, drive_head, drive_done, queued;
static unsigned live_owned[3];
static struct { unsigned bank, generation, stream, version; uint64_t frame; } commands[16];
void console_puts(const char *s) { (void)s; }
void console_putc(char c) { (void)c; }
void console_put_u32(uint32_t n) { (void)n; }
void console_put_hex32(uint32_t n) { (void)n; }
void console_put_hex64(uint64_t n) { (void)n; }
void test_wfi(void) { abort(); }
void cache_flush_range(const void *p, size_t n) { (void)p; (void)n; abort(); }
void mmio_fence(void) { abort(); } /* Live PPU drivers must use the read barrier. */
uint32_t mmio_read32(uintptr_t addr) {
    unsigned o = (unsigned)(addr - POSTPROCESS_DIAG_BASE);
    assert(o < sizeof(regs));
    switch (o) {
    case 0x100: return 0x50505531;
    case 0x1a0: return 0x50505532;
    case 0x238: return 0x50505232;
    case 0x208: return 32;
    case 0x1b4: return allocated[bank];
    case 0x1bc: return generation[bank];
    case 0x1b8: return published[bank] << 8;
    default: return regs[o / 4];
    }
}
void mmio_write32(uintptr_t addr, uint32_t v) {
    unsigned o = (unsigned)(addr - POSTPROCESS_DIAG_BASE);
    assert(o < sizeof(regs)); regs[o / 4] = v;
    if (o == 0x1a8) { assert(v < 6); bank = v; }
    if (o == 0x1b0 && v == 1) {
        assert(!allocated[bank]); allocated[bank] = 1;
        generation[bank] = regs[0x1ac / 4]; published[bank] = 0;
    }
    if (o == 0x1b0 && (v & 0x3f00)) published[bank] |= (v >> 8) & 63;
    if (o == 0x204 && v == 1) {
        assert(queued < 16 && allocated[bank] && published[bank] == 63);
        unsigned w = bank / 2;
        assert(stats.done_mask & (1U << w)); /* A admission requires graph completion. */
        commands[queued].bank = bank;
        commands[queued].generation = generation[bank];
        commands[queued].stream = regs[0x20c / 4];
        commands[queued].version = regs[0x218 / 4];
        commands[queued].frame = ((uint64_t)regs[0x214 / 4] << 32) | regs[0x210 / 4];
        ++queued;
    }
    if (o == 0x24c && v == 1) regs[0x240 / 4] = 0;
}
void yolov5nu_dim16_dual_init(void) { for (unsigned w = 0; w < 3; ++w) idle[w] = 1; }
void yolov5nu_dim16_set_head_callback(void (*f)(unsigned, unsigned)) { (void)f; }
int yolov5nu_dim16_worker_is_idle(uint32_t w) { return idle[w]; }
int yolov5nu_dim16_worker_start(uint32_t w, const int8_t *p) { assert(p && idle[w] && !live_owned[w]); idle[w] = 0; return 0; }
void yolov5nu_dim16_worker_set_head_slot(uint32_t w, uintptr_t p) { assert(w < 3 && p); }
void yolov5nu_dim16_worker_use_hardware(uint32_t w, int enable) { assert(w < 3 && enable); }
void yolov5nu_dim16_worker_finish_hardware(uint32_t w) { assert(!idle[w]); idle[w] = 1; }
uint32_t yolov5nu_dim16_worker_stage(uint32_t w) { return idle[w] ? 0 : 124; }
int yolov5nu_dim16_worker_get_profile(uint32_t w, struct yolov5nu_dim16_profile *p) { (void)w; memset(p, 0, sizeof(*p)); return 0; }
void yolo32_independent_live_init(void) { yolo32_independent_enabled = 1; memset(&stats, 0, sizeof(stats)); }
void yolo32_independent_live_start(unsigned w) { assert(!live_owned[w]); live_owned[w] = 1; stats.done_mask &= ~(1U << w); stats.head_produced_mask[w] = 0; }
void yolo32_independent_live_release(unsigned w) { assert(live_owned[w] && (stats.done_mask & (1U << w))); live_owned[w] = 0; }
const Yolo32IndependentStats *yolo32_independent_stats(void) { return &stats; }
unsigned yolo32_independent_head_mask(unsigned w) { return stats.head_produced_mask[w]; }
unsigned yolo32_independent_finished(unsigned w) { return (stats.done_mask >> w) & 1; }
int yolo32_independent_step(void) {
    if (drive_worker < 3) {
        unsigned w = drive_worker;
        if (drive_head < 6) {
            stats.head_produced_mask[w] |= 1U << drive_head;
            stats.head_completed_cycle[w][drive_head] = ++test_cycle;
            stats.head_requests[w][drive_head] = drive_head + 1;
        }
        if (drive_done) stats.done_mask |= 1U << w;
    }
    return 0;
}
static AiModelFrameRequest request(unsigned w, unsigned frame) {
    AiModelFrameRequest r = {0};
    r.worker_id = w; r.stream_id = w + 4; r.job_id = frame * 3 + w;
    r.frame_id = frame; r.version = frame; r.timestamp = frame;
    r.input_addr = 0x08000000; r.input_bytes = AI_YOLOV5NU_INPUT_BYTES;
    r.output_addr = AI_MODEL_OUTPUT0_PHYS_BASE + w * AI_MODEL_OUTPUT_ARENA_BYTES;
    r.output_bytes = AI_MODEL_OUTPUT_ARENA_BYTES;
    return r;
}
static void graph(unsigned w) {
    AiModelComputeCompletion c;
    drive_worker = w; drive_done = 0;
    unsigned prior = queued;
    for (drive_head = 0; drive_head < 6; ++drive_head) {
        assert(ai_model_backend_poll_compute(w, &c) == 0);
        assert(queued == prior);
    }
    drive_done = 1;
    assert(ai_model_backend_poll_compute(w, &c) == 1);
    assert(c.worker_id == w && c.frame_id && queued == prior + 1);
    drive_worker = 3; drive_done = 0;
}
static void result(unsigned i) {
    unsigned b = commands[i].bank;
    allocated[b] = 0;
    regs[0x240 / 4] = 1; regs[0x250 / 4] = b;
    regs[0x254 / 4] = 2 | (commands[i].stream << 10);
    regs[0x258 / 4] = (uint32_t)commands[i].frame;
    regs[0x25c / 4] = (uint32_t)(commands[i].frame >> 32);
    regs[0x260 / 4] = commands[i].version;
    regs[0x268 / 4] = commands[i].generation;
    AiModelFrameCompletion c;
    assert(ai_model_backend_poll_result(&c) == 1);
    assert(c.worker_id == b / 2 && c.frame_id == commands[i].frame);
    assert(c.stream_id == commands[i].stream && c.version == commands[i].version);
    const AiDetectionResult *r = (const AiDetectionResult *)c.output_addr;
    assert(r->count == 2 && (r->flags & AI_RESULT_METADATA_ONLY));
    assert(regs[0x240 / 4] == 0);
}
int main(void) {
    drive_worker = 3;
    ai_model_backend_init();
    assert(ai_model_backend_is_idle());
    for (unsigned w = 0; w < 3; ++w) { AiModelFrameRequest r = request(w, 1); assert(!ai_model_backend_submit(&r)); }
    graph(2); graph(0); graph(1);
    assert(queued == 3 && !ai_model_backend_is_idle());
    for (unsigned w = 0; w < 3; ++w) { AiModelFrameRequest r = request(w, 2); assert(!ai_model_backend_submit(&r)); graph(w); }
    AiModelFrameRequest r = request(2, 3);
    assert(ai_model_backend_submit(&r) == -3); /* Both Head slots still owned by PPU. */
#if defined(R2_STOP_PROOF) || defined(AI_BACKEND_RESOURCE_TEST)
    AiModelResourceSnapshot ownership;
    ai_model_backend_get_resources(&ownership);
    assert(ownership.owned_head == 63 && !ownership.activation_held);
    for (unsigned key = 0; key < 6; ++key) {
        assert(ownership.heads[key].identity.worker_id == key / 2);
        assert(ownership.heads[key].producer_complete && ownership.heads[key].producer_mask == 63);
    }
#endif
    result(0); /* Worker 2 first slot releases, second remains owned. */
    assert(!ai_model_backend_submit(&r)); graph(2);
    assert(commands[6].bank == commands[0].bank);
    assert(commands[6].generation == commands[0].generation + 1);
    for (unsigned i = 1; i < 7; ++i) result(i);
    assert(ai_model_backend_is_idle());
#if defined(R2_STOP_PROOF) || defined(AI_BACKEND_RESOURCE_TEST)
    ai_model_backend_get_resources(&ownership);
    assert(!ownership.owned_head && !ownership.activation_held && !ownership.unsafe_fault);
#endif
    puts("PASS: V17 A head publication/admission, independent compute release, six-slot backpressure, generation reuse and queued metadata");
    return 0;
}

uintptr_t yolov5nu_dim16_worker_arena(uint32_t worker) { return UINT32_C(0x40000000) + worker * UINT32_C(0x01000000); }
