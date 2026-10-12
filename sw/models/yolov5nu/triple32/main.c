#include <string.h>
#include "yolo32.h"
#include "ppu.h"
#include "independent.h"
#include "inputs.h"
#include "console.h"
#include "mmio.h"
#include "platform.h"
#ifndef YOLO32_TIMEOUT_SECONDS
#define YOLO32_TIMEOUT_SECONDS 600
#endif
_Static_assert(YOLO32_TIMEOUT_SECONDS > 0, "Timeout must be positive");
enum { PARALLEL, FORWARD, REVERSE, BLOCKED, INDEPENDENT, MODES, ROUNDS = 5 };
static const char *const mode_names[MODES] = {"parallel", "forward", "reverse", "blocked", "independent"};
static Yolo32Result unused_results[3];
static int8_t reference_heads[3][YOLOV5NU_HEAD_PAYLOAD_BYTES];
static Yolo32PpuResult references[3];
static uint64_t starts[3];
static unsigned run_id, reference_valid, run_failures;
typedef struct { uint64_t batch, graph, post; } Timing;
static void help(void) {
    console_puts("Commands: u/U=serial forward/reverse; b=blocking worker polling; "
        "t=independent workers; l=legacy lockstep tiles; a=5-mode hardware-PPU benchmark; "
        "p=profiles; q=serial/independent RoCC layer diagnosis; 0/1/2=single image; h=help\r\n");
}
static void field(const char *name, uint64_t value) {
    console_puts(" "); console_puts(name); console_putc('='); console_put_hex64(value);
}
static void worker_image(unsigned w) {
    console_puts(" worker="); console_put_u32(w);
    console_puts(" image="); console_puts(yolo32_image_ids[w]);
}
static void timeout(uint64_t start) {
    if (read_cycle()-start > SOC_CLOCK_HZ*(uint64_t)YOLO32_TIMEOUT_SECONDS) yolo32_fail("inference_timeout");
}
static void start_worker(unsigned w) {
    starts[w]=read_cycle();
    uintptr_t head=yolo32_ppu_begin(w,run_id);
    if (yolo32_start_hardware(w,yolo32_inputs[w],head)<0) yolo32_fail("start");
}
static int graph_poll(unsigned w) {
    int status=yolo32_graph_poll(w,&unused_results[w]); timeout(starts[w]);
    if (status==YOLOV5NU_DIM16_HEAD_READY) { yolo32_ppu_graph_done(w); return 1; }
    if (status!=YOLOV5NU_DIM16_RUNNING) yolo32_fail("graph_poll");
    yolo32_ppu_service(); return 0;
}
static void finish_worker(unsigned w) {
    while (!yolo32_ppu_done(w)) { yolo32_ppu_service(); timeout(starts[w]); }
}
static void print_result(unsigned w) {
    const Yolo32PpuResult *r=yolo32_ppu_result(w);
    console_puts("YOLO32_WORKER"); worker_image(w);
    field("raw_fnv",yolo32_hash(yolo32_raw_heads(w),YOLOV5NU_HEAD_PAYLOAD_BYTES));
    field("ppu_fnv",yolo32_hash(r->words,sizeof(r->words))); field("detections",r->count);
    field("ppu_core_cycles",r->core_cycles); field("ppu_wall_cycles",r->wall_cycles);
    field("cycles",r->completed_cycle-starts[w]); console_puts("\r\n");
    for (unsigned i=0;i<r->count;++i) {
        console_puts("YOLO32_DETECTION worker="); console_put_u32(w); field("index",i);
        field("xy0",r->words[i][0]); field("xy1",r->words[i][1]);
        field("score_class",r->words[i][2]); field("word3",r->words[i][3]); console_puts("\r\n");
    }
}
static unsigned compare_result(unsigned w, unsigned baseline) {
    const int8_t *heads=yolo32_raw_heads(w);
    const Yolo32PpuResult *r=yolo32_ppu_result(w);
    if (baseline) { memcpy(reference_heads[w],heads,sizeof(reference_heads[w])); references[w]=*r; }
    unsigned mismatches=0, first_index=0; const char *first="none";
    for (unsigned i=0;i<YOLOV5NU_HEAD_PAYLOAD_BYTES;++i) if (reference_heads[w][i]!=heads[i]) {
        if (!mismatches) { first="raw_heads"; first_index=i; } ++mismatches;
    }
    if (references[w].count!=r->count) { if (!mismatches) first="count"; ++mismatches; }
    for (unsigned i=0;i<10;++i) for(unsigned j=0;j<4;++j) if(references[w].words[i][j]!=r->words[i][j]) {
        if (!mismatches) { first="ppu_words"; first_index=i*4+j; } ++mismatches;
    }
    console_puts("YOLO32_COMPARE"); worker_image(w); console_puts(" reference=serial");
    field("mismatches",mismatches); console_puts(" first="); console_puts(first);
    field("index",first_index); console_puts("\r\n"); return mismatches==0;
}
static void print_profiles(int mode) {
    for (unsigned w = 0; w < 3; ++w) {
        struct yolov5nu_dim16_profile p;
        if (yolo32_profile(w, &p)) yolo32_fail("profile");
        console_puts("YOLO32_PROFILE"); worker_image(w);
        field("gem_busy", p.gemmini_busy_cycles); field("exec", p.gemmini_exec_cycles);
        field("load_stall", p.gemmini_load_stall_cycles); field("store_stall", p.gemmini_store_stall_cycles);
        /* Native conv_call includes fence; grouped tile timings are below. */
        field("conv_call", p.rocc_submit_cycles); field("fence", p.fence_cycles);
        field("rvv", p.rvv_maxpool_cycles + p.rvv_resize_cycles + p.rvv_copy_requant_cycles);
        console_puts("\r\n");
    }
    for (unsigned w=0; w<3; ++w) for (unsigned f=0; f<YOLO32_COMMAND_FUNCTS; ++f) {
        const Yolo32CommandStats *s=yolo32_command_stats(w,f);
        if (!s || !s->count) continue;
        console_puts("YOLO32_ROCC"); field("worker",w); field("funct",f);
        field("count",s->count); field("cycles",s->cycles); field("max_cycles",s->max_cycles);
        console_puts("\r\n");
    }
#if YOLO32_ROCC_LAYERS
    for (unsigned w=0; w<3; ++w) for (unsigned stage=0; stage<YOLO32_GRAPH_STAGES; ++stage)
        for (unsigned i=0; i<2; ++i) {
            unsigned f=i ? 11U : 15U;
            const Yolo32LayerCommandStats *s=yolo32_layer_command_stats(w,stage,f);
            if (!s || !s->count) continue;
            console_puts("YOLO32_ROCC_LAYER"); field("worker",w); field("stage",stage); field("funct",f);
            console_puts(" kind="); console_puts(yolo32_stage_kind(stage));
            console_puts(" label="); console_puts(yolo32_stage_label(stage));
            field("count",s->count); field("cycles",s->cycles); field("max_cycles",s->max_cycles);
            field("max_index",s->max_index);
            const char *const n[]={"n20","n100","n1000"}, *const c[]={"c20","c100","c1000"};
            for (unsigned b=0; b<3; ++b) { field(n[b],s->slow_count[b]); field(c[b],s->slow_cycles[b]); }
            console_puts("\r\n");
        }
#endif
    if (mode == PARALLEL) {
        console_puts("YOLO32_GROUP_PROFILE"); field("submit_cycles", yolo32_parallel_submit_cycles());
        field("wait_cycles", yolo32_parallel_wait_cycles()); console_puts("\r\n");
    }
    if (mode == INDEPENDENT) {
        const Yolo32IndependentStats *s=yolo32_independent_stats();
        console_puts("YOLO32_SCHED_PROFILE"); field("step_cycles",s->step_cycles);
        field("scheduler_cycles",s->scheduler_cycles); field("ready_cycles",s->ready_cycles);
        field("ready_checks",s->ready_checks); field("ready_blocked",s->ready_blocked);
        field("idle_steps",s->idle_steps); field("switch_cycles",s->switch_cycles);
        field("scheduler_steps",s->scheduler_steps);
        field("idle_scheduler_cycles",s->idle_scheduler_cycles);
        field("active_scheduler_cycles",s->active_scheduler_cycles);
        field("switch_count",s->switch_count);
        field("policy_ready_cycles",s->policy_ready_cycles);
        field("policy_ready_checks",s->policy_ready_checks);
        field("max_quantum_cycles",s->max_quantum_cycles);
        field("saved_bytes",YOLO32_CONTEXT_SAVED_BYTES);
        field("vector_bytes",YOLO32_CONTEXT_VECTOR_BYTES); console_puts("\r\n");
        for (unsigned w=0; w<3; ++w) {
            console_puts("YOLO32_TASK_CPU"); field("worker",w);
            field("wall_cycles",s->task_wall_cycles[w]); field("context_cycles",s->context_cycles[w]);
            console_puts("\r\n");
        }
        for (unsigned w = 0; w < 3; ++w) for (unsigned s = 0; s < YOLO32_GRAPH_STAGES; ++s) {
            const Yolo32TaskStage *p = yolo32_independent_stage(w, s);
            console_puts("YOLO32_TASK_STAGE"); field("worker", w); field("stage", s);
            console_puts(" kind="); console_puts(yolo32_stage_kind(s));
            console_puts(" label="); console_puts(yolo32_stage_label(s));
            field("cpu_cycles", p->cpu_cycles); field("span_cycles", p->span_cycles); console_puts("\r\n");
        }
        const Yolo32IndependentStats *p = yolo32_independent_stats();
        for (unsigned t = 0; t < p->trace_count; ++t) {
            console_puts("YOLO32_AHEAD"); field("worker", p->traces[t].worker);
            field("busy_mask", p->traces[t].busy_mask);
            field("stage0", p->traces[t].stages[0]); field("stage1", p->traces[t].stages[1]);
            field("stage2", p->traces[t].stages[2]); console_puts("\r\n");
        }
        return;
    }
    for (unsigned s = 0; s < YOLO32_GRAPH_STAGES; ++s) {
        console_puts("YOLO32_STAGE"); field("stage", s);
        console_puts(" kind="); console_puts(yolo32_stage_kind(s));
        console_puts(" label="); console_puts(yolo32_stage_label(s));
        field("cycles", yolo32_stage_cycles(s)); console_puts("\r\n");
    }
}

