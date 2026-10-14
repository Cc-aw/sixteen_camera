/* Compile the existing cooperative Stage8F model with the generated DIM32 ABI.
 * Keep the graph/weights/RVV operators shared instead of duplicating the AOT. */
#include "yolo32.h"
#include "console.h"
#include "platform.h"
#include "mmio.h"
#include "independent.h"
#if YOLO32_CAPACITY_DIAG
#include "capacity_observer.h"
#endif
#if YOLO32_MEMORY_OPS
#include "memory_kernels.h"
#endif

/* Keep the old spinning ABI admission disabled. The optional cooperative
 * credit experiment checks capacity before a complete fixed Conv packet. */
#define GEMMINI_LOOPCONV_CREDIT_ADMISSION 0
#define GEMMINI_POOL_COMMAND_STATS 1
#if YOLO32_SUPPLY_DIAG
#define GEMMINI_POOL_COMMAND_RETURN_HOOK(funct) do { \
    if ((funct)==15U || (funct)==8U) { \
        unsigned _diag_w=gemmini_pool_active_worker; \
        unsigned _diag_token=yolo32_diag_push(_diag_w,DIAG_POLICY); \
        yolo32_independent_command_return(funct); \
        yolo32_diag_pop(_diag_w,_diag_token); \
    } \
} while (0)
#define YOLO32_DIAG_NATIVE_BEGIN() yolo32_diag_native_begin(gemmini_pool_active_worker)
#define YOLO32_DIAG_NATIVE_END() yolo32_diag_native_end(gemmini_pool_active_worker)
#else
#define GEMMINI_POOL_COMMAND_RETURN_HOOK(funct) do { \
    if (!YOLO32_HOT_PATHS || (funct)==15U || (funct)==8U) \
        yolo32_independent_command_return(funct); \
} while (0)
#define YOLO32_DIAG_NATIVE_BEGIN() ((void)0)
#define YOLO32_DIAG_NATIVE_END() ((void)0)
#endif
static unsigned parallel_mode, parallel_collecting, parallel_pending;
static unsigned parallel_stage;
#if YOLO32_DIAGNOSTIC_BUILD
static unsigned analysis_enabled;
#else
#define analysis_enabled 0U
#endif
#if YOLO32_DIAGNOSTIC_BUILD
static Yolo32CommandStats command_stats[YOLO32_WORKERS][YOLO32_COMMAND_FUNCTS];
#endif
#if YOLO32_ROCC_LAYERS
static Yolo32LayerCommandStats layer_command_stats[YOLO32_WORKERS][YOLO32_GRAPH_STAGES][2];
#endif
#if YOLO32_DIAGNOSTIC_BUILD
static void command_elapsed(unsigned funct, uint64_t cycles);
#define GEMMINI_POOL_COMMAND_CLOCK(funct) ((analysis_enabled || \
    (YOLO32_SCHED_ADAPTIVE && yolo32_independent_enabled && ((funct)==15U || (funct)==11U))) \
    ? (YOLO32_DIAG_NATIVE_BEGIN(),read_cycle()) : UINT64_C(0))
