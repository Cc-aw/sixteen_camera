#include <stdint.h>
#include <stddef.h>
#define GEMMINI_POOL_RUNTIME_DISPATCH 1
#define GEMMINI_POOL_COMMAND_STATS 1
#define GEMMINI_LOOPCONV_CREDIT_ADMISSION 1
#define GEMMINI_LOOPCONV_WORKER1_STATUS_CSR 0x7c5
#define GEMMINI_LOOPCONV_WORKER1_ACCEPTED_CSR 0x7c8
#define GEMMINI_LOOPCONV_WORKER1_RETIRED_CSR 0x7c9
#define GEMMINI_LOOPCONV_WORKER2_STATUS_CSR 0x7cb
#define GEMMINI_LOOPCONV_WORKER2_ACCEPTED_CSR 0x7cc
#define GEMMINI_LOOPCONV_WORKER2_RETIRED_CSR 0x7cd
static void credit_timeout(uint64_t status, uint64_t elapsed);
static void command_returned(unsigned funct);
static void command_args(unsigned funct, uint64_t rs1, uint64_t rs2);
#define GEMMINI_POOL_COMMAND_ARGS_HOOK(f, a, b) command_args(f, (uint64_t)(a), (uint64_t)(b))
static void diagnostic_fence(void);
static void credit_granted(uint64_t elapsed);
#define GEMMINI_POOL_COMMAND_RETURN_HOOK(f) command_returned(f)
#define GEMMINI_LOOPCONV_CREDIT_WAIT_HOOK(c) credit_granted(c)
#define gemmini_fence() diagnostic_fence()
#define GEMMINI_LOOPCONV_CREDIT_WAIT_TIMEOUT_CYCLES 1000000000ULL
#define GEMMINI_LOOPCONV_CREDIT_WAIT_TIMEOUT_HOOK(s, c) credit_timeout(s, c)
#include "include/gemmini.h"
#include "board/board_runtime.h"

