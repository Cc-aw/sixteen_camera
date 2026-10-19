/* Private original-layout network benchmark on one runtime-selectable image.
 * Reuse the validated V34 scheduler, plans, Head/PPU comparisons and boundary
 * windows; the frozen production entry and its defaults are unchanged. */
#ifdef __riscv
#include "dma_load_identity.h"
#include "board_identity.h"
#define DMA_LOAD_BENCHMARK 1
static unsigned dma_load_whole_window;
#endif
#define main dma_load_v34_unused_main
#include "boundary_main.c"
#undef main

#ifdef __riscv
#include "dma_load_suite.h"
static const volatile uint64_t dma_expected_build_id=DMA_LOAD_EXPECTED_BUILD_ID;
static uint32_t dma_counts[LANES][DMA_LAST_COUNTER+1];
static uint64_t dma_identity;
static unsigned dma_mode_count;

static void dma_select(unsigned mode) {
    gf_publish();
    for(unsigned lane=0;lane<LANES;lane++) {
        uint64_t status=gf_status(lane);
        if(status&(GF_OWNED|GF_GEMMINI_BUSY|GF_FAULT|GF_ARMED))at_fail("dma_mode_not_drained",status);
        if(gf_read(lane,7,0)!=(dma_mode_count==4?UINT64_C(0x1000f):UINT64_C(0x10007)))at_fail("dma_capability",lane);
        if(gf_read(lane,10,0)!=dma_identity)at_fail("dma_build_identity",lane);
        if(gf_set_dma_load_mode(lane,mode,0)||gf_read(lane,8,0)!=mode)at_fail("dma_mode_switch",lane);
    }
    gf_publish();
}
static void dma_count_begin(void) {
    for(unsigned lane=0;lane<LANES;lane++)(void)memory_counter_access(lane,1);
}
static void dma_count_end(void) {
    for(unsigned lane=0;lane<LANES;lane++) {
        if(gf_status(lane)&(GF_OWNED|GF_GEMMINI_BUSY))at_fail("dma_count_while_busy",lane);
        for(unsigned id=DMA_FIRST_COUNTER;id<=DMA_LAST_COUNTER;id++) {
            (void)memory_counter_access(lane,UINT32_C(0x80000008)|(id<<12));
            dma_counts[lane][id]=memory_counter_access(lane,0);
        }
    }
}
static void dma_report_counters(unsigned mode,unsigned round,unsigned warmup) {
    for(unsigned lane=0;lane<LANES;lane++) {
        text("DMAL1,COUNTERS,mode=");text(dma_modes[mode]);field(",round=",round);
        field(",warmup=",warmup);field(",executor=",executor);field(",lane=",lane);
        field(",build_id=",dma_identity);field(",actual_mode=",gf_read(lane,8,0));
        field(",mode_switch_rejects=",gf_read(lane,9,0));
        for(unsigned id=DMA_FIRST_COUNTER;id<=DMA_LAST_COUNTER;id++) {
            text(",c");number(id);text("=");number(dma_counts[lane][id]);
        }
        text("\n");
    }
}
static uint64_t dma_batch(unsigned mode,unsigned round,unsigned warmup,unsigned count) {
    uint32_t run_before=ppu_run_sequence;
    text("DMAL1,BATCH_BEGIN,mode=");text(dma_modes[mode]);field(",round=",round);
    field(",warmup=",warmup);field(",executor=",executor);
    field(",run_before=",run_before);field(",frames=",count);text("\n");
    run_frames=count;prepare_batch();dma_count_begin();
    batch_begin=clock_cycle();
    if(executor)parallel_batch(executor==2?LANES:1);else serial_batch();
    uint64_t elapsed=clock_cycle()-batch_begin;
    dma_count_end();
    if(completed!=count||host_calls!=count*12)at_fail("dma_batch_incomplete",completed);
    if(ppu_run_sequence-run_before!=count)at_fail("dma_run_sequence",ppu_run_sequence);
    unsigned bad=report(executor);
    if(bad) {
        boundary_report(executor);
        text("DMAL1,CHECK_FAILED,mode=");text(dma_modes[mode]);field(",round=",round);
        field(",warmup=",warmup);field(",executor=",executor);field(",bad_frames=",bad);
        field(",run_first=",run_before+1);field(",run_last=",ppu_run_sequence);field(",cycles=",elapsed);text("\n");
        dma_report_counters(mode,round,warmup);
        at_fail("dma_output_mismatch",mode);
    }
    text("DMAL1,RESULT,mode=");text(dma_modes[mode]);field(",round=",round);
    field(",warmup=",warmup);field(",executor=",executor);field(",cycles=",elapsed);
    field(",frames=",count);text(",ppu_results_bit_exact=1,comparison=legacy_direct,scope=full_graph");
    field(",run_first=",run_before+1);field(",run_last=",ppu_run_sequence);text("\n");
    dma_report_counters(mode,round,warmup);
    return elapsed;
}
#endif

