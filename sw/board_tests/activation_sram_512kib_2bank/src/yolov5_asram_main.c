/* Same frozen YOLO graph and schedule, two activation backing profiles. */
#ifdef __riscv
#define DMA_LOAD_BENCHMARK 1
static unsigned dma_load_whole_window;
#endif
#define main yolo_boundary_unused_main
#include "yolo_boundary.c"
#undef main

#ifdef __riscv
#include "dma_load_suite.h"
static const volatile uint64_t expected_yolo_hardware=EXPECTED_HW_ID;
static uint64_t local_counts[3][2][20];
static uint32_t gemmini_counts[3][35];
static unsigned suite_round,suite_mode,suite_warmup,batch_sequence;
static uint64_t plan_signature;
#if YOLO_DIAGNOSTIC
static uint8_t head_gold[3][YOLOV5NU_HEAD_PAYLOAD_BYTES] __attribute__((aligned(64)));
static uint8_t pad_gold[3][6][38400] __attribute__((aligned(64)));
static unsigned head_gold_ready[3],pad_gold_ready[3][6],pad_sizes[3][6];
static unsigned pad_checks[FRAMES],pad_bytes[FRAMES],head_checks[FRAMES];
static void diagnostic_compare(volatile const uint8_t *actual,uint8_t *gold,size_t n,
                               unsigned *ready,const char *reason) {
    if(!*ready) {
        if(reference_ready)at_fail("missing_raw_golden",current_frame);
        for(size_t i=0;i<n;i++)gold[i]=actual[i];
        *ready=1;
    } else for(size_t i=0;i<n;i++)if(actual[i]!=gold[i]) {
        text("ASRY1,DIFF,kind=");text(reason);field(",frame=",current_frame);
        field(",lane=",current_lane);field(",offset=",i);
        field(",expected=",gold[i]);field(",actual=",actual[i]);text("\n");
        at_fail(reason,i);
    }
}
#endif
static void yolo_diag_pad(unsigned f,const struct Host *h) {
#if YOLO_DIAGNOSTIC
    unsigned image=frames[f].image,index=pad_checks[f]++;
    size_t bytes=(size_t)h->h*h->w*h->c;
    if(index>=6 || !bytes || bytes>38400)at_fail("diagnostic_pad_range",bytes);
    if(!pad_gold_ready[image][index])pad_sizes[image][index]=bytes;
    if(pad_sizes[image][index]!=bytes)at_fail("diagnostic_pad_geometry",index);
    diagnostic_compare((const uint8_t *)h->src,pad_gold[image][index],bytes,
        &pad_gold_ready[image][index],"raw_pad_mismatch");
    pad_bytes[f]+=bytes;
#else
    (void)f;(void)h;
#endif
}
static void yolo_diag_head(unsigned f) {
#if YOLO_DIAGNOSTIC
    struct Frame *t=&frames[f];current_frame=f;current_lane=t->device;
    if(pad_checks[f]!=6)at_fail("diagnostic_pad_count",f);
    diagnostic_compare((const uint8_t *)head_address(t->device,t->slot),head_gold[t->image],
        YOLOV5NU_HEAD_PAYLOAD_BYTES,&head_gold_ready[t->image],"raw_head_mismatch");
    head_checks[f]=1;
#else
    (void)f;
#endif
}
static uint64_t asram_reg(unsigned offset) {
    return *(volatile uint64_t *)(uintptr_t)(ASRAM_CONTROL_BASE+offset);
}
static void asram_action(unsigned value) {
    *(volatile uint64_t *)(uintptr_t)(ASRAM_CONTROL_BASE+0x40)=value;
    gf_publish();uint64_t begin=clock_cycle();
    while(asram_reg(0x40))if(clock_cycle()-begin>1000000)at_fail("asram_action_timeout",value);
}
static void hardware_check(void) {
    uint64_t vlenb;__asm__ volatile("csrr %0,vlenb":"=r"(vlenb));
    if(vlenb!=32)at_fail("rvv_vlenb",vlenb);
    for(unsigned lane=0;lane<3;lane++) {
        if(gf_read(lane,10,0)!=expected_yolo_hardware)at_fail("hardware_identity",lane);
        if(gf_read(lane,7,0)!=0x1000f)at_fail("four_dma_modes_required",lane);
        uint64_t status=gf_status(lane);
        if((status>>32)!=0x20000 || !(status&GF_START_READY) ||
           (status&(GF_OWNED|GF_DONE|GF_HOST_WAIT|GF_FAULT|GF_ARMED|GF_GEMMINI_BUSY)))
            at_fail("frontend_not_clean",status);
    }
    arena_caps=(ActivationSramCapabilities){.magic=asram_reg(0),.abi=asram_reg(8),
        .enabled_mask=asram_reg(0x10),.physical_bytes=asram_reg(0x18),
        .logical_bytes=asram_reg(0x20),.data_width_bits=asram_reg(0x28),
        .clock_hz=asram_reg(0x30),.base={asram_reg(0x48),asram_reg(0x50),asram_reg(0x58)}};
    if(!activation_memory_capabilities_valid(&arena_caps) || asram_reg(0x38)!=2)
        at_fail("asram_capability",arena_caps.magic);
}
static int all_idle(void) {
    gf_publish();
    for(unsigned lane=0;lane<3;lane++)if(gf_status(lane)&
        (GF_OWNED|GF_DONE|GF_HOST_WAIT|GF_FAULT|GF_ARMED|GF_GEMMINI_BUSY|GF_FENCE_BUSY))return 0;
    return !ppu_pending_mask && !ppu_queue.ready_count && ppu_queue.active==AI_HEAD_SLOT_INVALID;
}
static void select_mode(unsigned mode) {
    if(!all_idle())at_fail("mode_not_quiescent",mode);
    for(unsigned lane=0;lane<3;lane++)if(gf_set_dma_load_mode(lane,mode,0) || gf_read(lane,8,0)!=mode)
        at_fail("dma_mode_switch",lane);
}
static uint64_t normalized_plan_hash(void) {
    uint64_t hash=UINT64_C(1469598103934665603);
    struct Plan *p=&plans[0][0][0];
    for(unsigned i=0;i<p->count;i++) {
        GfCommand c=normalize(p->commands[i],0,0,0);
        const uint8_t *bytes=(const uint8_t *)&c;
        for(unsigned j=0;j<sizeof(c);j++){hash^=bytes[j];hash*=UINT64_C(1099511628211);}
    }
    return hash;
}
static void prepare_profile(unsigned profile) {
    uint64_t begin=clock_cycle();
    yolo_bind_storage(profile,all_idle());prepare_model();
    uint64_t hash=normalized_plan_hash();
    if(plan_signature && hash!=plan_signature)at_fail("storage_plan_math_changed",hash);
    plan_signature=hash;
    text("ASRY1,PROFILE,storage=");text(storage_name(profile));field(",round=",suite_round);
    field(",prepare_cycles=",clock_cycle()-begin);field(",plan_hash=",hash);
    text(",tables=18,entries=10870,raw=10478,hosts=12,arena_bytes=2217600\n");
}
static void count_begin(void) {
    asram_action(2);
    for(unsigned lane=0;lane<3;lane++)(void)memory_counter_access(lane,1);
}
static void count_end(unsigned active_lanes) {
    if(!all_idle())at_fail("batch_not_quiescent",completed);
    asram_action(1);
    for(unsigned lane=0;lane<3;lane++) {
        for(unsigned port=0;port<2;port++) {
            if(asram_reg(0x60+(lane*2+port)*8))at_fail("asram_outstanding",lane*2+port);
            uint64_t *c=local_counts[lane][port];
            for(unsigned i=0;i<20;i++)c[i]=asram_reg(0x100+lane*0x400+port*0x100+i*8);
            if(c[0]!=c[1] || c[15] || c[16])at_fail("asram_error_counters",lane*2+port);
            if((!storage_profile || lane>=active_lanes) && c[0])at_fail("unexpected_local_traffic",lane*2+port);
        }
        if(storage_profile && lane<active_lanes &&
            (!local_counts[lane][0][2] || !(local_counts[lane][0][3]+local_counts[lane][0][4]) ||
             !local_counts[lane][1][2]))at_fail("local_arena_not_used",lane);
        for(unsigned id=DMA_FIRST_COUNTER;id<=DMA_LAST_COUNTER;id++) {
            (void)memory_counter_access(lane,UINT32_C(0x80000008)|(id<<12));
            gemmini_counts[lane][id]=memory_counter_access(lane,0);
        }
    }
}
static void batch_fields(void) {
    field(",sequence=",batch_sequence);field(",round=",suite_round);
    text(",storage=");text(storage_name(storage_profile));field(",mode=",suite_mode);
    field(",executor=",executor);field(",warmup=",suite_warmup);
}
static void report_counts(void) {
    for(unsigned lane=0;lane<3;lane++) {
        for(unsigned port=0;port<2;port++) {
            text("ASRY1,ASRAM");batch_fields();field(",lane=",lane);field(",port=",port);
            for(unsigned i=0;i<20;i++){text(",c");number(i);text("=");number(local_counts[lane][port][i]);}
            text(",pending=0\n");
        }
        text("ASRY1,DMA");batch_fields();field(",lane=",lane);
        field(",actual_mode=",gf_read(lane,8,0));field(",mode_rejects=",gf_read(lane,9,0));
        for(unsigned id=DMA_FIRST_COUNTER;id<=DMA_LAST_COUNTER;id++) {
            text(",c");number(id);text("=");number(gemmini_counts[lane][id]);
        }
        text("\n");
    }
}
static uint64_t run_batch(unsigned warmup,unsigned count) {
    suite_warmup=warmup;batch_sequence++;
    uint32_t first=ppu_run_sequence+1;
    text("ASRY1,BATCH_BEGIN");batch_fields();field(",frames=",count);
    field(",run_before=",ppu_run_sequence);text("\n");
    run_frames=count;prepare_batch();
#if YOLO_DIAGNOSTIC
    memset(pad_checks,0,sizeof(pad_checks));memset(pad_bytes,0,sizeof(pad_bytes));memset(head_checks,0,sizeof(head_checks));
#endif
    count_begin();batch_begin=clock_cycle();
    if(executor)parallel_batch(executor==2?3:1);else serial_batch();
    uint64_t elapsed=clock_cycle()-batch_begin;
    unsigned active=executor==2?3:1;count_end(active);yolo_check_guards();
    if(completed!=count || host_calls!=count*12 || ppu_run_sequence-first+1!=count ||
       (executor && launches!=count))at_fail("incomplete_batch",completed);
    for(unsigned lane=0;lane<3;lane++)if(use[lane]!=(lane<active?count/active:0))at_fail("lane_frame_quota",lane);
    unsigned bad=report(executor);
    if(bad) {report_counts();boundary_report(executor);at_fail("ppu_output_mismatch",bad);}
#if YOLO_DIAGNOSTIC
    for(unsigned f=0;f<count;f++) {
        if(!head_checks[f] || pad_checks[f]!=6)at_fail("raw_checks_missing",f);
        text("ASRY1,RAW_CHECK");batch_fields();field(",frame=",f);
        field(",head_bytes=",YOLOV5NU_HEAD_PAYLOAD_BYTES);field(",pad_bytes=",pad_bytes[f]);text(",match=1\n");
    }
#endif
    text("ASRY1,RESULT");batch_fields();field(",frames=",count);field(",cycles=",elapsed);
    field(",run_first=",first);field(",run_last=",ppu_run_sequence);text(",ppu_bit_exact=1,guards=1\n");
    report_counts();return elapsed;
}
#endif

