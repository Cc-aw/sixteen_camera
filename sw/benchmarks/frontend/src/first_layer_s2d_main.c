/* Isolated first-convolution experiment; no production graph or Head changes. */
#include <stdint.h>
#include <stddef.h>
#include <string.h>
#include "config.h"
#include "gemmini_frontend.h"
#include "first_layer_s2d.h"
#include "inputs.h"

enum { LANES = 3, ROUNDS = 4, INPUT_BYTES = 480 * 640 * 3,
       OUTPUT_BYTES = 240 * 320 * 16, TABLE_CAPACITY = 564, EVICT_BYTES = 4 * 1024 * 1024 };
struct S2dPacket { uint64_t geometry[6], offsets[4], launch[2]; };
struct S2dPlan { uint64_t config[6]; unsigned count; const struct S2dPacket *packets; };
#include "first_layer_s2d_data.inc"

struct InputBuffer { uint8_t before[64]; int8_t data[INPUT_BYTES]; uint8_t after[64]; };
struct OutputBuffer { uint8_t before[64]; int8_t data[OUTPUT_BYTES]; uint8_t after[64]; };
static struct InputBuffer packed[LANES] __attribute__((aligned(64)));
static int8_t scalar_packed[LANES][INPUT_BYTES] __attribute__((aligned(64)));
static struct OutputBuffer gold[LANES], outputs[LANES] __attribute__((aligned(64)));
static uint8_t eviction[EVICT_BYTES] __attribute__((aligned(64)));
static volatile uint64_t eviction_sink;
static GfCommand tables[2][LANES][TABLE_CAPACITY] __attribute__((aligned(64)));
static unsigned table_count[2][LANES], current_round, current_profile, current_job;
static const char *const profile_names[3] = {"reference", "prepacked", "rvv_online"};
static const unsigned counter_events[8] = {42, 24, 10, 14, 20, 29, 30, 31};
static const char *const counter_names[8] = {",rs_active=", ",exec_active=", ",load_req_wait=",
    ",store_req_wait=", ",rdma_tl_wait=", ",spad_a_wait=", ",spad_b_wait=", ",spad_d_wait="};
volatile unsigned irq_event;
volatile uint64_t irq_count, irq_cycles;