_Static_assert(DIM == 64, "This test requires DIM64");
unsigned gemmini_pool_active_worker;
static elem_t a[DIM][DIM] __attribute__((aligned(64)));
static elem_t b[DIM][DIM] __attribute__((aligned(64)));
static volatile elem_t out[DIM][DIM] __attribute__((aligned(64)));
static uint64_t cycles(void) { uint64_t v; asm volatile("rdcycle %0":"=r"(v)); return v; }
void *memset(void *p, int v, size_t n) { unsigned char *q=p; while(n--) *q++=v; return p; }
void runtime_trap(uint64_t cause, uint64_t pc, uint64_t val) { board_trap_report(cause,pc,val); }
static void mark(const char *s) {
    board_uart_puts("GEMMINI worker="); board_uart_puthex(gemmini_pool_active_worker);
    board_uart_puts(" "); board_uart_puts(s); board_uart_puts("\n");
}
static unsigned trace_commands, command_count;
void gemmini_pool_record_command(unsigned funct) {
    if (!trace_commands) return;
    ++command_count;
    {
        board_uart_puts("ROCC_SUBMIT count/funct=");
        board_uart_puthex(command_count); board_uart_puts(" / "); board_uart_puthex(funct); board_uart_puts("\n");
    }
}
static void command_args(unsigned funct, uint64_t rs1, uint64_t rs2) {
    if (!trace_commands || funct < 15 || funct > 21) return;
    board_uart_puts("LOOPCONV_ARGS rs1/rs2=");
    board_uart_puthex(rs1); board_uart_puts(" / "); board_uart_puthex(rs2); board_uart_puts("\n");
}
static void command_returned(unsigned funct) {
    if (!trace_commands) return;
    board_uart_puts("ROCC_RETURN count/funct=");
    board_uart_puthex(command_count); board_uart_puts(" / "); board_uart_puthex(funct); board_uart_puts("\n");
}
static void diagnostic_fence(void) {
    if (trace_commands) mark("INTERNAL_FENCE_BEGIN");
    asm volatile("fence":::"memory");
    if (trace_commands) mark("INTERNAL_FENCE_DONE");
}
static void credit_granted(uint64_t elapsed) {
    if (!trace_commands) return;
    mark("CREDIT_GRANTED waited_cycles"); board_uart_puthex(elapsed); board_uart_puts("\n");
}
__attribute__((noreturn)) void exit(int code) {
    mark("HALTED reset required; exit code follows"); board_uart_puthex(code);
    for (;;) asm volatile("wfi");
}
int printf(const char *format, ...) { board_uart_puts(format); return 0; }
int puts(const char *text) { board_uart_puts(text); board_uart_puts("\n"); return 0; }
// Opt in only after programming the ABI v9 RTL. Old bitstreams have no window.
#ifndef GEMMINI_INTERNAL_DIAGNOSTICS
#define GEMMINI_INTERNAL_DIAGNOSTICS 0
#endif
#if GEMMINI_INTERNAL_DIAGNOSTICS
static uint64_t debug_status(void) {
    uint64_t v;
    switch (gemmini_pool_active_worker) {
    case 0: asm volatile("csrr %0, 0x7d1":"=r"(v)::"memory"); break;
    case 1: asm volatile("csrr %0, 0x7d5":"=r"(v)::"memory"); break;
    default: asm volatile("csrr %0, 0x7d9":"=r"(v)::"memory"); break;
    }
    return v;
}
static void debug_freeze(void) {
    uint64_t one=1;
    switch (gemmini_pool_active_worker) {
    case 0: asm volatile("csrw 0x7d0, %0"::"r"(one):"memory"); break;
    case 1: asm volatile("csrw 0x7d4, %0"::"r"(one):"memory"); break;
    default: asm volatile("csrw 0x7d8, %0"::"r"(one):"memory"); break;
    }
}
static uint64_t debug_page(uint64_t page) {
    uint64_t v;
    switch (gemmini_pool_active_worker) {
    case 0: asm volatile("csrw 0x7d2, %1; csrr %0, 0x7d3":"=r"(v):"r"(page):"memory"); break;
    case 1: asm volatile("csrw 0x7d6, %1; csrr %0, 0x7d7":"=r"(v):"r"(page):"memory"); break;
    default: asm volatile("csrw 0x7da, %1; csrr %0, 0x7db":"=r"(v):"r"(page):"memory"); break;
    }
    return v;
}
static void internal_snapshot(void) {
    if (!(debug_status() & 1)) debug_freeze(); // preserve an earlier automatic freeze
    mark("INTERNAL_SNAPSHOT ABI9 status");
    board_uart_puthex(debug_status()); board_uart_puts("\n");
    for (unsigned page=0; page<80; ++page) {
        board_uart_puts("DBG page/data="); board_uart_puthex(page);
        board_uart_puts(" / "); board_uart_puthex(debug_page(page)); board_uart_puts("\n");
    }
}
#endif
static void loopconv_snapshot(void) {
#if GEMMINI_INTERNAL_DIAGNOSTICS
    internal_snapshot();
#endif
    mark("LOOPCONV_SNAPSHOT status/accepted/retired");
    board_uart_puthex(gemmini_loopconv_status_read()); board_uart_puts(" / ");
    board_uart_puthex(gemmini_loopconv_accepted_count_read()); board_uart_puts(" / ");
    board_uart_puthex(gemmini_loopconv_retired_count_read()); board_uart_puts("\n");
}
static void credit_timeout(uint64_t status, uint64_t elapsed) {
    mark("FAIL LOOPCONV_CREDIT_TIMEOUT status/cycles");
    board_uart_puthex(status); board_uart_puts(" / "); board_uart_puthex(elapsed); board_uart_puts("\n");
    for (unsigned sample=0;sample<3;sample++) {
        loopconv_snapshot();
        uint64_t start=cycles(); while(cycles()-start<100000000ULL) asm volatile("nop");
    }
    exit(2);
}
static uint64_t busy(void) {
    uint64_t v;
    switch (gemmini_pool_active_worker) {
    case 0: asm volatile("csrr %0, 0x7c2":"=r"(v)::"memory"); break;
    case 1: asm volatile("csrr %0, 0x7c3":"=r"(v)::"memory"); break;
    default: asm volatile("csrr %0, 0x7ca":"=r"(v)::"memory"); break;
    }
    return v;
}
static int wait_idle(void) {
    uint64_t start=cycles();
    mark("BUSY_WAIT_BEGIN");
    while(busy()) {
        if(cycles()-start > 1000000000ULL) { mark("FAIL busy_timeout_10s; reset before retry"); loopconv_snapshot(); return 0; }
    }
    mark("FENCE_BEGIN"); asm volatile("fence":::"memory"); mark("FENCE_DONE");
    return 1;
}
#define STEP(name, command) do { mark(name " BEGIN"); command; mark(name " RETURNED"); } while(0)
static int basic(unsigned worker) {
    gemmini_pool_active_worker=worker;
    mark("BASIC_BEGIN DIM=64");
    for(unsigned i=0;i<DIM;i++) for(unsigned j=0;j<DIM;j++) {
        a[i][j]=(elem_t)((int)((i*7+j*3+worker)%5)-2);
        b[i][j]=(elem_t)((int)((i*5+j*2+1)%3)-1);
        out[i][j]=99;
    }
    asm volatile("fence":::"memory");
    STEP("FLUSH", gemmini_flush(0));
    STEP("CONFIG_LD", gemmini_config_ld(DIM*sizeof(elem_t)));
    STEP("CONFIG_ST", gemmini_config_st(DIM*sizeof(elem_t)));
    STEP("MVIN_A", gemmini_mvin(a,0));
    STEP("MVOUT_COPY", gemmini_mvout(out,0));
    if(!wait_idle()) return 0;
    for(unsigned i=0;i<DIM;i++) for(unsigned j=0;j<DIM;j++) if(out[i][j]!=a[i][j]) {
        mark("FAIL DMA_COPY"); return 0;
    }
    mark("DMA_COPY_PASS");
    STEP("MVIN_B", gemmini_mvin(b,DIM));
    STEP("CONFIG_EX_WS", gemmini_config_ex(WEIGHT_STATIONARY,0,0));
    STEP("PRELOAD_B", gemmini_preload(DIM,0x80000000U));
    STEP("COMPUTE", gemmini_compute_preloaded(0,GARBAGE_ADDR));
    STEP("MVOUT_MATMUL", gemmini_mvout(out,0x80000000U));
    if(!wait_idle()) return 0;
    for(unsigned i=0;i<DIM;i++) for(unsigned j=0;j<DIM;j++) {
        int expected=0;
        for(unsigned k=0;k<DIM;k++) expected+=(int)a[i][k]*(int)b[k][j];
        if(expected>127) expected=127;
        if(expected< -128) expected= -128;
        if((int)out[i][j]!=expected) {
            mark("FAIL MATMUL row/col/expected/actual");
            board_uart_puthex(i); board_uart_puthex(j);
            board_uart_puthex((uint64_t)(int64_t)expected);
            board_uart_puthex((uint64_t)(int64_t)out[i][j]); board_uart_puts("\n"); return 0;
        }
    }
    mark("MATMUL_PASS"); return 1;
}
static void counter_test(unsigned worker) {
    gemmini_pool_active_worker=worker;
    unsigned result, config=1, unused=0;
    mark("COUNTER_RESET_BEGIN funct=126 xd=1");
    if(worker==0) { ROCC_INSTRUCTION(3,result,config,unused,k_COUNTER); }
    else if(worker==1) { ROCC_INSTRUCTION(2,result,config,unused,k_COUNTER); }
    else { ROCC_INSTRUCTION(1,result,config,unused,k_COUNTER); }
    mark("COUNTER_RESET_RETURNED"); board_uart_puthex(result); board_uart_puts("\n");
}