#define GEMMINI_POOL_COMMAND_ELAPSED(funct, start) do { \
    if (analysis_enabled || (YOLO32_SCHED_ADAPTIVE && yolo32_independent_enabled && \
                            ((funct)==15U || (funct)==11U))) { \
        uint64_t elapsed=read_cycle()-(start); \
        YOLO32_DIAG_NATIVE_END(); \
        if (analysis_enabled) command_elapsed(funct,elapsed); \
        if (YOLO32_SCHED_ADAPTIVE && ((funct)==15U || (funct)==11U)) \
            yolo32_independent_command_elapsed(funct,elapsed); \
    } \
} while (0)
#else
#define GEMMINI_POOL_COMMAND_CLOCK(funct) UINT64_C(0)
#define GEMMINI_POOL_COMMAND_ELAPSED(funct,start) ((void)(start))
#endif
static uint64_t stage_cycles[YOLO32_GRAPH_STAGES];
static uint64_t group_submit_cycles, group_wait_cycles;
static unsigned pending_heads[YOLO32_WORKERS];
static void yolo32_publish_head(unsigned worker, unsigned head);
static Yolo32ParallelStats parallel_stats;
#define YOLO32_RECORD_FIXED_RUN(worker,funct) do { \
    if (parallel_mode && (funct)==15U) ++parallel_stats.requests[worker]; \
} while (0)
static void parallel_sample_busy(void);
static void parallel_drain(void);
static void yolo32_model_fence(void);
#if YOLO32_WAIT_REUSE
static void yolo32_reused_fence(unsigned stage);
#endif
/* Also scope fences expanded inside native ABI functions at include time. */
#define gemmini_fence() yolo32_model_fence()
#include "parallel_model.inc"
#include "parallel_stages.inc"
#include "parallel_executor.inc"
static void yolo32_model_fence(void) { yolo_profile_fence(); }
#if YOLO32_MEMORY_OPS
#include "memory_selftest.inc"
#endif
#if YOLO32_WAIT_REUSE
static void yolo32_reused_fence(unsigned stage) {
    if (yolo32_independent_try_reuse_wait(stage)) {
        __asm__ volatile("" ::: "memory");
        return;
    }
    /* Serial/legacy modes and any missing proof keep their original wait. */
    yolo32_model_fence();
}
#endif
#if YOLO32_DIAGNOSTIC_BUILD
static void command_elapsed(unsigned funct, uint64_t cycles) {
    unsigned w=gemmini_pool_active_worker;
    if (w>=YOLO32_WORKERS || funct>=YOLO32_COMMAND_FUNCTS) yolo32_fail("command_profile_id");
    Yolo32CommandStats *s=&command_stats[w][funct];
    ++s->count; s->cycles+=cycles;
    if (cycles>s->max_cycles) s->max_cycles=cycles;
#if YOLO32_ROCC_LAYERS
    if (funct==15U || funct==11U) {
        /* Lockstep descriptors have already advanced their worker stages.
         * Independent/serial native calls are still in the executing stage.
         * This runs before the return hook can yield or select another worker. */
        unsigned stage=parallel_mode ? parallel_stage : yolo32_stage(w);
        if (stage>=YOLO32_GRAPH_STAGES) yolo32_fail("command_profile_stage");
        yolo32_layer_record(&layer_command_stats[w][stage][funct==11U], cycles, SOC_CLOCK_HZ);
    }
#endif
}
#endif
const Yolo32CommandStats *yolo32_command_stats(unsigned worker, unsigned funct) {
#if YOLO32_DIAGNOSTIC_BUILD
    return worker<YOLO32_WORKERS && funct<YOLO32_COMMAND_FUNCTS ? &command_stats[worker][funct] : NULL;
#else
    (void)worker; (void)funct; return NULL;
#endif
}

const Yolo32LayerCommandStats *yolo32_layer_command_stats(unsigned worker,
                                                        unsigned stage, unsigned funct) {
#if YOLO32_ROCC_LAYERS
    if (worker<YOLO32_WORKERS && stage<YOLO32_GRAPH_STAGES && (funct==15U || funct==11U))
        return &layer_command_stats[worker][stage][funct==11U];
#else
    (void)worker; (void)stage; (void)funct;
#endif
    return NULL;
}

static void yolo32_publish_head(unsigned worker, unsigned head) {
    /* Descriptor capture has not executed the conv yet. Publish only after
     * parallel_execute has drained the complete three-worker tile group. */
    if (parallel_collecting || yolo32_independent_enabled) {
#if YOLO32_PPU_HEAD_CLEAN
        if (yolo32_independent_enabled) yolo32_independent_head_ready(worker,head);
#endif
        pending_heads[worker] |= 1U << head;
    }
    else if (head_callback) head_callback(worker, head);
}

_Static_assert(GEMMINI_CONV_TILE_FENCE == 0,
               "Parallel tiles require layer-level synchronization");

_Static_assert(DIM == 32 && BANK_NUM == 8 && BANK_ROWS == 2048 && ACC_ROWS == 2048,
               "Use the generated triple32 parameters");
_Static_assert(sizeof(scale_t_bits) == 2 && sizeof(acc_scale_t_bits) == 2,
               "Use the current FP16 command encoding");