static uint64_t cycle(void) {
    uint64_t value;
    __asm__ volatile("rdcycle %0" : "=r"(value) :: "memory");
    return value;
}
static void text(const char *s) {
    volatile uint32_t *uart = (volatile uint32_t *)AT_UART_BASE;
    while (*s) {
        if (*s == '\n') { while (uart[0] & 0x80000000u) {} uart[0] = '\r'; }
        while (uart[0] & 0x80000000u) {}
        uart[0] = (unsigned char)*s++;
    }
}
static void field(const char *key, uint64_t value) {
    char buf[24]; unsigned n = sizeof(buf);
    buf[--n] = 0;
    do { buf[--n] = '0' + value % 10; value /= 10; } while (value);
    text(key); text(buf + n);
}
static void fail(const char *reason, uint64_t value) __attribute__((noreturn));
static void fail(const char *reason, uint64_t value) {
    text("S2D1,FAIL,reason="); text(reason); field(",value=", value);
    field(",round=", current_round); field(",profile=", current_profile); field(",job=", current_job); text("\n");
    for (;;) __asm__ volatile("nop");
}
void at_irq_fault(uint64_t cause, uint64_t pc, uint64_t val) {
    field("S2D1,TRAP,pc=", pc); field(",tval=", val); text("\n"); fail("trap", cause);
}
static void require(uint64_t rc, const char *reason) { if (rc) fail(reason, rc); }
static void compare(const int8_t *actual, const int8_t *expected, size_t count, const char *reason) {
    size_t errors = 0, first = 0;
    for (size_t i = 0; i < count; ++i)
        if (actual[i] != expected[i]) { if (!errors) first = i; ++errors; }
    if (errors) {
        field("S2D1,DIFF,offset=", first); field(",actual_u8=", (uint8_t)actual[first]);
        field(",expected_u8=", (uint8_t)expected[first]); field(",mismatches=", errors); text("\n");
        fail(reason, errors);
    }
}
static void guards(const uint8_t *before, const uint8_t *after) {
    for (unsigned i = 0; i < 64; ++i)
        if (before[i] != 0xc3 || after[i] != 0x3c) fail("buffer_guard", i);
}
static void evict(void) {
    /* Reproducible pressure larger than either supported L2. This is a sweep,
     * not an architectural guarantee that every line has become cold. */
    const volatile uint8_t *p = eviction;
    uint64_t sum = 0;
    for (size_t i = 0; i < sizeof(eviction); i += 64) sum += p[i];
    eviction_sink = sum;
    gf_publish();
}
static void lut(unsigned lane) {
    for (unsigned i = 0; i < 32; ++i) GF_DIRECT(lane, 26, (uint64_t)i * 8, first_lut[i]);
    gf_publish();
}
static uint32_t counter(unsigned lane, uint32_t config) {
    uint64_t out;
#define ACCESS(op) __asm__ volatile(".insn r " op ",7,126,%0,%1,x0" : "=&r"(out) : "r"((uint64_t)config) : "memory")
    switch (lane) {
        case 0: ACCESS("0x0b"); break;
        case 1: ACCESS("0x2b"); break;
        case 2: ACCESS("0x5b"); break;
        default: fail("counter_lane", lane);
    }
#undef ACCESS
    return (uint32_t)out;
}
static void counters_begin(void) {
    for (unsigned d = 0; d < LANES; ++d) {
        (void)counter(d, 1);
        for (unsigned i = 0; i < 8; ++i) (void)counter(d, (i << 4) | 8 | (counter_events[i] << 12));
    }
}
static void append(unsigned variant, unsigned job, GfCommand c) {
    unsigned *n = &table_count[variant][job];
    if (*n == TABLE_CAPACITY) fail("table_capacity", *n);
    tables[variant][job][(*n)++] = c;
}
static void build(unsigned variant, unsigned job, unsigned image, int8_t *output) {
    const struct S2dPlan *plan = variant ? &s2d_plan : &reference_plan;
    const int8_t *input = variant ? packed[image].data : yolo32_inputs[image];
    const int8_t *weights = variant ? s2d_weights : reference_weights;
    uintptr_t bases[4] = {(uintptr_t)weights, (uintptr_t)output, (uintptr_t)first_bias, (uintptr_t)input};
    table_count[variant][job] = 0;
    append(variant, job, gf_raw(0, plan->config[0], plan->config[1], 0));
    append(variant, job, gf_raw(0, plan->config[2], plan->config[3], 0));
    for (unsigned i = 0; i < plan->count; ++i) {
        const struct S2dPacket *p = plan->packets + i;
        append(variant, job, gf_raw(16, plan->config[4], plan->config[5], 0));
        for (unsigned k = 0; k < 3; ++k) append(variant, job, gf_raw(17 + k, p->geometry[2*k], p->geometry[2*k+1], 0));
        uint64_t address[4];
        for (unsigned k = 0; k < 4; ++k) address[k] = p->offsets[k] == UINT32_MAX ? 0 : bases[k] + p->offsets[k];
        append(variant, job, gf_raw(20, address[0], address[1], 0));
        append(variant, job, gf_raw(21, address[2], address[3], 0));
        append(variant, job, gf_raw(15, p->launch[0], p->launch[1], 0));
    }
    append(variant, job, gf_drain());
    if (table_count[variant][job] != 563) fail("table_shape", table_count[variant][job]);
}
static void launch(unsigned variant, unsigned job, unsigned lane) {
    require(gf_launch(lane, tables[variant][job], table_count[variant][job], 0, 50000000, 0), "launch");
}
static void wait_lanes(unsigned mask) {
    uint64_t begin = cycle();
    while (mask) {
        for (unsigned lane = 0; lane < LANES; ++lane) if (mask & (1U << lane)) {
            uint64_t status = gf_status(lane);
            if (status & GF_FAULT) fail("frontend_fault", status);
            if (status & GF_DONE) {
                require(gf_ack(lane, 0, 0), "ack");
                mask &= ~(1U << lane);
            }
        }
        if (cycle() - begin > 100000000) fail("completion_timeout", mask);
    }
    gf_publish();
}