int main(int argc,char **argv) {
#ifndef __riscv
    return dma_load_v34_unused_main(argc,argv);
#else
    (void)argc;(void)argv;
    volatile uint32_t *uart=(volatile uint32_t *)AT_UART_BASE;
    uart[2]=1;uart[4]=0;uart[6]=867;
    dma_identity=gf_read(0,10,0);
    if(dma_identity!=dma_expected_build_id)at_fail("dma_identity_mismatch",dma_identity);
    uint64_t capability=gf_read(0,7,0);
    if(capability!=UINT64_C(0x10007)&&capability!=UINT64_C(0x1000f))at_fail("dma_capability",capability);
    dma_mode_count=capability==UINT64_C(0x1000f)?4:3;
    if(DMA_REQUIRE_SPAD_ONLY&&dma_mode_count!=4)at_fail("dma_spad_only_requires_new_bitstream",capability);
    text("DMAL1,BUILD,schema=2,suite=short_ablation,rounds=1,load_modes=");number(dma_mode_count);
    text(",executors=2,frames=12,warmup_frames=3,phase_diagnostics=0,clock_hz=100000000,l2_kib=512,l2_banks=2,layout=original,firmware_revision=3,ppu_runs=monotonic,failure_diagnostics=1,ablation=");
    text(dma_mode_count==4?"complete":"missing_spad_only");
    text(",package_build=" DMA_BOARD_BUILD_ID "\n");
    dma_select(0);prepare_model();ppu_init();memory_init();
    if(!memory_available||memory_abi!=UINT64_C(0x4d50563300010001))at_fail("dma_requires_512kib_2bank",memory_abi);
    dma_load_whole_window=1;
    // Twelve direct legacy outputs are retained as the immutable PPU golden.
    executor=0;(void)dma_batch(0,0,1,DMA_MEASURE_FRAMES);
    uint64_t totals[DMA_MAX_MODES][2]={{0}};
    // IDs 2 and 3 deliberately mean combined and SPAD-only respectively.
    for(unsigned order=0;order<dma_mode_count;order++) {
        unsigned mode=order;
        dma_select(mode);
        for(executor=1;executor<=2;executor++) {
            (void)dma_batch(mode,0,1,DMA_WARMUP_FRAMES);
            totals[mode][executor-1]=dma_batch(mode,0,0,DMA_MEASURE_FRAMES);
        }
    }
    for(unsigned mode=0;mode<dma_mode_count;mode++) {
        text("DMAL1,SUMMARY,mode=");text(dma_modes[mode]);
        field(",frames=",DMA_MEASURE_FRAMES);
        field(",serial_cycles=",totals[mode][0]);field(",parallel_cycles=",totals[mode][1]);
        field(",scaling_x1000=",totals[mode][0]*1000/totals[mode][1]);
        field(",serial_gain_x1000=",totals[0][0]*1000/totals[mode][0]);
        field(",parallel_gain_x1000=",totals[0][1]*1000/totals[mode][1]);text("\n");
    }
    dma_select(0);
    field("DMAL1,PASS,build_id=",dma_identity);
    field(",measured_records=",dma_mode_count*2);field(",warmup_records=",dma_mode_count*2+1);
    field(",load_modes=",dma_mode_count);
    text(",serial_parallel=checked,ppu_results_bit_exact=1,phase_diagnostics=0,ablation=");
    text(dma_mode_count==4?"complete":"missing_spad_only");
    field(",ppu_runs=",ppu_run_sequence);text("\n");
    for(;;)__asm__ volatile("wfi");
#endif
}