_Static_assert(YOLOV5NU_DIM16_WORKER_COUNT == YOLO32_WORKERS,
               "Three workers are required");

/* Dedicated DDR heads stay intact through CPU postprocessing and comparison.
 * Each row is cache-line aligned and has exactly six contiguous raw heads. */
static elem_t raw_heads[YOLO32_WORKERS][YOLOV5NU_HEAD_PAYLOAD_BYTES]
    __attribute__((aligned(64)));
static uint8_t candidate_masks[YOLO32_WORKERS][YOLO32_POSITIONS];
static unsigned completed[YOLO32_WORKERS];

void gemmini_pool_record_command(unsigned funct) {
    if (parallel_mode && funct == 15 && gemmini_pool_active_worker < 3)
        ++parallel_stats.requests[gemmini_pool_active_worker];
}

static unsigned parallel_busy_mask(void) {
    unsigned mask = 0;
    for (unsigned w=0; w<YOLO32_WORKERS; ++w)
        if (read_worker_busy(w)) mask |= 1U << w;
    return mask;
}

static void parallel_sample_busy(void) {
    if (!analysis_enabled) return;
    /* Two sweeps reduce false overlap from sequential CSR observations. */
    unsigned mask = parallel_busy_mask() & parallel_busy_mask();
    parallel_stats.busy_mask_seen |= mask;
    if ((mask & (mask-1U)) != 0) ++parallel_stats.overlap_samples;
    if (mask == 7U) ++parallel_stats.triple_overlap_samples;
}

static void parallel_drain(void) {
    uint64_t start = read_cycle();
    while (parallel_busy_mask()) {
        parallel_sample_busy();
        if (read_cycle()-start > SOC_CLOCK_HZ * (uint64_t)YOLO32_TIMEOUT_SECONDS)
            yolo32_fail("parallel_drain_timeout");
    }
    gemmini_fence();
    if (analysis_enabled) group_wait_cycles += read_cycle() - start;
}

void yolo32_parallel_begin(void) {
    memset(&parallel_stats, 0, sizeof(parallel_stats));
    parallel_stage = parallel_pending = parallel_collecting = 0;
    memset(pending_heads, 0, sizeof(pending_heads));
    parallel_mode = 1;
}

static uint32_t independent_accepted_base[YOLO32_WORKERS];
/* The ABI's helpers are guarded by software credit admission, which stays
 * disabled. Read the existing CSRs directly for completion observation. */
static uint64_t independent_status_read(unsigned w) {
    uint64_t value;
    if (w == 0) __asm__ volatile("csrr %0, 0x7c4" : "=r"(value) :: "memory");
    else if (w == 1) __asm__ volatile("csrr %0, 0x7c5" : "=r"(value) :: "memory");
    else __asm__ volatile("csrr %0, 0x7cb" : "=r"(value) :: "memory");
    return value;
}
static uint32_t independent_counter_read(unsigned w, unsigned retired) {
    uint64_t value;
    if (w == 0) {
        if (retired) __asm__ volatile("csrr %0, 0x7c7" : "=r"(value) :: "memory");
        else __asm__ volatile("csrr %0, 0x7c6" : "=r"(value) :: "memory");
    } else if (w == 1) {
        if (retired) __asm__ volatile("csrr %0, 0x7c9" : "=r"(value) :: "memory");
        else __asm__ volatile("csrr %0, 0x7c8" : "=r"(value) :: "memory");
    } else {
        if (retired) __asm__ volatile("csrr %0, 0x7cd" : "=r"(value) :: "memory");
        else __asm__ volatile("csrr %0, 0x7cc" : "=r"(value) :: "memory");
    }
    return (uint32_t)value;
}
void yolo32_independent_select(unsigned worker) { select_worker_memory(worker); }
void yolo32_independent_snapshot(unsigned worker) {
    parallel_mode = parallel_collecting = parallel_pending = 0;
    pending_heads[worker] = 0;
    select_worker_memory(worker);
    independent_accepted_base[worker] = independent_counter_read(worker, 0);
}
unsigned yolo32_independent_ready(unsigned worker, uint32_t requests) {
    uint64_t status = independent_status_read(worker);
    if (status & UINT64_C(0xc000)) yolo32_fail("independent_ingress_error");
    /* busy, outstanding, ingress queue, running slots and partial packet.
     * These are completion checks only; admission remains hardware-owned. */
    if (status & UINT64_C(0x1f1d)) return 0;
    uint32_t expected = independent_accepted_base[worker] + requests;
    if (independent_counter_read(worker, 0) != expected ||
        independent_counter_read(worker, 1) != expected) return 0;
    return !read_worker_busy(worker);
}
#if YOLO32_CREDIT_LIMIT
#if YOLO32_CAPACITY_EXPERIMENT
/* Hardware's inclusive SAFE_MAX is four accepted-not-retired requests.
 * Software-issued accounting also reserves registered ingress lag. The live
 * entrance gate remains mandatory; this is not a four-packet reservation. */
