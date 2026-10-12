#ifndef YOLO32_INDEPENDENT_H
#define YOLO32_INDEPENDENT_H
#include <stddef.h>
#include <stdint.h>
#include "task_context_config.h"
#ifndef YOLO32_LIVE
#define YOLO32_LIVE 0
#endif

#ifndef YOLO32_SUBMIT_BURST
#define YOLO32_SUBMIT_BURST 2U
#endif
#ifndef YOLO32_QUANTUM_US
#define YOLO32_QUANTUM_US 200U
#endif
#ifndef YOLO32_SCHED_ADAPTIVE
#define YOLO32_SCHED_ADAPTIVE 1
#endif
#ifndef YOLO32_BLOCK_US
#define YOLO32_BLOCK_US 20U
#endif
#ifndef YOLO32_HOT_PATHS
#define YOLO32_HOT_PATHS 0
#endif
#if YOLO32_HOT_PATHS != 0 && YOLO32_HOT_PATHS != 1
#error "YOLO32_HOT_PATHS must be 0 or 1"
#endif
#ifndef YOLO32_ROCC_LAYERS
#define YOLO32_ROCC_LAYERS 0
#endif
#ifndef YOLO32_FIXED_PLANS
#define YOLO32_FIXED_PLANS 0
#endif
#if YOLO32_FIXED_PLANS != 0 && YOLO32_FIXED_PLANS != 1
#error "YOLO32_FIXED_PLANS must be 0 or 1"
#endif
#ifndef YOLO32_FIXED_PACKETS
#define YOLO32_FIXED_PACKETS 0
#endif
#if YOLO32_FIXED_PACKETS != 0 && YOLO32_FIXED_PACKETS != 1
#error "YOLO32_FIXED_PACKETS must be 0 or 1"
#endif
#if YOLO32_FIXED_PACKETS && !YOLO32_FIXED_PLANS
#error "YOLO32_FIXED_PACKETS requires fixed plans"
#endif
#ifndef YOLO32_IDLE_PRIORITY
#define YOLO32_IDLE_PRIORITY 0
#endif
#ifndef YOLO32_TAIL_WAIT
#define YOLO32_TAIL_WAIT 0
#endif
#if (YOLO32_IDLE_PRIORITY != 0 && YOLO32_IDLE_PRIORITY != 1) || \
    (YOLO32_TAIL_WAIT != 0 && YOLO32_TAIL_WAIT != 1)
#error "Idle priority and tail wait must be 0 or 1"
#endif
#if YOLO32_TAIL_WAIT && !YOLO32_FIXED_PACKETS
#error "Tail wait annotations require fixed packets"
#endif
#ifndef YOLO32_PREPARED_PACKETS
#define YOLO32_PREPARED_PACKETS 0
#endif
#if YOLO32_PREPARED_PACKETS != 0 && YOLO32_PREPARED_PACKETS != 1
#error "YOLO32_PREPARED_PACKETS must be 0 or 1"
#endif
#if YOLO32_PREPARED_PACKETS && !YOLO32_FIXED_PACKETS
#error "Prepared WS/LUT packets require fixed packets"
#endif
#ifndef YOLO32_PPU_EARLY
#define YOLO32_PPU_EARLY 0
#endif
#if YOLO32_PPU_EARLY != 0 && YOLO32_PPU_EARLY != 1
#error "YOLO32_PPU_EARLY must be 0 or 1"
#endif
#if YOLO32_PPU_EARLY && !YOLO32_PREPARED_PACKETS
#error "Early PPU builds require the prepared-packets baseline"
#endif
#ifndef YOLO32_PPU_HEAD_CLEAN
#define YOLO32_PPU_HEAD_CLEAN 0
#endif
#ifndef YOLO32_PPU_HEAD_ADMIT
#define YOLO32_PPU_HEAD_ADMIT 0
#endif
#if (YOLO32_PPU_HEAD_CLEAN != 0 && YOLO32_PPU_HEAD_CLEAN != 1) || \
    (YOLO32_PPU_HEAD_ADMIT != 0 && YOLO32_PPU_HEAD_ADMIT != 1)
#error "Head clean and Class0 admission must be 0 or 1"
#endif
#if YOLO32_PPU_HEAD_CLEAN && !YOLO32_PPU_EARLY
#error "Head clean requires the early PPU ordering path"
#endif
#if YOLO32_PPU_HEAD_ADMIT && !YOLO32_PPU_HEAD_CLEAN
#error "Class0 admission requires head clean"
#endif
#if YOLO32_PPU_HEAD_CLEAN
#define YOLO32_FIRMWARE_VERSION "v17"
#elif YOLO32_PPU_EARLY
#define YOLO32_FIRMWARE_VERSION "v16"
#elif YOLO32_PREPARED_PACKETS
#define YOLO32_FIRMWARE_VERSION "v15"
#elif YOLO32_IDLE_PRIORITY || YOLO32_TAIL_WAIT
#define YOLO32_FIRMWARE_VERSION "v14"
#elif YOLO32_FIXED_PACKETS
#define YOLO32_FIRMWARE_VERSION "v13"
#elif YOLO32_FIXED_PLANS
#define YOLO32_FIRMWARE_VERSION "v12"
#elif YOLO32_ROCC_LAYERS
#define YOLO32_FIRMWARE_VERSION "v11"
#elif YOLO32_HOT_PATHS
#define YOLO32_FIRMWARE_VERSION "v10"
#else
#define YOLO32_FIRMWARE_VERSION "v9"
#endif
#define YOLO32_RECOVER_US 5U
#define YOLO32_FAST_PACKETS 4U
#if YOLO32_SCHED_ADAPTIVE
#define YOLO32_SCHED_NAME "adaptive"
#else
#define YOLO32_SCHED_NAME "fixed"
#endif