static unsigned counter_access(unsigned config) {
    unsigned result, unused=0;
    board_uart_puts("COUNTER_COMMAND config="); board_uart_puthex(config); board_uart_puts("\n");
    if(gemmini_pool_active_worker==0) { ROCC_INSTRUCTION(3,result,config,unused,k_COUNTER); }
    else if(gemmini_pool_active_worker==1) { ROCC_INSTRUCTION(2,result,config,unused,k_COUNTER); }
    else { ROCC_INSTRUCTION(1,result,config,unused,k_COUNTER); }
    mark("COUNTER_COMMAND_RETURNED"); return result;
}
static void counter_full(unsigned worker) {
    static const unsigned events[]={RESERVATION_STATION_ACTIVE_CYCLES,
        LOAD_DMA_WAIT_CYCLE,LOAD_SCRATCHPAD_WAIT_CYCLE,EXE_ACTIVE_CYCLE,
        STORE_DMA_WAIT_CYCLE,STORE_SCRATCHPAD_WAIT_CYCLE};
    gemmini_pool_active_worker=worker;
    mark("COUNTER_FULL_BEGIN");
    counter_access(1);
    for(unsigned i=0;i<6;i++) counter_access((i<<4)|8|(events[i]<<12));
    counter_access(4);
    for(unsigned i=0;i<6;i++) { board_uart_puthex(counter_access(i<<4)); board_uart_puts("\n"); }
    mark("COUNTER_FULL_PASS");
}
static elem_t conv_input[480*640*3] __attribute__((aligned(64)));
static elem_t conv_weights[6*6*3*16] __attribute__((aligned(64)));
static acc_t conv_bias[16] __attribute__((aligned(64)));
static elem_t conv_output[240*320*16] __attribute__((aligned(64)));
static elem_t test_lut[256] __attribute__((aligned(64)));
static void conv_test(unsigned worker, int full) {
    gemmini_pool_active_worker=worker;
    const int height=full?480:16, width=full?640:20;
    const int oh=height/2, ow=width/2;
    mark(full?"CONV_FULL_BEGIN 480x640x3 -> 240x320x16 k6 s2 p2":"CONV_SMALL_BEGIN 16x20x3 -> 8x10x16 k6 s2 p2");
    for(int i=0;i<height*width*3;i++) conv_input[i]=(elem_t)((i*7+i/31)%17-8);
    memset(conv_weights,0,sizeof(conv_weights));
    for(int c=0;c<16;c++) {
        int kr=c%6, kc=(c*5+1)%6, ic=c%3;
        conv_weights[((kr*6+kc)*3+ic)*16+c]=(c&1)?-1:1;
        conv_bias[c]=c%5-2;
    }
    for(int i=0;i<256;i++) test_lut[i]=(elem_t)((int)(int8_t)i/2);
    memset(conv_output,99,sizeof(conv_output));
    asm volatile("fence":::"memory");
    STEP("FLUSH", gemmini_flush(0));
    command_count=0; trace_commands=1;
    STEP("SILU_TEST_LUT_CONFIG", gemmini_config_silu_lut(test_lut));
    STEP("SILU_TEST_LUT_FENCE", asm volatile("fence":::"memory"));
    mark("LOOPCONV_STATUS_BEFORE"); board_uart_puthex(gemmini_loopconv_status_read()); board_uart_puts("\n");
    STEP("LOOPCONV_SUBMIT", tiled_conv_auto(1,height,width,3,16,oh,ow,2,1,1,2,6,
        false,false,false,false,false,conv_input,conv_weights,conv_bias,conv_output,
        SILU_LUT,1.0f,1,0,0,WS));
    trace_commands=0;
    if(!wait_idle()) return;
    mark("LOOPCONV_STATUS_AFTER"); board_uart_puthex(gemmini_loopconv_status_read()); board_uart_puts("\n");
    mark("CONV_CPU_CHECK_BEGIN");
    for(int r=0;r<oh;r++) for(int col=0;col<ow;col++) for(int c=0;c<16;c++) {
        int ir=r*2-2+c%6, ic=col*2-2+(c*5+1)%6;
        int value=conv_bias[c];
        if(ir>=0 && ir<height && ic>=0 && ic<width)
            value+=conv_input[(ir*width+ic)*3+c%3]*((c&1)?-1:1);
        int expected=test_lut[(uint8_t)(int8_t)value];
        int pos=(r*ow+col)*16+c;
        int actual=((volatile elem_t *)conv_output)[pos];
        if(actual!=expected) {
            mark("FAIL CONV index/expected/actual");
            board_uart_puthex(pos); board_uart_puthex((uint64_t)(int64_t)expected);
            board_uart_puthex((uint64_t)(int64_t)actual); board_uart_puts("\n"); return;
        }
    }
    mark(full?"CONV_FULL_PASS":"CONV_SMALL_PASS");
}
static void help(void) {
    board_uart_puts("0/1/2=DMA+matmul a=all c/d/e=counter-reset C/D/E=full-counter\n"
                    "f/g/j=small-conv workers0/1/2 k/l/m=full-size-conv workers0/1/2 h=help\n");
}
int main(void) {
    board_uart_init();
    board_uart_puts("\nGEMMINI_STANDALONE triple64 v5; no video/YOLO/PPU initialization\n"
                    "0/1/2=worker DMA+WS matmul; a=all workers; c/d/e=worker counter reset; h=help\n"
                    "Test commands are synchronous. Last BEGIN without RETURNED identifies a stalled instruction.\n");
    board_uart_puts("LOOPCONV_CREDIT_LIMIT="); board_uart_puthex(GEMMINI_LOOPCONV_CREDIT_SAFE_MAX_OVERRIDE); board_uart_puts("\n");
    board_uart_puts("DISABLE_B_REUSE="); board_uart_puthex(GEMMINI_DISABLE_B_REUSE); board_uart_puts("\n");
    help();
    *(volatile uint32_t *)0x1002000c=1;
    for(;;) {
        uint32_t rx=*(volatile uint32_t *)0x10020004;
        if(rx>>31) continue;
        unsigned ch=rx&255;
        if(ch>='0' && ch<='2') (void)basic(ch-'0');
        else if(ch=='a') {
            int ok=1;
            for(unsigned w=0;w<3;w++) if(!basic(w)) { ok=0; break; }
            board_uart_puts(ok ? "GEMMINI_ALL_PASS\n" : "GEMMINI_ALL_FAIL\n");
        } else if(ch>='c' && ch<='e') counter_test(ch-'c');
        else if(ch>='C' && ch<='E') counter_full(ch-'C');
        else if(ch=='f' || ch=='g' || ch=='j') conv_test(ch=='f'?0:ch=='g'?1:2,0);
        else if(ch=='k' || ch=='l' || ch=='m') conv_test(ch-'k',1);
        else if(ch=='h') help();
    }
}