_Static_assert(GEMMINI_LOOPCONV_SAFE_MAX == 4 &&
               YOLO32_CREDIT_LIMIT <= GEMMINI_LOOPCONV_SAFE_MAX,
               "Capacity experiment requires the verified four-slot ABI");
#else
_Static_assert(YOLO32_CREDIT_LIMIT < GEMMINI_LOOPCONV_SAFE_MAX,
               "Credit experiment must leave one hardware request slot free");
#endif
unsigned yolo32_independent_credit_ready(unsigned worker, uint32_t issued,
                                       uint32_t *pending) {
    /* CPU-issued minus hardware-retired includes the registered ingress lag.
     * Merely reading accepted-retired could miss already-issued packets. */
    uint32_t expected=independent_accepted_base[worker]+issued;
    *pending=expected-independent_counter_read(worker,1);
    if (*pending>YOLO32_CREDIT_LIMIT) yolo32_fail("credit_retired_or_budget");
    uint64_t status=independent_status_read(worker);
    if (status & UINT64_C(0xc000)) yolo32_fail("independent_ingress_error");
    /* can_submit also covers the ordered ingress queue and assembler state.
     * This snapshot is not a reservation for WS/LUT/ordinary commands. */
#if YOLO32_SUPPLY_DIAG
    yolo32_diag_credit_status(worker,status);
#endif
    return *pending<YOLO32_CREDIT_LIMIT && (status & UINT64_C(2));
}
#if YOLO32_CREDIT_QUERY
uint32_t yolo32_independent_credit_pending(unsigned worker, uint32_t issued) {
    uint32_t expected=independent_accepted_base[worker]+issued;
    uint32_t pending=expected-independent_counter_read(worker,1);
    if (pending>YOLO32_CREDIT_LIMIT) yolo32_fail("credit_retired_or_budget");
    return pending;
}
unsigned yolo32_independent_credit_status(unsigned worker) {
    uint64_t status=independent_status_read(worker);
    if (status & UINT64_C(0xc000)) yolo32_fail("independent_ingress_error");
    return (status & UINT64_C(2)) != 0;
}
#if YOLO32_CAPACITY_DIAG
uint64_t yolo32_capacity_status(unsigned worker) {
    uint64_t status=independent_status_read(worker);
    if (status & UINT64_C(0xc000)) yolo32_fail("independent_ingress_error");
    return status;
}
#endif
#endif
#endif
unsigned yolo32_independent_busy_mask(void) { return parallel_busy_mask(); }
unsigned yolo32_independent_head_mask(unsigned worker) {
    return worker < YOLO32_WORKERS ? pending_heads[worker] : 0;
}

