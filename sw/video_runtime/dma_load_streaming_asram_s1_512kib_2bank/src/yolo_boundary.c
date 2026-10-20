/* v34 boundary diagnostics; isolated from the frozen v33 formal entry. */
#include <stdint.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "config.h"
#include "gemmini_frontend.h"
#include "inputs.h"
#include "platform.h"
#include "yolo_arena.h"

enum { FRAMES=12, LANES=3, MAX_COMMANDS=16384, MAX_HOSTS=16 };
#ifndef ATSOFT_THREE_WAY
#define ATSOFT_THREE_WAY 0
#endif
#ifndef YOLO32_FRONTEND_DIAG
#define YOLO32_FRONTEND_DIAG 0
#endif
enum { MODES=ATSOFT_THREE_WAY?3:2 };
_Static_assert(MODES==3,"V34 requires three complete result buffers");
_Static_assert(FRAMES % LANES == 0,"equal frame allocation requires a multiple of lanes");
enum { HOST_PAD=1, HOST_HEAD=2 };
struct Host { unsigned kind,phase,head; const int8_t *src; int8_t *dst; int h,w,c; };
struct Plan { GfCommand commands[MAX_COMMANDS]; struct Host hosts[MAX_HOSTS];
    unsigned count,host_count,raw,conv,ws,load,store; uint16_t phases[MAX_COMMANDS]; } __attribute__((aligned(64)));
struct Range { const void *base; size_t bytes; };
static struct Plan plans[3][2][3];
static struct Plan *recording;
static unsigned planning,current_phase,current_lane,current_frame,executor;
unsigned gemmini_pool_active_worker;
static const unsigned analysis_enabled=0,yolo32_independent_enabled=0;
#ifdef ATSOFT_NATIVE_ORACLE
static const unsigned parallel_mode=1;
#endif
static unsigned parallel_collecting,parallel_pending;
volatile unsigned irq_event;
volatile uint64_t irq_count,irq_cycles;
static uint64_t clock_cycle(void) {
#ifdef __riscv
    uint64_t v;__asm__ volatile("rdcycle %0":"=r"(v));return v;
#elif defined(S1_HOST_TEST)
    extern uint64_t mock_cycle;return ++mock_cycle;
#else
    return 0;
#endif
}
#define read_cycle() clock_cycle()
static void text(const char *s) {
#ifdef __riscv
    volatile uint32_t *u=(volatile uint32_t *)AT_UART_BASE;
    while(*s){if(*s=='\n'){while(u[0]&0x80000000u){}u[0]='\r';}while(u[0]&0x80000000u){}u[0]=(unsigned char)*s++;}
#else
    fputs(s,stdout);
#endif
}
static void number(uint64_t v) {char b[24];unsigned n=sizeof(b);b[--n]=0;do{b[--n]='0'+v%10;v/=10;}while(v);text(b+n);}
static void field(const char *s,uint64_t v) {text(s);number(v);}
static void at_fail(const char *s,uint64_t v) __attribute__((noreturn));
static void at_fail(const char *s,uint64_t v) {
    text("ATSOFT1,FAIL,reason=");text(s);field(",value=",v);field(",frame=",current_frame);field(",lane=",current_lane);field(",phase=",current_phase);text("\n");
#ifdef __riscv
    __asm__ volatile("csrw mie,zero":::"memory");for(;;)__asm__ volatile("nop");
#else
    exit(1);
#endif
}
static void yolo32_fail(const char *s) {at_fail(s,0);}
static void append(GfCommand c) {
    if(!planning||!recording||recording->count==MAX_COMMANDS)at_fail("table_capacity_or_late_command",0);
    recording->phases[recording->count]=current_phase;
    recording->commands[recording->count++]=c;
}
static void at_raw(unsigned f,uintptr_t a,uintptr_t b) {
    if(f>21&&f!=26)at_fail("unexpected_funct",f);
    if(f==20||f==21||f==10||f==11) { a=arena_dma_address(a,current_lane);b=arena_dma_address(b,current_lane); }
    else if(f==1||f==2||f==3||f==14)a=arena_dma_address(a,current_lane);
    append(gf_raw(f,a,b,0));recording->raw++;
    recording->conv+=f==15;recording->ws+=f==8;recording->load+=f==2;recording->store+=f==3;
}
static void at_drain(void) {
    if(!planning)at_fail("unexpected_cpu_gemmini_wait",0);
    if(recording->count && recording->commands[recording->count-1].control==GF_DRAIN)return;
    append(gf_drain());
}
static void host_append(struct Host h) {
    if(!planning||recording->host_count==MAX_HOSTS)at_fail("host_capacity",0);
    h.phase=current_phase;recording->hosts[recording->host_count]=h;
    append(gf_host(++recording->host_count));
}
static void at_pad(const int8_t *src,int8_t *dst,int h,int w,int c) {
    host_append((struct Host){.kind=HOST_PAD,.src=src,.dst=dst,.h=h,.w=w,.c=c});
}
static void at_head(unsigned h) {
    host_append((struct Host){.kind=HOST_HEAD,.head=h});
    /* Preserve the native poller's post-head completion boundary. */
    at_drain();
}
/* All old CPU scheduling hooks are replaced; arithmetic packet emitters remain. */
#define GEMMINI_POOL_COMMAND_RETURN_HOOK(f) ((void)0)
#define GEMMINI_POOL_COMMAND_ARGS_HOOK(f,a,b) ((void)0)
#define GEMMINI_POOL_COMMAND_CLOCK(f) 0
#define GEMMINI_POOL_COMMAND_ELAPSED(f,s) ((void)0)
#define yolo32_independent_arm_tail_wait(f) ((void)0)
#define yolo32_independent_conv_more(m) ((void)0)
#define yolo32_independent_memory_submit() ((void)0)
#define yolo32_reused_fence(p) at_drain()
typedef struct {uint64_t pool_calls,resize_calls,mvin,mvout,waits,pad_cycles;} Yolo32MemoryStats;
#ifndef __riscv
static void yolov5nu_rvv_copy_i8(const int8_t *src,int8_t *dst,uintptr_t n) {memcpy(dst,src,n);}
#endif
#ifdef ATSOFT_NATIVE_ORACLE
#define yolo32_publish_head(w,h) at_head(h)
static void yolo32_publish_head_dummy(unsigned w,unsigned h) {(void)w;(void)h;}
#include "native_graph.inc"
static const struct Range constants[] = {
#include "constants.inc"
};
#else
#include "graph.inc"
#endif