static Timing run_all(int mode, const char *phase, unsigned round, unsigned analysis) {
    unsigned baseline=phase[0]=='b';
    if (!baseline && !reference_valid) yolo32_fail("missing_serial_reference");
    yolo32_set_analysis(analysis);
    console_puts("YOLO32_BEGIN run="); console_put_u32(++run_id);
    console_puts(" images=025,036,142 dim=32 workers=3 postprocess=hardware mode="); console_puts(mode_names[mode]);
    console_puts(" reference=serial phase="); console_puts(phase);
    field("round",round); field("profile",analysis); field("diagnostics",analysis);
    field("submit_burst",YOLO32_SUBMIT_BURST); field("quantum_us",YOLO32_QUANTUM_US);
    field("hot_paths",YOLO32_HOT_PATHS); field("rocc_layers",YOLO32_ROCC_LAYERS && analysis);
    field("fixed_plans",YOLO32_FIXED_PLANS);
    field("fixed_packets",YOLO32_FIXED_PACKETS);
    field("idle_priority",YOLO32_IDLE_PRIORITY); field("tail_wait",YOLO32_TAIL_WAIT);
    field("prepared_packets",YOLO32_PREPARED_PACKETS);
#if YOLO32_PPU_EARLY
    field("ppu_early",YOLO32_PPU_EARLY);
#if YOLO32_PPU_HEAD_CLEAN
    field("head_clean",YOLO32_PPU_HEAD_CLEAN); field("head_admit",YOLO32_PPU_HEAD_ADMIT);
#endif
#endif
    console_puts(" context=" YOLO32_CONTEXT_NAME " scheduling=" YOLO32_SCHED_NAME "\r\n");
    for (unsigned w=0;w<3;++w) { console_puts("YOLO32_START"); worker_image(w); console_puts("\r\n"); }
    Timing time={0,0,0}; uint64_t batch_start=read_cycle();
    if (mode==FORWARD || mode==REVERSE) {
        for(unsigned i=0;i<3;++i) {
            unsigned w=mode==FORWARD?i:2-i;
            uint64_t begin=read_cycle(); start_worker(w); while(!graph_poll(w)) {}
            time.graph+=read_cycle()-begin;
            begin=read_cycle(); finish_worker(w); time.post+=read_cycle()-begin;
        }
    } else if (mode == INDEPENDENT) {
        for (unsigned w=0; w<3; ++w) start_worker(w);
#if YOLO32_PPU_EARLY
        yolo32_ppu_early_begin(batch_start, analysis);
#endif
        yolo32_independent_begin(analysis);
        while (!yolo32_independent_step()) timeout(batch_start);
        yolo32_independent_end();
        time.graph=read_cycle()-batch_start;
        uint64_t begin=read_cycle();
#if !YOLO32_PPU_EARLY
        /* Original PPU drivers may now use their full hardware fences: the
         * independent graph has ended, so no worker is held at a layer. */
        for (unsigned w=0; w<3; ++w) {
            if (yolo32_independent_head_mask(w)!=63U) yolo32_fail("independent_heads");
            for (unsigned h=0; h<6; ++h) yolo32_ppu_head(w,h);
            yolo32_ppu_graph_done(w);
        }
#endif
        for (unsigned w=0; w<3; ++w) finish_worker(w);
        time.post=read_cycle()-begin;
    } else {
        for(unsigned w=0;w<3;++w) start_worker(w);
        if (mode==PARALLEL) {
            yolo32_parallel_begin(); int status;
            do {
                status=yolo32_parallel_step(unused_results); timeout(batch_start);
                if(status<0) yolo32_fail("parallel_step");
                yolo32_ppu_service();
            } while(!status);
        }
        unsigned ready=0;
        while(ready!=7U) for(unsigned w=0;w<3;++w)
            if(!(ready&(1U<<w)) && graph_poll(w)) ready|=1U<<w;
        time.graph=read_cycle()-batch_start;
        uint64_t begin=read_cycle();
        for(unsigned w=0;w<3;++w) finish_worker(w);
        time.post=read_cycle()-begin;
    }
    time.batch=read_cycle()-batch_start;
    uint64_t ppu_core=0; for(unsigned w=0;w<3;++w) ppu_core+=yolo32_ppu_result(w)->core_cycles;
    console_puts("YOLO32_TIMING"); field("batch_cycles",time.batch); field("graph_cycles",time.graph);
    field("ppu_tail_cycles",time.post); field("ppu_core_cycles",ppu_core); console_puts("\r\n");
#if YOLO32_PPU_EARLY
    if (mode == INDEPENDENT) {
        const Yolo32PpuEarlyStats *p=yolo32_ppu_early_stats();
        for (unsigned w=0; w<3; ++w) {
            const Yolo32PpuEvent *e=&p->workers[w];
            console_puts("YOLO32_PPU_EVENT"); field("worker",w);
            field("graph_done_cycles",e->graph_done_cycle-batch_start);
            field("publication_commit_cycles",e->publication_cycle-batch_start);
            field("enqueue_cycles",e->enqueue_cycle-batch_start);
            field("result_observed_cycles",e->result_cycle-batch_start);
            field("enqueue_done_mask",e->enqueue_done_mask); field("result_done_mask",e->result_done_mask);
            field("progress_cycles",e->progress_cycle ? e->progress_cycle-batch_start : 0);
            field("progress_done_mask",e->progress_done_mask); console_puts("\r\n");
        }
        console_puts("YOLO32_PPU_EARLY"); field("published_mask",p->published_mask);
        field("enqueued_mask",p->enqueued_mask); field("result_mask",p->result_mask);
        field("progress_mask",p->progress_mask); field("progress_sampling",analysis);
        field("service_calls",p->service_calls); field("service_cycles",p->service_cycles);
        console_puts("\r\n");
#if YOLO32_PPU_HEAD_CLEAN
        const Yolo32PpuHeadStats *heads=yolo32_ppu_head_stats();
        static const unsigned head_stage[6]={124,147,164,123,146,163};
        for (unsigned w=0;w<3;++w) {
            for (unsigned h=0;h<6;++h) {
                const Yolo32PpuHeadEvent *e=&heads->heads[w][h];
                console_puts("YOLO32_HEAD_EVENT"); field("worker",w); field("head",h);
                field("stage",head_stage[h]); field("requests",e->requests);
                field("completed_cycles",e->completed_cycle-batch_start);
                field("publication_commit_cycles",e->publication_cycle-batch_start);
                field("ready_observed_cycles",e->ready_cycle ? e->ready_cycle-batch_start : 0);
                console_puts("\r\n");
            }
            console_puts("YOLO32_HEAD_STATE"); field("worker",w);
            field("published_heads",heads->published_heads[w]);
            field("ready_at_finish",heads->ready_at_finish[w]);
            field("allocated_at_finish",heads->allocated_at_finish[w]);
            field("finish_sample_cycles",heads->finish_sample_cycle[w]-batch_start); console_puts("\r\n");
        }
        console_puts("YOLO32_HEAD_CLEAN"); field("head_admit",YOLO32_PPU_HEAD_ADMIT);
        field("publication_transactions",heads->publication_transactions);
        field("ready_sampling",analysis); console_puts("\r\n");
#endif
    }
#endif
    unsigned parallel_passed=1;
    if(mode==INDEPENDENT) {
        const Yolo32IndependentStats *s=yolo32_independent_stats();
        console_puts("YOLO32_INDEPENDENT"); field("done_mask",s->done_mask);
        for (unsigned w=0; w<3; ++w) {
            const char *const req[]={"requests0","requests1","requests2"};
            const char *const mm[]={"matmuls0","matmuls1","matmuls2"};
            const char *const rs[]={"resumes0","resumes1","resumes2"};
            const char *const wt[]={"wait_cycles0","wait_cycles1","wait_cycles2"};
            field(req[w],s->conv_requests[w]); field(mm[w],s->matmul_requests[w]);
            field(rs[w],s->resumes[w]); field(wt[w],s->wait_cycles[w]);
        }
        field("ahead_submissions",s->ahead_submissions);
        field("overlap_samples",s->overlap_samples); field("triple_overlap_samples",s->triple_overlap_samples);
        field("busy_mask_seen",s->busy_mask_seen); field("busy_sampling",analysis); console_puts("\r\n");
        console_puts("YOLO32_POLICY"); field("submit_burst",YOLO32_SUBMIT_BURST);
        field("quantum_us",YOLO32_QUANTUM_US);
        field("command_yields",s->command_yields); field("stage_yields",s->stage_yields);
        field("command_kept",s->command_kept); field("stage_kept",s->stage_kept);
        field("bootstrap_yields",s->bootstrap_yields); field("idle_yields",s->idle_yields);
        field("packet_yields",s->packet_yields); field("time_yields",s->time_yields);
        field("pressure_yields",s->pressure_yields);
        field("wait_yields",s->wait_yields); field("no_peer",s->no_peer);
        field("max_quantum_packets",s->max_quantum_packets);
        field("block_us",YOLO32_BLOCK_US); field("recover_us",YOLO32_RECOVER_US);
        field("fast_packets",YOLO32_FAST_PACKETS);
        field("feedback_commands",s->feedback_commands); field("feedback_cycles",s->feedback_cycles);
        field("dispatch_max_cycles",s->dispatch_max_cycles); field("slow_dispatches",s->slow_dispatches);
        field("burst_reductions",s->burst_reductions); field("burst_recoveries",s->burst_recoveries);
        field("cached_ready_hits",s->cached_ready_hits); console_puts("\r\n");
        if (YOLO32_IDLE_PRIORITY || YOLO32_TAIL_WAIT) {
            console_puts("YOLO32_TAIL_WAIT"); field("deferred",s->tail_deferred);
            field("merges",s->tail_wait_merges); field("conv",s->tail_conv_merges);
            field("ws",s->tail_ws_merges); console_puts("\r\n");
        }
        parallel_passed=s->done_mask==7 && s->conv_requests[0]>0 &&
            s->conv_requests[0]==s->conv_requests[1] && s->conv_requests[1]==s->conv_requests[2];
        for (unsigned w=0; w<3; ++w) parallel_passed &= s->resumes[w]>0 && s->matmul_requests[w]>0;
        if(analysis) parallel_passed &= s->ahead_submissions>0 && s->triple_overlap_samples>0 && s->busy_mask_seen==7;
        console_puts(!parallel_passed?"YOLO32_INDEPENDENT_RESULT FAIL\r\n":analysis?
            "YOLO32_INDEPENDENT_RESULT PASS\r\n":"YOLO32_INDEPENDENT_RESULT UNMEASURED\r\n");
    }
    if(mode==PARALLEL) {
        const Yolo32ParallelStats *s=yolo32_parallel_stats(); console_puts("YOLO32_PARALLEL");
        field("conv_groups",s->conv_groups); field("tile_groups",s->tile_groups);
        field("requests0",s->requests[0]); field("requests1",s->requests[1]); field("requests2",s->requests[2]);
        field("overlap_samples",s->overlap_samples); field("triple_overlap_samples",s->triple_overlap_samples);
        field("busy_mask_seen",s->busy_mask_seen); field("busy_sampling",analysis); console_puts("\r\n");
        parallel_passed=s->conv_groups==58 && s->tile_groups && s->requests[0]==s->tile_groups &&
            s->requests[1]==s->tile_groups && s->requests[2]==s->tile_groups;
        if(analysis) parallel_passed &= s->triple_overlap_samples>0 && s->busy_mask_seen==7;
        console_puts(!parallel_passed?"YOLO32_PARALLEL_RESULT FAIL\r\n":analysis?
            "YOLO32_PARALLEL_RESULT PASS\r\n":"YOLO32_PARALLEL_RESULT UNMEASURED\r\n");
    }
    unsigned passed=1;
    for(unsigned w=0;w<3;++w) { print_result(w); passed &= compare_result(w,baseline); }
    if(analysis) print_profiles(mode);
    if(baseline) reference_valid=1;
    if(!passed || !parallel_passed) ++run_failures;
    console_puts(!passed?"YOLO32_RESULT FAIL reason=serial_mismatch\r\n":!parallel_passed?
        "YOLO32_RESULT FAIL reason=parallel_evidence\r\n":"YOLO32_RESULT PASS workers=bit_exact reference=serial\r\n");
    return time;
}
static void ensure_reference(void) {
    if (!reference_valid) (void)run_all(FORWARD, "baseline", 0, 0);
}
static uint64_t median(uint64_t values[ROUNDS]) {
    for (unsigned i = 1; i < ROUNDS; ++i) {
        uint64_t v = values[i]; unsigned j = i;
        while (j && values[j-1] > v) { values[j] = values[j-1]; --j; }
        values[j] = v;
    }
    return values[ROUNDS/2];
}
static void profile_all(void) {
    ensure_reference();
    for (int mode = 0; mode < MODES; ++mode) (void)run_all(mode, "analysis", 0, 1);
}
static void profile_layers(void) {
#if YOLO32_ROCC_LAYERS
    ensure_reference();
    (void)run_all(FORWARD,"analysis",0,1);
    (void)run_all(INDEPENDENT,"analysis",0,1);
#else
#if YOLO32_PPU_HEAD_CLEAN
    console_puts(YOLO32_PPU_HEAD_ADMIT ? "Use download.sh --ppu-head-class0-rocc for q diagnostics\r\n" :
                 "Use download.sh --ppu-head-clean-rocc for q diagnostics\r\n");
#elif YOLO32_PPU_EARLY
            console_puts("Use download.sh --ppu-early-rocc for q diagnostics\r\n");
#elif YOLO32_PREPARED_PACKETS
    console_puts("Use download.sh --prepared-packets-rocc for layer diagnosis\r\n");
#elif YOLO32_IDLE_PRIORITY || YOLO32_TAIL_WAIT
    console_puts("Use download.sh --scheduled-packets-rocc for layer diagnosis\r\n");
#elif YOLO32_FIXED_PACKETS
    console_puts("Use download.sh --fixed-packets-rocc for layer diagnosis\r\n");
#elif YOLO32_FIXED_PLANS
    console_puts("Use download.sh --fixed-plans-rocc for layer diagnosis\r\n");
#else
    console_puts("Use download.sh --rocc-layers for layer diagnosis\r\n");
#endif
#endif
}
static void benchmark(void) {
    uint64_t batch[MODES][ROUNDS], graph[MODES][ROUNDS], med_batch[MODES], med_graph[MODES];
    unsigned failures = run_failures;
    reference_valid = 0; ensure_reference();
    console_puts("YOLO32_BENCH_BEGIN rounds=5 warmups=1 modes=5 clock_hz=100000000\r\n");
    for (int mode = 0; mode < MODES; ++mode) (void)run_all(mode, "warmup", 0, 0);
    for (unsigned r = 0; r < ROUNDS; ++r) {
        /* Rotate order to reduce order/cache bias. */
        for (unsigned i = 0; i < MODES; ++i) {
            int mode = (int)((i + r) % MODES);
            Timing t = run_all(mode, "measure", r+1, 0);
            batch[mode][r] = t.batch; graph[mode][r] = t.graph;
        }
    }
    for (unsigned m = 0; m < MODES; ++m) {
        med_batch[m] = median(batch[m]); med_graph[m] = median(graph[m]);
    }
    for (unsigned m = 0; m < MODES; ++m) {
        console_puts("YOLO32_BENCH mode="); console_puts(mode_names[m]);
        field("samples", ROUNDS); field("median_batch_cycles", med_batch[m]);
        field("median_graph_cycles", med_graph[m]);
        field("speedup_batch_milli", med_batch[FORWARD] * 1000 / med_batch[m]);
        field("speedup_graph_milli", med_graph[FORWARD] * 1000 / med_graph[m]);
        field("fps_milli", (uint64_t)SOC_CLOCK_HZ * 3000 / med_batch[m]); console_puts("\r\n");
    }
    profile_all();
    console_puts(run_failures == failures ? "YOLO32_BENCH_RESULT PASS\r\n" : "YOLO32_BENCH_RESULT FAIL\r\n");
}
int main(void) {
    console_init();
    console_puts("\r\nYOLO32_FIRMWARE " YOLO32_FIRMWARE_VERSION " dim=32 workers=3 clock_hz=100000000 "
        "input=640x480x3 images=025,036,142 scale=fp16 postprocess=hardware head=uram\r\n");
    console_puts("YOLO32_SCHED_CONFIG"); field("submit_burst",YOLO32_SUBMIT_BURST);
    field("quantum_us",YOLO32_QUANTUM_US);
    field("hot_paths",YOLO32_HOT_PATHS); field("rocc_layers",YOLO32_ROCC_LAYERS);
    field("fixed_plans",YOLO32_FIXED_PLANS);
    field("fixed_packets",YOLO32_FIXED_PACKETS);
    field("idle_priority",YOLO32_IDLE_PRIORITY); field("tail_wait",YOLO32_TAIL_WAIT);
    field("prepared_packets",YOLO32_PREPARED_PACKETS);
#if YOLO32_PPU_EARLY
    field("ppu_early",YOLO32_PPU_EARLY);
#if YOLO32_PPU_HEAD_CLEAN
    field("head_clean",YOLO32_PPU_HEAD_CLEAN); field("head_admit",YOLO32_PPU_HEAD_ADMIT);
#endif
#endif
    field("saved_bytes",YOLO32_CONTEXT_SAVED_BYTES); field("vector_bytes",YOLO32_CONTEXT_VECTOR_BYTES);
    console_puts(" context=" YOLO32_CONTEXT_NAME " vcsr=preserved scheduling=" YOLO32_SCHED_NAME);
    field("block_us",YOLO32_BLOCK_US); field("recover_us",YOLO32_RECOVER_US);
    field("fast_packets",YOLO32_FAST_PACKETS); console_puts("\r\n");
    yolo32_init(); yolo32_ppu_init(); yolo32_set_head_callback(yolo32_ppu_head); help();
    for(;;) {
        int c=console_getc_nonblock();
        if(c=='a') benchmark();
        else if(c=='p') profile_all();
        else if(c=='q') profile_layers();
        else if(c=='t'||c=='l'||c=='u'||c=='U'||c=='b') {
            ensure_reference(); int mode=c=='t'?INDEPENDENT:c=='l'?PARALLEL:c=='u'?FORWARD:c=='U'?REVERSE:BLOCKED;
            (void)run_all(mode,"manual",0,0);
        } else if(c>='0'&&c<='2') {
            unsigned w=(unsigned)(c-'0'); ++run_id; yolo32_set_analysis(0);
            start_worker(w); while(!graph_poll(w)) {} finish_worker(w); print_result(w);
            console_puts("YOLO32_SINGLE DONE\r\n");
        } else if(c=='h') help();
    }
}