static uint64_t run(unsigned profile, unsigned parallel, unsigned round, unsigned warmup) {
    current_profile = profile;
    for (unsigned job = 0; job < LANES; ++job) {
        unsigned image = (round + job) % LANES;
        memset(outputs[job].data, 0x5a, OUTPUT_BYTES);
        build(profile != 0, job, image, outputs[job].data);
        if (profile == 1) require(first_layer_s2d_rvv(yolo32_inputs[image], packed[image].data, 480, 640), "prepack");
    }
    evict();
    for (unsigned lane = 0; lane < LANES; ++lane) lut(lane);
    counters_begin();
    uint64_t pack_cycles = 0, begin = cycle();
    for (unsigned job = 0; job < LANES; ++job) {
        current_job = job;
        unsigned image = (round + job) % LANES;
        if (profile == 2) {
            uint64_t start = cycle();
            require(first_layer_s2d_rvv(yolo32_inputs[image], packed[image].data, 480, 640), "online_pack");
            gf_publish();
            pack_cycles += cycle() - start;
        }
        launch(profile != 0, job, parallel ? job : 0);
        if (!parallel) wait_lanes(1);
    }
    if (parallel) wait_lanes(7);
    uint64_t elapsed = cycle() - begin, counts[8] = {0};
    for (unsigned lane = 0; lane < LANES; ++lane) {
        (void)counter(lane, 4);
        for (unsigned i = 0; i < 8; ++i) counts[i] += counter(lane, i << 4);
    }
    if (!counts[0] || !counts[1]) fail("inactive_counters", counts[0]);
    for (unsigned job = 0; job < LANES; ++job) {
        current_job = job;
        unsigned image = (round + job) % LANES;
        guards(outputs[job].before, outputs[job].after);
        compare(outputs[job].data, gold[image].data, OUTPUT_BYTES, "output_mismatch");
        if (profile) {
            guards(packed[image].before, packed[image].after);
            compare(packed[image].data, scalar_packed[image], INPUT_BYTES, "pack_mismatch");
        }
    }
    text("S2D1,RESULT,profile="); text(profile_names[profile]); text(",executor="); text(parallel ? "parallel" : "serial");
    field(",round=", round); field(",warmup=", warmup); field(",batch_cycles=", elapsed); field(",pack_cycles=", pack_cycles);
    text(",frames=3,compared_bytes=3686400,bit_exact=1");
    for (unsigned i = 0; i < 8; ++i) field(counter_names[i], counts[i]);
    text("\n");
    return elapsed;
}

int main(void) {
    volatile uint32_t *uart = (volatile uint32_t *)AT_UART_BASE;
    uart[2] = 1; uart[4] = 0; uart[6] = 867;
    text("S2D1,BUILD,schema=1,rounds=4,profiles=3,executors=2,frames_per_batch=3,clock_hz=100000000,scope=first_conv,evict_bytes=4194304,prepacked_excludes_pack=1,online_includes_pack=1\n");
    uint64_t vlenb; __asm__ volatile("csrr %0,vlenb" : "=r"(vlenb));
    if (vlenb != 32) fail("rvv_vlenb", vlenb);
    for (unsigned lane = 0; lane < LANES; ++lane) {
        uint64_t status = gf_status(lane);
        if ((status >> 32) != 0x20000 || !(status & GF_START_READY) || (status & (GF_OWNED | GF_GEMMINI_BUSY)))
            fail("frontend_abi_or_busy", status);
        GF_DIRECT(lane, 7, UINT64_C(0), UINT64_C(0));
        gf_publish();
        lut(lane);
    }
    for (unsigned image = 0; image < LANES; ++image) {
        memset(packed[image].before, 0xc3, 64); memset(packed[image].after, 0x3c, 64);
        memset(gold[image].before, 0xc3, 64); memset(gold[image].after, 0x3c, 64);
        memset(outputs[image].before, 0xc3, 64); memset(outputs[image].after, 0x3c, 64);
        require(first_layer_s2d_scalar(yolo32_inputs[image], scalar_packed[image], 480, 640), "scalar_pack");
        memset(gold[image].data, 0xa5, OUTPUT_BYTES);
        build(0, image, image, gold[image].data);
        launch(0, image, 0); wait_lanes(1);
        guards(gold[image].before, gold[image].after);
    }
    uint64_t totals[3][2] = {{0}};
    for (unsigned iteration = 0; iteration <= ROUNDS; ++iteration) {
        unsigned warmup = iteration == 0;
        current_round = warmup ? 0 : iteration - 1;
        for (unsigned k = 0; k < 6; ++k) {
            unsigned index = iteration & 1 ? 5 - k : k;
            unsigned profile = index / 2, parallel = index % 2;
            uint64_t elapsed = run(profile, parallel, current_round, warmup);
            if (!warmup) totals[profile][parallel] += elapsed;
        }
    }
    for (unsigned p = 0; p < 3; ++p) {
        text("S2D1,SUMMARY,profile="); text(profile_names[p]);
        field(",serial_cycles=", totals[p][0]); field(",parallel_cycles=", totals[p][1]);
        field(",parallel_speedup_x1000=", totals[p][0] * 1000 / totals[p][1]);
        field(",parallel_efficiency_x1000=", totals[p][0] * 1000 / (3 * totals[p][1]));
        field(",serial_gain_x1000=", totals[0][0] * 1000 / totals[p][0]);
        field(",parallel_gain_x1000=", totals[0][1] * 1000 / totals[p][1]);
        text(",frames_per_executor=12\n");
    }
    text("S2D1,PASS,measured_records=24,warmup_records=6,compared_bytes_per_record=3686400,full_output_bit_exact=1,scope=first_conv\n");
    for (;;) __asm__ volatile("nop");
}
