/* Original RGB first-layer A/B: no input or weight reordering in any mode. */
#define main dma_load_s2d_unused_main
#include "first_layer_s2d_main.c"
#undef main
#include "dma_load_identity.h"

static const char *const dma_first_modes[3]={"legacy","read_coalesced","read_assembled"};
static const volatile uint64_t dma_expected_build_id=DMA_LOAD_EXPECTED_BUILD_ID;
static void dma_first_select(unsigned mode) {
    gf_publish();
    for(unsigned lane=0;lane<LANES;lane++) {
        if(gf_read(lane,7,0)!=UINT64_C(0x10007)||gf_read(lane,10,0)!=dma_expected_build_id)
            fail("dma_hardware_identity",lane);
        uint64_t begin=cycle();
        while(gf_status(lane)&(GF_OWNED|GF_GEMMINI_BUSY|GF_FAULT|GF_ARMED)) {
            if(cycle()-begin>10000000)fail("dma_not_drained",lane);
        }
        require(gf_set_dma_load_mode(lane,mode,0),"dma_mode_set");
        if(gf_read(lane,8,0)!=mode)fail("dma_mode_readback",lane);
    }
}
static uint64_t dma_first_run(unsigned mode,unsigned parallel,unsigned round,unsigned warmup) {
    text("DMALF1,WINDOW,mode=");text(dma_first_modes[mode]);
    field(",round=",round);field(",warmup=",warmup);field(",parallel=",parallel);text("\n");
    uint64_t elapsed=run(0,parallel,round,warmup);
    for(unsigned lane=0;lane<LANES;lane++) {
        (void)counter(lane,2); /* release the run() snapshot */
        text("DMALF1,COUNTERS,mode=");text(dma_first_modes[mode]);
        field(",round=",round);field(",warmup=",warmup);field(",parallel=",parallel);
        field(",lane=",lane);field(",actual_mode=",gf_read(lane,8,0));
        field(",mode_switch_rejects=",gf_read(lane,9,0));
        for(unsigned id=8;id<=34;id++) {
            (void)counter(lane,UINT32_C(0x80000008)|(id<<12));
            text(",c");field("",id);field("=",counter(lane,0));
        }
        text("\n");
    }
    return elapsed;
}
int main(void) {
    volatile uint32_t *uart=(volatile uint32_t *)AT_UART_BASE;
    uart[2]=1;uart[4]=0;uart[6]=867;
    field("DMALF1,BUILD,schema=1,build_id=",DMA_LOAD_EXPECTED_BUILD_ID);
    text(",rounds=4,modes=3,executors=2,frames_per_batch=3,clock_hz=100000000,l2_kib=512,l2_banks=2,layout=original\n");
    dma_first_select(0);
    for(unsigned lane=0;lane<LANES;lane++) {
        GF_DIRECT(lane,7,UINT64_C(0),UINT64_C(0));gf_publish();lut(lane);
    }
    for(unsigned image=0;image<LANES;image++) {
        memset(gold[image].before,0xc3,64);memset(gold[image].after,0x3c,64);
        memset(outputs[image].before,0xc3,64);memset(outputs[image].after,0x3c,64);
        memset(gold[image].data,0xa5,OUTPUT_BYTES);
        build(0,image,image,gold[image].data);launch(0,image,0);wait_lanes(1);
        guards(gold[image].before,gold[image].after);
    }
    uint64_t totals[3][2]={{0}};
    for(unsigned iteration=0;iteration<=ROUNDS;iteration++) {
        unsigned warmup=iteration==0,round=warmup?0:iteration-1;
        for(unsigned order=0;order<3;order++) {
            unsigned mode=iteration&1?2-order:order;
            dma_first_select(mode);current_round=round;
            if(!warmup)for(unsigned parallel=0;parallel<2;parallel++)
                (void)dma_first_run(mode,parallel,round,1);
            for(unsigned parallel=0;parallel<2;parallel++) {
                uint64_t elapsed=dma_first_run(mode,parallel,round,warmup);
                if(!warmup)totals[mode][parallel]+=elapsed;
            }
        }
    }
    for(unsigned mode=0;mode<3;mode++) {
        text("DMALF1,SUMMARY,mode=");text(dma_first_modes[mode]);
        field(",serial_cycles=",totals[mode][0]);field(",parallel_cycles=",totals[mode][1]);
        field(",scaling_x1000=",totals[mode][0]*1000/totals[mode][1]);
        field(",serial_gain_x1000=",totals[0][0]*1000/totals[mode][0]);
        field(",parallel_gain_x1000=",totals[0][1]*1000/totals[mode][1]);text("\n");
    }
    dma_first_select(0);
    text("DMALF1,PASS,measured_records=24,warmup_records=30,full_output_bit_exact=1,scope=first_conv\n");
    for(;;)__asm__ volatile("wfi");
}