static uintptr_t head_address(unsigned lane,unsigned slot) {return UINT64_C(0xb2000000)+(uintptr_t)lane*0x400000+(uintptr_t)slot*0x100000;}
static uint64_t hash_bytes(const void *ptr,size_t n) {const uint8_t *p=ptr;uint64_t h=UINT64_C(1469598103934665603);while(n--){h^=*p++;h*=UINT64_C(1099511628211);}return h;}
#include "yolo_arena.inc"
static uint64_t normalized_address(uintptr_t a,unsigned lane,unsigned slot,unsigned image,unsigned write) {
    if(!a)return 0;
    struct Range ranges[]={{activation_arenas[lane],ASRAM_ARENA_BYTES},
        {conv_input_scratches[lane],sizeof(conv_input_scratches[lane])},
        {conv_output_scratches[lane],sizeof(conv_output_scratches[lane])},
        {memory_pad[lane],SPPF_PAD_BYTES},{memory_intermediate[lane],SPPF_INTERMEDIATE_BYTES},
        {(void *)head_address(lane,slot),YOLOV5NU_HEAD_PAYLOAD_BYTES}};
    for(unsigned i=0;i<sizeof(ranges)/sizeof(*ranges);i++) {
        uintptr_t b=(uintptr_t)ranges[i].base;if(a>=b&&a-b<ranges[i].bytes)return (UINT64_C(1)<<63)|((uint64_t)i<<40)|(a-b);
        if(i==0 && a>=arena_views[lane].dma_base && a-arena_views[lane].dma_base<ASRAM_ARENA_BYTES)
            return (UINT64_C(1)<<63)|(a-arena_views[lane].dma_base);
        if(yolo_sppf_local() && (i==3 || i==4)) {
            uintptr_t dma=arena_views[lane].dma_base+(i==3?SPPF_PAD_OFFSET:SPPF_INTERMEDIATE_OFFSET);
            if(a>=dma && a-dma<ranges[i].bytes)return (UINT64_C(1)<<63)|((uint64_t)i<<40)|(a-dma);
        }
    }
    if(!write) {
        uintptr_t b=(uintptr_t)yolo32_inputs[image];
        if(a>=b&&a-b<YOLO32_INPUT_BYTES)return (UINT64_C(1)<<62)|(a-b);
        for(unsigned i=0;i<sizeof(constants)/sizeof(*constants);i++) {
            b=(uintptr_t)constants[i].base;
            if(a>=b&&a-b<constants[i].bytes)return (UINT64_C(1)<<61)|((uint64_t)i<<40)|(a-b);
        }
    }
    at_fail("operand_outside_owned_buffers",a);
}
static GfCommand normalize(GfCommand c,unsigned lane,unsigned slot,unsigned image) {
    if((c.control&255)!=GF_RAW)return c;
    unsigned f=c.control>>8;
    if(f==20||f==21||f==10||f==11) {
        c.rs1=normalized_address(c.rs1,lane,slot,image,0);
        c.rs2=normalized_address(c.rs2,lane,slot,image,f==20||f==11);
    }else if(f==1||f==2||f==3||f==14)c.rs1=normalized_address(c.rs1,lane,slot,image,f==3);
    return c;
}
static void normalized_range(const void *pointer,size_t bytes,unsigned lane,unsigned slot,unsigned image,unsigned write) {
    uintptr_t address=(uintptr_t)pointer;
    if(!bytes || bytes-1>UINTPTR_MAX-address)at_fail("range_overflow",address);
    uint64_t first=normalized_address(address,lane,slot,image,write);
    uint64_t last=normalized_address(address+bytes-1,lane,slot,image,write);
    if((first>>40)!=(last>>40) || last-first!=bytes-1)at_fail("buffer_span_overflow",address);
}
static void capture(unsigned lane,unsigned slot,unsigned image) {
    current_phase=0;current_lane=lane;recording=&plans[lane][slot][image];memset(recording,0,sizeof(*recording));
    worker_contexts[lane].input=yolo32_inputs[image];worker_contexts[lane].head_slot=(int8_t *)head_address(lane,slot);
    yolo32_batch_bind_start(lane);planning=1;
#ifdef ATSOFT_NATIVE_ORACLE
    struct yolov5nu_dim16_result result;
    /* Execute the original frozen worker_start/worker_poll control flow. */
    worker_contexts[lane].active=0;
    if(yolov5nu_dim16_worker_start(lane,yolo32_inputs[image])!=YOLOV5NU_DIM16_RUNNING)at_fail("oracle_start",lane);
    worker_contexts[lane].head_slot=(int8_t *)head_address(lane,slot);
    worker_contexts[lane].hardware_head=1;head_callback=yolo32_publish_head_dummy;
    yolo32_batch_bind_start(lane);
    while(worker_contexts[lane].stage<165)
        if(yolov5nu_dim16_worker_poll(lane,&result)!=YOLOV5NU_DIM16_RUNNING)at_fail("oracle_poll",lane);
#else
    at_raw(7,0,0);
    for(current_phase=0;current_phase<165;current_phase++)at_phase(lane,current_phase);
#endif
    at_drain();planning=0;
    if(recording->conv!=462||recording->ws!=224||recording->load!=1944||recording->store!=624||recording->host_count!=12)
        at_fail("native_workload_changed",recording->count);
    unsigned pads=0,mask=0;
    for(unsigned i=0;i<recording->host_count;i++) {
        struct Host *h=recording->hosts+i;
        if(h->kind==HOST_PAD) {
            normalized_address((uintptr_t)h->src,lane,slot,image,0);
            normalized_address((uintptr_t)h->dst,lane,slot,image,1);
            normalized_range(h->src,(size_t)h->h*h->w*h->c,lane,slot,image,0);
            normalized_range(h->dst,(size_t)(h->h+2)*(h->w+2)*h->c,lane,slot,image,1);pads++;
        }else if(h->kind==HOST_HEAD) {if(mask&(1U<<h->head))at_fail("duplicate_head",h->head);mask|=1U<<h->head;}
        else at_fail("unknown_host",h->kind);
    }
    if(pads!=6||mask!=63)at_fail("incomplete_host_work",mask);
    struct Plan *ref=&plans[0][0][0];
    if(recording->count!=ref->count)at_fail("table_shape",recording->count);
    for(unsigned i=0;i<recording->count;i++) {
        GfCommand a=normalize(recording->commands[i],lane,slot,image),b=normalize(ref->commands[i],0,0,0);
        if(memcmp(&a,&b,sizeof(a)))at_fail("table_math_changed",i);
    }
}
static void prepare_model(void) {
    yolo32_batch_bind_init();
    for(unsigned d=0;d<3;d++)for(unsigned s=0;s<2;s++)for(unsigned i=0;i<3;i++)capture(d,s,i);
    if(plans[0][0][0].count!=10870||plans[0][0][0].raw!=10478)
        at_fail("reference_table_count",plans[0][0][0].count);
}

#include "live_backend.inc"