int yolo32_parallel_step(Yolo32Result results[YOLO32_WORKERS]) {
    if (!parallel_mode || parallel_stage >= 165) return -1;
    uint64_t start = analysis_enabled ? read_cycle() : 0;
    parallel_collecting = parallel_conv_stage[parallel_stage];
    for (unsigned w=0; w<YOLO32_WORKERS; ++w) {
        struct yolov5nu_worker_context *context = &worker_contexts[w];
        if (!context->active || context->stage != parallel_stage)
            yolo32_fail("parallel_stage_mismatch");
        /* The previous layer was drained before CPU dependent operations. */
        context->waiting = context->poll_armed = 0;
        if (yolov5nu_dim16_worker_poll(w, &results[w]) != YOLOV5NU_DIM16_RUNNING ||
            context->stage != parallel_stage+1)
            yolo32_fail("parallel_stage_advance");
    }
    if (parallel_collecting) {
        uint64_t before_wait = group_wait_cycles;
        uint64_t submit_start = analysis_enabled ? read_cycle() : 0;
        parallel_execute();
        if (analysis_enabled)
            group_submit_cycles += read_cycle() - submit_start - (group_wait_cycles - before_wait);
        for (unsigned w = 0; w < YOLO32_WORKERS; ++w) {
            for (unsigned h = 0; h < 6; ++h)
                if (pending_heads[w] & (1U << h)) yolo32_publish_head(w, h);
            pending_heads[w] = 0;
        }
    }
    if (analysis_enabled) stage_cycles[parallel_stage] += read_cycle() - start;
    if (++parallel_stage == 165) {
        parallel_mode = 0;
        return 1;
    }
    return 0;
}

void yolo32_set_analysis(unsigned enabled) {
#if YOLO32_DIAGNOSTIC_BUILD
    analysis_enabled = enabled != 0;
#else
    if (enabled) yolo32_fail("diagnostic_image_required");
#endif
#if YOLO32_MEMORY_OPS
    memset(memory_stats,0,sizeof(memory_stats));
#endif
#if YOLO32_DIAGNOSTIC_BUILD
    memset(command_stats,0,sizeof(command_stats));
#if YOLO32_ROCC_LAYERS
    memset(layer_command_stats,0,sizeof(layer_command_stats));
#endif
    memset(stage_cycles, 0, sizeof(stage_cycles));
#endif
    group_submit_cycles = group_wait_cycles = 0;
}

uint64_t yolo32_stage_cycles(unsigned stage) {
    return stage < YOLO32_GRAPH_STAGES ? stage_cycles[stage] : 0;
}
const char *yolo32_stage_kind(unsigned stage) { return stage_kinds[stage]; }
const char *yolo32_stage_label(unsigned stage) { return stage_labels[stage]; }
uint64_t yolo32_parallel_submit_cycles(void) { return group_submit_cycles; }
uint64_t yolo32_parallel_wait_cycles(void) { return group_wait_cycles; }
int yolo32_profile(unsigned worker, struct yolov5nu_dim16_profile *profile) {
    return yolov5nu_dim16_worker_get_profile(worker, profile);
}

const Yolo32ParallelStats *yolo32_parallel_stats(void) {
    return &parallel_stats;
}

void yolo32_init(void) {
    yolov5nu_dim16_dual_init();
    memset(completed, 0, sizeof(completed));
}

int yolo32_start_hardware(unsigned worker, const int8_t *input, uintptr_t head) {
    if (worker >= YOLO32_WORKERS || !input || !head)
        return YOLOV5NU_DIM16_ERROR;
    int status = yolov5nu_dim16_worker_start(worker, input);
    if (status < 0) return status;
    yolov5nu_dim16_worker_set_head_slot(worker, head);
    yolov5nu_dim16_worker_use_hardware(worker, 1);
#if YOLO32_SOFTWARE_BATCH
    yolo32_batch_bind_start(worker);
#endif
    completed[worker] = 0;
    return status;
}
void yolo32_finish_hardware(unsigned worker) {
    yolov5nu_dim16_worker_finish_hardware(worker);
    completed[worker] = 1;
}
const int8_t *yolo32_raw_heads(unsigned worker) {
    return worker < YOLO32_WORKERS ? (const int8_t *)worker_contexts[worker].head_slot : NULL;
}
void yolo32_set_head_callback(void (*callback)(unsigned, unsigned)) {
    yolov5nu_dim16_set_head_callback(callback);
}

