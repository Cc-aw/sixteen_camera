#ifndef YOLO32_H
#define YOLO32_H

#include <stddef.h>
#include <stdint.h>
#include "yolov5nu_dim16_dual.h"
#include "yolov5nu_head_layout.h"

#define YOLO32_WORKERS 3U
#define YOLO32_CLASS_BYTES 504000U
#define YOLO32_POSITIONS 6300U
#define YOLO32_GRAPH_STAGES 165U

typedef struct yolov5nu_dim16_result Yolo32Result;

typedef struct {
    const int8_t *heads;
    const int8_t *logits;
    const int8_t *scores;
    const int8_t *dfl;
    const uint8_t *mask;
    const Yolo32Result *result;
} Yolo32Output;

typedef struct {
    uint32_t mismatches;
    const char *first_field;
    uint32_t first_index;
} Yolo32Comparison;

typedef struct {
    uint64_t conv_groups, tile_groups, requests[YOLO32_WORKERS];
    uint64_t overlap_samples, triple_overlap_samples;
    unsigned busy_mask_seen;
} Yolo32ParallelStats;
typedef struct { uint64_t count, cycles, max_cycles; } Yolo32CommandStats;
#define YOLO32_COMMAND_FUNCTS 32U

#ifndef YOLO32_ROCC_LAYERS
#define YOLO32_ROCC_LAYERS 0
#endif
#if YOLO32_ROCC_LAYERS != 0 && YOLO32_ROCC_LAYERS != 1
#error "YOLO32_ROCC_LAYERS must be 0 or 1"
#endif
/* Cumulative latency buckets: >=20us, >=100us, >=1ms. */
typedef struct {
    uint64_t count, cycles, max_cycles, max_index;
    uint64_t slow_count[3], slow_cycles[3];
} Yolo32LayerCommandStats;
static inline void yolo32_layer_record(Yolo32LayerCommandStats *s,
                                       uint64_t cycles, uint64_t clock_hz) {
    const unsigned us[3] = {20, 100, 1000};
    ++s->count; s->cycles += cycles;
    if (cycles > s->max_cycles) { s->max_cycles = cycles; s->max_index = s->count; }
    for (unsigned b=0; b<3; ++b) if (cycles >= clock_hz/1000000*us[b]) {
        ++s->slow_count[b]; s->slow_cycles[b] += cycles;
    }
}
const Yolo32LayerCommandStats *yolo32_layer_command_stats(unsigned worker,
                                                        unsigned stage, unsigned funct);
const Yolo32CommandStats *yolo32_command_stats(unsigned worker, unsigned funct);

void yolo32_parallel_begin(void);
/* Return 1 after stage 164; caller completes raw-head readiness and HW PPU. */
int yolo32_parallel_step(Yolo32Result results[YOLO32_WORKERS]);
const Yolo32ParallelStats *yolo32_parallel_stats(void);

/* The caller owns output buffers; compare only calculated sparse DFL entries. */
Yolo32Comparison yolo32_compare(const Yolo32Output *left,
                                const Yolo32Output *right);
uint64_t yolo32_hash(const void *data, size_t bytes);
uint32_t yolo32_float_bits(float value);

void yolo32_init(void);
int yolo32_start_hardware(unsigned worker, const int8_t *input, uintptr_t head);
void yolo32_finish_hardware(unsigned worker);
const int8_t *yolo32_raw_heads(unsigned worker);
void yolo32_set_head_callback(void (*callback)(unsigned, unsigned));
/* Graph polling stops at raw heads; finish via PPU and finish_hardware(). */
int yolo32_graph_poll(unsigned worker, Yolo32Result *result);
void yolo32_set_analysis(unsigned enabled);
uint64_t yolo32_stage_cycles(unsigned stage);
const char *yolo32_stage_kind(unsigned stage);
const char *yolo32_stage_label(unsigned stage);
uint64_t yolo32_parallel_submit_cycles(void);
uint64_t yolo32_parallel_wait_cycles(void);
int yolo32_profile(unsigned worker, struct yolov5nu_dim16_profile *profile);
/* NULL input selects embedded 640x480 NHWC signed INT8 image025. */
int yolo32_start(unsigned worker, const int8_t *input);
int yolo32_poll(unsigned worker, Yolo32Result *result);
int yolo32_output(unsigned worker, const Yolo32Result *result,
                  Yolo32Output *output);
unsigned yolo32_stage(unsigned worker);
__attribute__((noreturn)) void yolo32_fail(const char *reason);

#endif
