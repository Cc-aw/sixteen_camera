/* Stackful cooperative tasks: the native tiler and Split-K functions remain
 * unchanged. Only complete command packets and local completion waits yield. */
#include <string.h>
#include "independent.h"
#include "yolo32.h"
#include "mmio.h"
#include "platform.h"
#if YOLO32_PPU_EARLY
#include "ppu.h"
static unsigned ppu_seen_done, ppu_turns;
#if YOLO32_PPU_HEAD_CLEAN
static unsigned ppu_seen_heads, local_complete_valid;
static uint32_t local_complete_requests[3];
#endif
#endif

#define STACK_BYTES (16U * 1024U)
#define GUARD_BYTES 64U
#define CANARY 0xa7
enum { RUNNABLE, WAITING, FINISHED };
static struct {
    Yolo32TaskContext context;
    unsigned state, stage, in_stage, packets;
    unsigned pressure, fast_packets;
    unsigned tail_funct, deferred_funct;
    uint64_t packet_dispatch_max;
    uint64_t quantum_start, policy_start;
} tasks[3];
static uint8_t stacks[3][STACK_BYTES] __attribute__((aligned(16)));
static Yolo32TaskContext scheduler;
static Yolo32IndependentStats stats;
static Yolo32TaskStage stages[3][YOLO32_GRAPH_STAGES];
static unsigned current, next_worker, profiling;
static uint64_t begin_cycle;
static unsigned primed_mask;
static unsigned completed_mask;
#if YOLO32_LIVE
static unsigned live_mask;
static uint64_t live_start_cycle[3];
#endif
/* Cache only proven completion of a suspended WAITING task. This is never
 * admission/credit control and is invalidated before that task runs again. */
#define CACHE_COMPLETION (YOLO32_SCHED_ADAPTIVE || YOLO32_HOT_PATHS)
unsigned yolo32_independent_enabled;
unsigned yolo32_task_switch_profile;
volatile uint64_t yolo32_task_switch_cycles, yolo32_task_switch_count;

_Static_assert(offsetof(Yolo32TaskContext, fs) == 112, "task FP offsets");
_Static_assert(offsetof(Yolo32TaskContext, fcsr) == 208, "task CSR offsets");
_Static_assert(offsetof(Yolo32TaskContext, vectors) == 240, "task vector offsets");
_Static_assert(sizeof(Yolo32TaskContext) == 1264, "task context size");
_Static_assert(YOLO32_SUBMIT_BURST > 0, "nonzero submission budget");
_Static_assert(YOLO32_QUANTUM_US > 0, "nonzero CPU budget");
_Static_assert(YOLO32_BLOCK_US > YOLO32_RECOVER_US, "feedback hysteresis");
_Static_assert(YOLO32_SCHED_ADAPTIVE == 0 || YOLO32_SCHED_ADAPTIVE == 1, "scheduler mode");

static unsigned ready(unsigned w, unsigned on_task) {
    /* Latch positive completion only. A suspended WAITING task cannot submit
     * more work until it is resumed. Invalidate at every new dependency wait. */
    if (CACHE_COMPLETION && (completed_mask & (1U << w))) {
        ++stats.cached_ready_hits;
        return 1;
    }
    uint64_t start = profiling ? read_cycle() : 0;
    unsigned done = yolo32_independent_ready(w, (uint32_t)stats.conv_requests[w]);
    if (CACHE_COMPLETION && done) completed_mask |= 1U << w;
    if (profiling) {
        if (on_task) {
            stats.policy_ready_cycles += read_cycle() - start;
            ++stats.policy_ready_checks;
        } else {
            stats.ready_cycles += read_cycle() - start;
            ++stats.ready_checks;
            if (!done) ++stats.ready_blocked;
        }
    }
    return done;
}

static inline unsigned successor(unsigned w) { return w == 2U ? 0U : w + 1U; }
static inline unsigned round_worker(unsigned i) {
    unsigned w = next_worker + i;
    return YOLO32_HOT_PATHS ? (w >= 3U ? w - 3U : w) : w % 3U;
}
static unsigned first_peer(unsigned mask) {
    for (unsigned i = 0; i < 3; ++i) {
        unsigned w = round_worker(i);
        if (mask & (1U << w)) return w;
    }
    return 3;
}