int main(int argc,char **argv) {
#ifndef __riscv
    return yolo_boundary_unused_main(argc,argv);
#else
    (void)argc;(void)argv;
    volatile uint32_t *uart=(volatile uint32_t *)AT_UART_BASE;uart[2]=1;uart[4]=0;uart[6]=867;
    hardware_check();
    text("ASRY1,BUILD,schema=1,hardware=1,hardware_id=" EXPECTED_HW_ID_TEXT ",package=" PACKAGE_ID);
    field(",rounds=",YOLO_ROUNDS);field(",diagnostic=",YOLO_DIAGNOSTIC);
    text(",frames=12,warmup_frames=3,modes=4,profiles=2,executors=3,clock_hz=100000000,layout=original,ppu_runs=monotonic\n");
    ppu_init();memory_init();dma_load_whole_window=1;
    if(!memory_available || memory_abi!=UINT64_C(0x4d50563300010001))at_fail("memory_abi",memory_abi);
    select_mode(0);prepare_profile(0);executor=0;suite_mode=0;
    (void)run_batch(1,FRAMES);memcpy(reference_output,output[0],sizeof(reference_output));reference_ready=1;
    uint64_t cycles[YOLO_ROUNDS][2][4][3]={0};
    for(suite_round=0;suite_round<YOLO_ROUNDS;suite_round++)for(unsigned order=0;order<2;order++) {
        unsigned profile=order^(suite_round&1);prepare_profile(profile);
        for(suite_mode=0;suite_mode<4;suite_mode++) {
            select_mode(suite_mode);
            for(executor=0;executor<3;executor++) {
                (void)run_batch(1,3);
                cycles[suite_round][profile][suite_mode][executor]=run_batch(0,FRAMES);
            }
        }
    }
    for(unsigned round=0;round<YOLO_ROUNDS;round++)for(unsigned mode=0;mode<4;mode++)for(unsigned e=0;e<3;e++) {
        text("ASRY1,SUMMARY");field(",round=",round);field(",mode=",mode);field(",executor=",e);
        field(",ddr_cycles=",cycles[round][0][mode][e]);field(",local_cycles=",cycles[round][1][mode][e]);
        field(",gain_x1000=",cycles[round][0][mode][e]*1000/cycles[round][1][mode][e]);text("\n");
    }
    select_mode(0);
    if(ppu_run_sequence!=12+360*YOLO_ROUNDS)at_fail("suite_ppu_run_count",ppu_run_sequence);
    text("ASRY1,PASS");field(",rounds=",YOLO_ROUNDS);field(",diagnostic=",YOLO_DIAGNOSTIC);
    field(",measured_records=",24*YOLO_ROUNDS);field(",warmup_records=",24*YOLO_ROUNDS+1);
    field(",ppu_runs=",ppu_run_sequence);text(",ppu_bit_exact=1,guards=1\n");
    for(;;)__asm__ volatile("wfi");
#endif
}