int yolo32_start(unsigned worker, const int8_t *input) {
    if (worker >= YOLO32_WORKERS)
        return YOLOV5NU_DIM16_ERROR;
    int status = input ? yolov5nu_dim16_worker_start(worker, input) :
                        yolov5nu_dim16_worker_start_reference(worker);
    if (status < 0) return status;
    completed[worker] = 0;
    /* Sentinel poisoning distinguishes missing writes across workers. */
    memset(raw_heads[worker], 0x51 + (int)worker, sizeof(raw_heads[worker]));
    yolov5nu_dim16_worker_set_head_slot(worker, (uintptr_t)raw_heads[worker]);
    yolov5nu_dim16_worker_use_hardware(worker, 1);
#if YOLO32_SOFTWARE_BATCH
    yolo32_batch_bind_start(worker);
#endif
    return status;
}

int yolo32_poll(unsigned worker, Yolo32Result *result) {
    if (worker >= YOLO32_WORKERS || result == NULL)
        return YOLOV5NU_DIM16_ERROR;
    struct yolov5nu_worker_context *context = &worker_contexts[worker];
    int status = context->stage == YOLOV5NU_GRAPH_STAGE_COUNT && context->hardware_head ?
        yolov5nu_dim16_worker_finish_software(worker, result) :
        yolov5nu_dim16_worker_poll(worker, result);
    if (status == YOLOV5NU_DIM16_HEAD_READY)
        status = yolov5nu_dim16_worker_finish_software(worker, result);
    if (status == YOLOV5NU_DIM16_DONE) {
        memcpy(candidate_masks[worker], dfl_candidate_mask, YOLO32_POSITIONS);
        completed[worker] = 1;
    }
    return status;
}

int yolo32_graph_poll(unsigned worker, Yolo32Result *result) {
    if (worker >= YOLO32_WORKERS || result == NULL)
        return YOLOV5NU_DIM16_ERROR;
    unsigned stage = yolo32_stage(worker);
    uint64_t start = analysis_enabled ? read_cycle() : 0;
#if YOLO32_SUPPLY_DIAG
    unsigned detail=yolo32_diag_enabled() && stage<YOLO32_GRAPH_STAGES;
    if (detail) {
        if (!yolo32_independent_enabled) yolo32_diag_owner(worker);
        yolo32_diag_stage_begin(worker,stage,yolo32_stage_kind(stage));
        if (yolo32_diag_detail_enabled()) {
            unsigned token=yolo32_diag_push(worker,DIAG_INSTRUMENT);
            uint32_t values[6];
            for (unsigned i=0;i<6;++i) values[i]=frame_counter_read(worker,i);
            yolo32_diag_hw_begin(worker,values);
            yolo32_diag_pop(worker,token);
        }
    }
#endif
    int status = yolov5nu_dim16_worker_poll(worker, result);
#if YOLO32_SUPPLY_DIAG
    if (detail) {
        if (yolo32_diag_detail_enabled()) {
            unsigned token=yolo32_diag_push(worker,DIAG_INSTRUMENT);
            uint32_t values[6];
            for (unsigned i=0;i<6;++i) values[i]=frame_counter_read(worker,i);
            yolo32_diag_hw_end(worker,values);
            yolo32_diag_pop(worker,token);
        }
        yolo32_diag_stage_end(worker);
        if (!yolo32_independent_enabled) yolo32_diag_owner(3);
    }
#endif
    if (analysis_enabled && !yolo32_independent_enabled && stage < YOLO32_GRAPH_STAGES)
        stage_cycles[stage] += read_cycle() - start;
    return status;
}

int yolo32_output(unsigned worker, const Yolo32Result *result,
                  Yolo32Output *output) {
    if (worker >= YOLO32_WORKERS || !completed[worker] || !result || !output)
        return -1;
    select_worker_memory(worker);
    *output = (Yolo32Output){raw_heads[worker], tensor_246, tensor_248,
                            tensor_252, candidate_masks[worker], result};
    return 0;
}

unsigned yolo32_stage(unsigned worker) {
    return yolov5nu_dim16_worker_stage(worker);
}

#if YOLO32_SOFTWARE_BATCH
uint64_t yolo32_batch_binding_init_cycles(void) { return batch_bind_once_cycles; }
uint64_t yolo32_batch_binding_cycles(unsigned w) { return w<3 ? batch_bind_cycles[w] : 0; }
uint32_t yolo32_batch_binding_generation(unsigned w) { return w<3 ? batch_binding_generation[w] : 0; }
#endif