static void account(void) {
    if (!profiling) return;
    uint64_t now=read_cycle();
    if (tasks[current].in_stage && tasks[current].stage < YOLO32_GRAPH_STAGES)
        stages[current][tasks[current].stage].cpu_cycles += now-tasks[current].quantum_start;
    tasks[current].quantum_start=now;
}
static void yield(unsigned state) {
    account();
    tasks[current].state = state;
    yolo32_task_switch(&tasks[current].context, &scheduler);
    /* The scheduler restores model globals before resuming this stack. */
    tasks[current].policy_start=read_cycle();
}
/* Decisions occur only after complete native packets or complete CPU stages.
 * A waiting peer has already crossed the mandatory ingress-visibility handoff.
 * If nobody else can advance, keep this stack rather than save it and reload it.
 * Packet/time budgets are cooperative, not preemption of a blocked RoCC. */
static void maybe_yield(unsigned command) {
    unsigned peers = 0;
    for (unsigned w = 0; w < 3; ++w) {
        if (w == current || tasks[w].state == FINISHED) continue;
        if (tasks[w].state != WAITING || ready(w, 1)) peers |= 1U << w;
    }
    unsigned target = 3;
    unsigned idle_peers = (YOLO32_SCHED_ADAPTIVE || YOLO32_IDLE_PRIORITY) &&
        command && peers && !(peers & ~primed_mask) ?
        peers & ~yolo32_independent_busy_mask() : 0;
    if (!peers) {
        ++stats.no_peer;
#if YOLO32_LIVE
        /* Return to capture/PPU service even with a single active worker. */
        if (tasks[current].packets >= YOLO32_SUBMIT_BURST ||
            read_cycle() - tasks[current].policy_start >=
            (uint64_t)SOC_CLOCK_HZ * YOLO32_QUANTUM_US / 1000000U) {
            next_worker = successor(current);
            yield(RUNNABLE);
        }
#endif
    }
    else if (command && (peers & ~primed_mask)) {
        target = first_peer(peers & ~primed_mask);
        ++stats.bootstrap_yields;
    } else if (idle_peers) {
        /* Finish useful work on idle hardware before feeding a busy peer.
         * This is a scheduling preference, never admission/credit polling. */
        target = first_peer(idle_peers);
        ++stats.idle_yields;
    } else if (YOLO32_SCHED_ADAPTIVE && command && tasks[current].pressure) {
        target = first_peer(peers);
        ++stats.pressure_yields;
    } else if (tasks[current].packets >= YOLO32_SUBMIT_BURST) {
        target = first_peer(peers);
        ++stats.packet_yields;
    } else if (read_cycle() - tasks[current].policy_start >=
               (uint64_t)SOC_CLOCK_HZ * YOLO32_QUANTUM_US / 1000000U) {
        target = first_peer(peers);
        ++stats.time_yields;
    } else if (command && !YOLO32_SCHED_ADAPTIVE && !YOLO32_IDLE_PRIORITY) {
        /* Supply an idle peer promptly. CPU-only stage boundaries are governed
         * by time/packet budgets, avoiding ping-pong between idle CPU stages. */
        unsigned idle = peers & ~yolo32_independent_busy_mask();
        if (idle) { target = first_peer(idle); ++stats.idle_yields; }
    }
    if (target == 3) {
        if (command) ++stats.command_kept;
        else ++stats.stage_kept;
        return;
    }
    if (command) ++stats.command_yields;
    else ++stats.stage_yields;
    next_worker = target;
    yield(RUNNABLE);
}
static void task_entry(void) {
    unsigned w = current;
    Yolo32Result result;
    tasks[w].policy_start=read_cycle();
    for (;;) {
        unsigned stage = yolo32_stage(w);
        uint64_t start = profiling ? read_cycle() : 0;
        tasks[w].stage=stage; tasks[w].in_stage=1;
        tasks[w].quantum_start=start;
        int status = yolo32_graph_poll(w, &result);
        account();
        tasks[w].in_stage=0;
        if (profiling && stage < YOLO32_GRAPH_STAGES)
            stages[w][stage].span_cycles += read_cycle() - start;
        tasks[w].stage = yolo32_stage(w);
        tasks[w].quantum_start = profiling ? read_cycle() : 0;
        if (status == YOLOV5NU_DIM16_HEAD_READY) {
            if (yolo32_independent_head_mask(w) != 63U)
                yolo32_fail("independent_missing_heads");
            stats.done_mask |= 1U << w;
#if YOLO32_PPU_EARLY
            stats.graph_done_cycle[w] = read_cycle();
#endif
            yield(FINISHED);
            yolo32_fail("independent_resume_finished");
        }
        if (status != YOLOV5NU_DIM16_RUNNING)
            yolo32_fail("independent_graph_poll");
        maybe_yield(0);
    }
}
void yolo32_independent_begin(unsigned analysis) {
    if (yolo32_independent_enabled) yolo32_fail("independent_nested_run");
#ifndef YOLO32_HOST_TASKS
    uintptr_t vlen;
    __asm__ volatile("csrr %0, vlenb" : "=r"(vlen));
    if (vlen != 32U) yolo32_fail("independent_vlen");
#endif
    memset(tasks, 0, sizeof(tasks));
    memset(stages, 0, sizeof(stages));
    memset(&stats, 0, sizeof(stats));
    for (unsigned w = 0; w < 3; ++w) {
        memset(stacks[w], CANARY, GUARD_BYTES);
        tasks[w].context.ra = (uintptr_t)task_entry;
        tasks[w].context.sp = (uintptr_t)(stacks[w] + STACK_BYTES);
        /* Initially restore a legal, empty vector configuration. */
        tasks[w].context.vtype = 0;
        yolo32_independent_snapshot(w);
    }
    profiling = analysis;
    yolo32_task_switch_profile=analysis;
    yolo32_task_switch_cycles=yolo32_task_switch_count=0;
    next_worker = 0;
    primed_mask = 0;
    completed_mask = 0;
#if YOLO32_PPU_EARLY
    ppu_seen_done = ppu_turns = 0;
#if YOLO32_PPU_HEAD_CLEAN
    ppu_seen_heads = local_complete_valid = 0;
    memset(local_complete_requests,0,sizeof(local_complete_requests));
#endif
#endif
    begin_cycle = read_cycle();
    yolo32_independent_enabled = 1;
}
#if YOLO32_LIVE
void yolo32_independent_live_init(void) {
    yolo32_independent_begin(0);
    live_mask = 0;
    for (unsigned w = 0; w < 3; ++w) tasks[w].state = FINISHED;
}
void yolo32_independent_live_start(unsigned w) {
    if (w >= 3 || !yolo32_independent_enabled ||
        (tasks[w].state != FINISHED) ||
        (live_mask & (1U << w)))
        yolo32_fail("live_worker_owned");
    memset(&tasks[w], 0, sizeof(tasks[w]));
    memset(stages[w], 0, sizeof(stages[w]));
    memset(stacks[w], CANARY, GUARD_BYTES);
    tasks[w].context.ra = (uintptr_t)task_entry;
    tasks[w].context.sp = (uintptr_t)(stacks[w] + STACK_BYTES);
    stats.conv_requests[w] = stats.matmul_requests[w] = 0;
    stats.head_produced_mask[w] = 0;
    memset(stats.head_completed_cycle[w], 0, sizeof(stats.head_completed_cycle[w]));
    memset(stats.head_requests[w], 0, sizeof(stats.head_requests[w]));
    stats.graph_done_cycle[w] = 0;
    stats.done_mask &= ~(1U << w);
    completed_mask &= ~(1U << w);
    primed_mask &= ~(1U << w);
    local_complete_valid &= ~(1U << w);
    local_complete_requests[w] = 0;
    yolo32_independent_snapshot(w);
    live_start_cycle[w] = read_cycle();
    live_mask |= 1U << w;
}
void yolo32_independent_live_release(unsigned w) {
    if (w >= 3 || !(live_mask & (1U << w)) ||
        !yolo32_independent_finished(w))
        yolo32_fail("live_release_incomplete");
    live_mask &= ~(1U << w);
}
#endif
int yolo32_independent_step(void) {
    uint64_t step_start=profiling ? read_cycle() : 0, task_wall=0;
    uint64_t idle_start=0, idle_cycles=0;
    unsigned idle_sweeps=0;
    unsigned resumed=0;
    if (!yolo32_independent_enabled) yolo32_fail("independent_not_started");
#if YOLO32_LIVE
    for (unsigned w = 0; w < 3; ++w)
        if ((live_mask & (1U << w)) && tasks[w].state != FINISHED &&
            read_cycle() - live_start_cycle[w] >
            (uint64_t)SOC_CLOCK_HZ * YOLO32_TIMEOUT_SECONDS)
            yolo32_fail("live_worker_timeout");
#else
    if (read_cycle() - begin_cycle > (uint64_t)SOC_CLOCK_HZ * YOLO32_TIMEOUT_SECONDS)
        yolo32_fail("independent_timeout");
#endif
    if (profiling) {
        unsigned mask = yolo32_independent_busy_mask() & yolo32_independent_busy_mask();
        stats.busy_mask_seen |= mask;
        if ((mask & (mask - 1U)) != 0) ++stats.overlap_samples;
        if (mask == 7U) ++stats.triple_overlap_samples;
    }
scan:
    for (unsigned i = 0; i < 3; ++i) {
        unsigned w = round_worker(i);
        if (tasks[w].state == FINISHED) continue;
        if (tasks[w].state == WAITING) {
            if (!ready(w, 0)) continue;
#if YOLO32_PPU_HEAD_CLEAN
            /* Capture proof before the completion cache is invalidated and
             * before this task can submit any later native packet. */
            local_complete_valid |= 1U<<w;
            local_complete_requests[w]=(uint32_t)stats.conv_requests[w];
#endif
        }
        if (profiling && idle_start) idle_cycles=read_cycle()-idle_start;
        current = w;
        completed_mask &= ~(1U << w);
        next_worker = YOLO32_HOT_PATHS ? successor(w) : (w + 1U) % 3U;
        yolo32_independent_select(w);
        ++stats.resumes[w];
        uint64_t context_start=profiling ? yolo32_task_switch_cycles : 0;
        uint64_t quantum_start=profiling ? read_cycle() : 0;
        tasks[w].quantum_start=quantum_start;
        tasks[w].packets=0;
        yolo32_task_switch(&scheduler, &tasks[w].context);
        if (profiling) {
            task_wall=read_cycle()-quantum_start;
            stats.task_wall_cycles[w]+=task_wall;
            stats.context_cycles[w]+=yolo32_task_switch_cycles-context_start;
            if (task_wall > stats.max_quantum_cycles) stats.max_quantum_cycles=task_wall;
        }
        resumed=1;
        if (YOLO32_HOT_PATHS) {
            /* Alias-safe fixed-size copies fold into eight aligned loads,
             * retaining the full guard check on every task return. */
            for (unsigned j=0; j<GUARD_BYTES; j+=sizeof(uint64_t)) {
                uint64_t guard;
                __builtin_memcpy(&guard,stacks[w]+j,sizeof(guard));
                if (guard != UINT64_C(0xa7a7a7a7a7a7a7a7))
                    yolo32_fail("independent_stack_overflow");
            }
        } else {
            for (unsigned j = 0; j < GUARD_BYTES; ++j)
                if (stacks[w][j] != CANARY) yolo32_fail("independent_stack_overflow");
        }
        if (tasks[w].context.sp < (uintptr_t)(stacks[w] + GUARD_BYTES) ||
            tasks[w].context.sp > (uintptr_t)(stacks[w] + STACK_BYTES))
            yolo32_fail("independent_stack_pointer");
        break;
    }
    if (YOLO32_HOT_PATHS && !YOLO32_LIVE && !resumed && stats.done_mask != 7U) {
        /* All unfinished tasks are WAITING. Stay on this scheduler frame;
         * do not insert sleeps or issue commands. Probe every sweep and
         * retain bounded timeout checks even when no task can be resumed. */
        if (profiling) {
            ++stats.idle_steps;
            if (!idle_start) idle_start=read_cycle();
        }
        if ((++idle_sweeps & 15U) == 0U &&
            read_cycle()-begin_cycle > (uint64_t)SOC_CLOCK_HZ*YOLO32_TIMEOUT_SECONDS)
            yolo32_fail("independent_timeout");
#if YOLO32_PPU_EARLY
#if YOLO32_PPU_HEAD_CLEAN
        if (stats.head_sequence && !(idle_sweeps & 15U)) yolo32_ppu_early_service();
#else
        if (stats.done_mask && !(idle_sweeps & 15U)) yolo32_ppu_early_service();
#endif
#endif
        goto scan;
    }
#if YOLO32_PPU_EARLY
#if YOLO32_PPU_HEAD_CLEAN
    if ((stats.head_sequence || stats.done_mask) &&
        (stats.head_sequence!=ppu_seen_heads || stats.done_mask!=ppu_seen_done || !(++ppu_turns&15U))) {
        yolo32_ppu_early_service();
        ppu_seen_done=stats.done_mask; ppu_seen_heads=stats.head_sequence;
    }
#else
    if (stats.done_mask && (stats.done_mask != ppu_seen_done || !(++ppu_turns & 15U))) {
        yolo32_ppu_early_service();
        ppu_seen_done = stats.done_mask;
    }
#endif
#endif
    if (profiling) {
        uint64_t elapsed=read_cycle()-step_start;
        uint64_t scheduler_cycles=elapsed-task_wall;
        stats.step_cycles+=elapsed;
        stats.scheduler_cycles+=scheduler_cycles;
        ++stats.scheduler_steps;
        if (!resumed) { ++stats.idle_steps; idle_cycles=scheduler_cycles; }
        stats.idle_scheduler_cycles+=idle_cycles;
        stats.active_scheduler_cycles+=scheduler_cycles-idle_cycles;
    }
    return stats.done_mask == 7U;
}
#if YOLO32_PPU_EARLY
unsigned yolo32_independent_finished(unsigned w) {
    if (w >= 3 || !yolo32_independent_enabled || tasks[w].state != FINISHED ||
        !(stats.done_mask & (1U << w)) || tasks[w].tail_funct || tasks[w].deferred_funct ||
        yolo32_independent_head_mask(w) != 63U)
        yolo32_fail("ppu_producer_state");
    return yolo32_independent_ready(w, (uint32_t)stats.conv_requests[w]);
}
#endif
#if YOLO32_PPU_HEAD_CLEAN
void yolo32_independent_head_ready(unsigned w, unsigned h) {
    static const unsigned head_stage[6]={124,147,164,123,146,163};
    if (!yolo32_independent_enabled || w>=3 || h>=6 || w!=current ||
        !tasks[w].in_stage || tasks[w].stage!=head_stage[h] ||
        !(local_complete_valid&(1U<<w)) || tasks[w].tail_funct || tasks[w].deferred_funct ||
        local_complete_requests[w]!=(uint32_t)stats.conv_requests[w])
        yolo32_fail("ppu_head_completion_proof");
    if (stats.head_produced_mask[w]&(1U<<h)) yolo32_fail("ppu_duplicate_head");
    stats.head_completed_cycle[w][h]=read_cycle();
    stats.head_requests[w][h]=(uint32_t)stats.conv_requests[w];
    stats.head_produced_mask[w]|=1U<<h;
    ++stats.head_sequence;
}
#endif
void yolo32_independent_wait(void) {
    /* Always switch once before observing busy: commands may still be in
     * registered ingress. No hardware fence is issued on a worker stack. */
    unsigned w = current;
    if (YOLO32_TAIL_WAIT) {
        if (tasks[w].tail_funct) yolo32_fail("tail_packet_missing");
        if (tasks[w].deferred_funct) {
            ++stats.tail_wait_merges;
            if (tasks[w].deferred_funct == 15U) ++stats.tail_conv_merges;
            else ++stats.tail_ws_merges;
            tasks[w].deferred_funct = 0;
        }
    }
    uint64_t start = profiling ? read_cycle() : 0;
    ++stats.wait_yields;
    completed_mask &= ~(1U << w);
#if YOLO32_PPU_HEAD_CLEAN
    local_complete_valid &= ~(1U<<w);
#endif
    yield(WAITING);
    if (profiling) stats.wait_cycles[w] += read_cycle() - start;
    __asm__ volatile("" ::: "memory");
}
void yolo32_independent_arm_tail_wait(unsigned funct) {
    if (!YOLO32_TAIL_WAIT || !yolo32_independent_enabled) return;
    if (funct != 15U && funct != 8U) yolo32_fail("tail_packet_kind");
    if (tasks[current].tail_funct || tasks[current].deferred_funct)
        yolo32_fail("tail_packet_rearmed");
    tasks[current].tail_funct = funct;
}
void yolo32_independent_command_elapsed(unsigned funct, uint64_t cycles) {
    if (!YOLO32_SCHED_ADAPTIVE || !yolo32_independent_enabled ||
        (funct != 15U && funct != 11U)) return;
    ++stats.feedback_commands;
    stats.feedback_cycles += cycles;
    if (cycles > stats.dispatch_max_cycles) stats.dispatch_max_cycles = cycles;
    if (cycles > tasks[current].packet_dispatch_max)
        tasks[current].packet_dispatch_max = cycles;
    if (cycles >= (uint64_t)SOC_CLOCK_HZ * YOLO32_BLOCK_US / 1000000U)
        ++stats.slow_dispatches;
}
void yolo32_independent_command_return(unsigned funct) {
    if (!yolo32_independent_enabled || (funct != 15U && funct != 8U)) return;
    unsigned w = current;
#if YOLO32_PPU_HEAD_CLEAN
    local_complete_valid &= ~(1U<<w);
#endif
    if (YOLO32_TAIL_WAIT && tasks[w].deferred_funct)
        yolo32_fail("tail_wait_missing");
    if (funct == 15U) ++stats.conv_requests[w];
    else ++stats.matmul_requests[w];
    if (YOLO32_SCHED_ADAPTIVE) {
        uint64_t latency = tasks[w].packet_dispatch_max;
        tasks[w].packet_dispatch_max = 0;
        if (latency >= (uint64_t)SOC_CLOCK_HZ * YOLO32_BLOCK_US / 1000000U) {
            if (!tasks[w].pressure) ++stats.burst_reductions;
            tasks[w].pressure = 1;
            tasks[w].fast_packets = 0;
        } else if (tasks[w].pressure) {
            if (latency <= (uint64_t)SOC_CLOCK_HZ * YOLO32_RECOVER_US / 1000000U) {
                if (++tasks[w].fast_packets == YOLO32_FAST_PACKETS) {
                    tasks[w].pressure = tasks[w].fast_packets = 0;
                    ++stats.burst_recoveries;
                }
            } else tasks[w].fast_packets = 0;
        }
    }
    primed_mask |= 1U << w;
    ++tasks[w].packets;
    if (tasks[w].packets > stats.max_quantum_packets)
        stats.max_quantum_packets=tasks[w].packets;
    if (profiling) {
        unsigned mask = yolo32_independent_busy_mask();
        for (unsigned other = 0; other < 3; ++other)
            if (other != w && (mask & (1U << other)) && yolo32_stage(other) < yolo32_stage(w)) {
                ++stats.ahead_submissions;
                if (stats.trace_count < 16U) {
                    unsigned t = stats.trace_count++;
                    stats.traces[t].worker = w;
                    stats.traces[t].busy_mask = mask;
                    for (unsigned k = 0; k < 3; ++k) stats.traces[t].stages[k] = yolo32_stage(k);
                }
                break;
            }
    }
    if (YOLO32_TAIL_WAIT && tasks[w].tail_funct) {
        if (tasks[w].tail_funct != funct) yolo32_fail("tail_packet_kind");
        tasks[w].deferred_funct = funct;
        tasks[w].tail_funct = 0;
        ++stats.tail_deferred;
        ++stats.command_kept;
        /* The caller immediately reaches its original local fence. Keep the
         * complete packet here and let WAITING perform the ingress handoff;
         * completion is never inferred from packet return or busy alone. */
        return;
    }
    maybe_yield(1);
}
void yolo32_independent_end(void) {
    if (!yolo32_independent_enabled || stats.done_mask != 7U)
        yolo32_fail("independent_incomplete");
    if (YOLO32_TAIL_WAIT) {
        for (unsigned w = 0; w < 3; ++w)
            if (tasks[w].tail_funct || tasks[w].deferred_funct)
                yolo32_fail("tail_wait_incomplete");
        if (stats.tail_deferred != stats.tail_wait_merges)
            yolo32_fail("tail_wait_accounting");
    }
    /* Keep the final batch boundary. Early publication additionally verifies
     * the finished producer's local DMA completion before its own publish. */
    if (yolo32_independent_busy_mask()) yolo32_fail("independent_busy_at_end");
#ifndef YOLO32_HOST_TASKS
    __asm__ volatile("fence" ::: "memory");
#endif
    yolo32_independent_enabled = 0;
    stats.switch_cycles=yolo32_task_switch_cycles;
    stats.switch_count=yolo32_task_switch_count;
    yolo32_task_switch_profile=0;
}
const Yolo32IndependentStats *yolo32_independent_stats(void) { return &stats; }
const Yolo32TaskStage *yolo32_independent_stage(unsigned w, unsigned stage) {
    return w < 3 && stage < YOLO32_GRAPH_STAGES ? &stages[w][stage] : NULL;
}