/* Offsets are shared with task_switch.S. VLEN is fixed by this SoC to 256.
 * Keep storage/layout identical for full/light builds. Light mode does not
 * read or write vl/vtype/vectors. This is not an asynchronous interrupt frame. */
typedef struct __attribute__((aligned(16))) {
    uintptr_t ra, sp, s[12];
    uint64_t fs[12], fcsr, vl, vtype, vcsr;
    uint8_t vectors[1024];
} Yolo32TaskContext;
typedef struct { uint64_t cpu_cycles, span_cycles; } Yolo32TaskStage;
typedef struct {
    uint64_t resumes[3], conv_requests[3], matmul_requests[3], wait_cycles[3];
    uint64_t ahead_submissions, overlap_samples, triple_overlap_samples;
    uint64_t task_wall_cycles[3], context_cycles[3];
    uint64_t step_cycles, scheduler_cycles, ready_cycles, ready_checks, ready_blocked, idle_steps;
    uint64_t scheduler_steps, idle_scheduler_cycles, active_scheduler_cycles;
    uint64_t switch_cycles, switch_count;
    uint64_t command_yields, stage_yields, command_kept, stage_kept;
    uint64_t bootstrap_yields, idle_yields, packet_yields, time_yields, wait_yields;
    uint64_t policy_ready_cycles, policy_ready_checks, no_peer;
    uint64_t max_quantum_packets, max_quantum_cycles;
    uint64_t pressure_yields, feedback_commands, feedback_cycles, dispatch_max_cycles;
    uint64_t slow_dispatches, burst_reductions, burst_recoveries, cached_ready_hits;
    uint64_t tail_deferred, tail_wait_merges, tail_conv_merges, tail_ws_merges;
    unsigned busy_mask_seen, done_mask;
#if YOLO32_PPU_EARLY
    uint64_t graph_done_cycle[3];
#endif
#if YOLO32_PPU_HEAD_CLEAN
    uint64_t head_completed_cycle[3][6];
    uint32_t head_requests[3][6];
    unsigned head_produced_mask[3], head_sequence;
#endif
    struct { unsigned worker, busy_mask, stages[3]; } traces[16];
    unsigned trace_count;
} Yolo32IndependentStats;

extern unsigned yolo32_independent_enabled;
extern unsigned yolo32_task_switch_profile;
extern volatile uint64_t yolo32_task_switch_cycles, yolo32_task_switch_count;
void yolo32_independent_begin(unsigned analysis);
#if YOLO32_LIVE
/* Persistent worker pool. Start only after the model arena/Head slot is set. */
void yolo32_independent_live_init(void);
/* Release the finished producer before issuing any next-frame commands. */
void yolo32_independent_live_release(unsigned worker);
void yolo32_independent_live_start(unsigned worker);
#endif
/* One scheduling quantum; 1 = all raw heads complete, 0 = running. */
int yolo32_independent_step(void);
void yolo32_independent_end(void);
#if YOLO32_PPU_EARLY
/* Scheduler only; verifies a FINISHED producer without waiting for its peers. */
unsigned yolo32_independent_finished(unsigned worker);
#endif
#if YOLO32_PPU_HEAD_CLEAN
/* Called by the generated head callback after its original local wait. */
void yolo32_independent_head_ready(unsigned worker, unsigned head);
#endif
void yolo32_independent_wait(void);
/* Mark a complete packet whose next dependency is the existing local wait.
 * Its return hook keeps this stack until that wait performs the sole handoff. */
void yolo32_independent_arm_tail_wait(unsigned funct);
void yolo32_independent_command_return(unsigned funct);
/* Called before the return hook. Does not switch within a native packet. */
void yolo32_independent_command_elapsed(unsigned funct, uint64_t cycles);
const Yolo32IndependentStats *yolo32_independent_stats(void);
const Yolo32TaskStage *yolo32_independent_stage(unsigned worker, unsigned stage);

/* Model backend. Completion includes ingress retirement and DMA responses. */
void yolo32_independent_select(unsigned worker);
void yolo32_independent_snapshot(unsigned worker);
/* Observational: must not change the selected opcode or model arena. */
unsigned yolo32_independent_ready(unsigned worker, uint32_t conv_requests);
unsigned yolo32_independent_busy_mask(void);
unsigned yolo32_independent_head_mask(unsigned worker);
void yolo32_task_switch(Yolo32TaskContext *from, const Yolo32TaskContext *to);
#endif
