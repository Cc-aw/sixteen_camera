#include <stdint.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "config.h"
#include "gemmini_frontend.h"
#include "inputs.h"
#include "platform.h"

enum { FRAMES=12, LANES=3, MAX_COMMANDS=16384, MAX_HOSTS=16 };
#ifndef ATSOFT_THREE_WAY
#define ATSOFT_THREE_WAY 0
#endif
#ifndef YOLO32_FRONTEND_DIAG
#define YOLO32_FRONTEND_DIAG 0
#endif
enum { MODES=ATSOFT_THREE_WAY?3:2 };
_Static_assert(FRAMES % LANES == 0,"equal frame allocation requires a multiple of lanes");
enum { HOST_PAD=1, HOST_HEAD=2 };
struct Host { unsigned kind,phase,head; const int8_t *src; int8_t *dst; int h,w,c; };
struct Plan { GfCommand commands[MAX_COMMANDS]; struct Host hosts[MAX_HOSTS];
    unsigned count,host_count,raw,conv,ws,load,store; };
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
    recording->commands[recording->count++]=c;
}
static void at_raw(unsigned f,uintptr_t a,uintptr_t b) {
    if(f>21&&f!=26)at_fail("unexpected_funct",f);
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
static uint64_t normalized_address(uintptr_t a,unsigned lane,unsigned slot,unsigned image,unsigned write) {
    if(!a)return 0;
    struct Range ranges[]={{activation_arenas[lane],sizeof(activation_arenas[lane])},
        {conv_input_scratches[lane],sizeof(conv_input_scratches[lane])},
        {conv_output_scratches[lane],sizeof(conv_output_scratches[lane])},
        {memory_pad[lane],sizeof(memory_pad[lane])},{memory_intermediate[lane],sizeof(memory_intermediate[lane])},
        {(void *)head_address(lane,slot),YOLOV5NU_HEAD_PAYLOAD_BYTES}};
    for(unsigned i=0;i<sizeof(ranges)/sizeof(*ranges);i++) {
        uintptr_t b=(uintptr_t)ranges[i].base;if(a>=b&&a-b<ranges[i].bytes)return (UINT64_C(1)<<63)|((uint64_t)i<<40)|(a-b);
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
static void capture(unsigned lane,unsigned slot,unsigned image) {
    current_lane=lane;recording=&plans[lane][slot][image];memset(recording,0,sizeof(*recording));
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
            normalized_address((uintptr_t)h->dst,lane,slot,image,1);pads++;
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
    for(unsigned d=0;d<3;d++)for(unsigned s=0;s<2;s++)for(unsigned i=0;i<3;i++){field("L2PROBE,CAPTURE_BEGIN,lane=",d);field(",slot=",s);field(",image=",i);text("\n");capture(d,s,i);text("L2PROBE,CAPTURE_END\n");}
    if(plans[0][0][0].count!=10870||plans[0][0][0].raw!=10478)
        at_fail("reference_table_count",plans[0][0][0].count);
}

#ifndef __riscv
static void tensor_fill(unsigned char value) {
    memset(activation_arenas,value,sizeof(activation_arenas));
    memset(conv_input_scratches,value,sizeof(conv_input_scratches));
    memset(conv_output_scratches,value,sizeof(conv_output_scratches));
    memset(memory_pad,value,sizeof(memory_pad));memset(memory_intermediate,value,sizeof(memory_intermediate));
}
static uint64_t tensor_hash(void) {
    return hash_bytes(activation_arenas,sizeof(activation_arenas)) ^
        hash_bytes(conv_input_scratches,sizeof(conv_input_scratches)) ^
        (hash_bytes(conv_output_scratches,sizeof(conv_output_scratches))<<1) ^
        hash_bytes(memory_pad,sizeof(memory_pad)) ^ hash_bytes(memory_intermediate,sizeof(memory_intermediate));
}
static void test_padding(void) {
    static int8_t input[15*20*128],guarded[17*22*128+128];
    for(size_t i=0;i<sizeof(input);i++)input[i]=(int8_t)(i*37+19);
    memset(guarded,0x5a,sizeof(guarded));planning=0;
    memory_pad_input(input,guarded+64,15,20,128);
    for(unsigned y=0;y<17;y++)for(unsigned x=0;x<22;x++)for(unsigned c=0;c<128;c++) {
        int8_t expected=y&&y<16&&x&&x<21?input[((y-1)*20+x-1)*128+c]:-128;
        if(guarded[64+(y*22+x)*128+c]!=expected)at_fail("native_pad_mismatch",y*22+x);
    }
    for(unsigned i=0;i<64;i++)if(guarded[i]!=0x5a||guarded[sizeof(guarded)-1-i]!=0x5a)at_fail("pad_guard",i);
}
#endif

#ifdef __riscv
#if YOLO32_FRONTEND_DIAG
static uint64_t host_service_cycles,head_publish_cycles,ppu_service_cycles,host_max_cycles;
static unsigned host_max_kind,host_max_phase;
#endif
#include "ppu.inc"
struct Frame {unsigned device,image,slot,host_next,state;struct Plan *plan;uint64_t begin,end,graph_end;};
static struct Frame frames[FRAMES];
static struct PpuResult output[MODES][FRAMES];
static int bound[3];
static unsigned use[3],next_frame,completed,held_events,rr;
static uint64_t batch_begin,launches,host_calls,pad_cycles,triple_samples,busy_samples,last_sample;
void at_irq_fault(uint64_t cause,uint64_t pc,uint64_t val) {field("ATSOFT1,TRAP,pc=",pc);field(",tval=",val);text("\n");at_fail("trap",cause);}
static void require(uint64_t rc,const char *s) {if(rc)at_fail(s,rc);}
static void direct(const GfCommand *c) {
    uint64_t a=c->rs1,b=c->rs2;
#define SEND(f) case f: GF_DIRECT(0,f,a,b);break
    switch(c->control>>8) {
        SEND(0);SEND(1);SEND(2);SEND(3);SEND(4);SEND(5);SEND(6);SEND(7);SEND(8);SEND(9);SEND(10);
        SEND(11);SEND(12);SEND(13);SEND(14);SEND(15);SEND(16);SEND(17);SEND(18);SEND(19);SEND(20);SEND(21);SEND(26);
        default:at_fail("direct_funct",c->control>>8);
    }
#undef SEND
}
static void execute_host(unsigned f,unsigned tag) {
    struct Frame *t=&frames[f];
    if(tag!=t->host_next+1||tag>t->plan->host_count)at_fail("host_sequence",tag);
    struct Host *h=t->plan->hosts+tag-1;current_phase=h->phase;current_lane=t->device;current_frame=f;
#if YOLO32_FRONTEND_DIAG
    uint64_t service_begin=clock_cycle();
#endif
    if(h->kind==HOST_PAD) {uint64_t begin=clock_cycle();memory_pad_input(h->src,h->dst,h->h,h->w,h->c);pad_cycles+=clock_cycle()-begin;}
    else if(h->kind==HOST_HEAD)ppu_head(t->device,h->head);
    else at_fail("host_kind",h->kind);
    t->host_next++;host_calls++;
#if YOLO32_FRONTEND_DIAG
    uint64_t elapsed=clock_cycle()-service_begin;
    host_service_cycles+=elapsed;
    if(h->kind==HOST_HEAD)head_publish_cycles+=elapsed;
    if(elapsed>host_max_cycles){host_max_cycles=elapsed;host_max_kind=h->kind;host_max_phase=h->phase;}
#endif
}
static void admit(unsigned f,unsigned d) {
    current_frame=f;current_lane=d;struct Frame *t=&frames[f];
    t->image=f%3;t->device=d;t->begin=clock_cycle();t->slot=ppu_begin(d,executor*FRAMES+f+1);
    t->plan=&plans[d][t->slot][t->image];t->host_next=0;t->state=1;bound[d]=f;use[d]++;
}
static void graph_done(unsigned f) {
    struct Frame *t=&frames[f];
    if(t->host_next!=12)at_fail("missing_host_ops",t->host_next);
    ppu_graph_done(t->device);t->state=2;
#if YOLO32_FRONTEND_DIAG
    t->graph_end=clock_cycle();
#endif
}
static void finish(unsigned f) {
    struct Frame *t=&frames[f];output[executor][f]=ppu_result[t->device];t->end=clock_cycle();
    t->state=3;bound[t->device]=-1;completed++;
}
static void watchdog(void) {
    if(clock_cycle()-batch_begin<UINT64_C(120000000000))return;
    for(unsigned d=0;d<3;d++) {
        field("ATSOFT1,DIAG,device=",d);field(",status=",gf_status(d));field(",cursor=",gf_read(d,2,0));text("\n");
    }
    at_fail("watchdog_120000000000_cycles",completed);
}
static void serial_batch(void) {
    for(unsigned f=0;f<FRAMES;f++) {
        field("L2PROBE,ADMIT_BEGIN,frame=",f);text("\n");admit(f,0);text("L2PROBE,ADMIT_END\n");struct Plan *p=frames[f].plan;
        for(unsigned i=0;i<p->count;i++) {
            GfCommand *c=p->commands+i;unsigned kind=c->control&255;
            if(kind==GF_RAW){if(f==0&&(i<1024||i%128==0)){field("L2PROBE,DIRECT_BEGIN,index=",i);field(",control=",c->control);text("\n");}direct(c);if(f==0&&i<1024){field("L2PROBE,DIRECT_END,index=",i);text("\n");}}
            else if(kind==GF_DRAIN){if(f==0&&i<1024){field("L2PROBE,FENCE_BEGIN,index=",i);text("\n");}gf_publish();if(f==0&&i<1024)text("L2PROBE,FENCE_END\n");}
            else if(kind==GF_HOST){gf_publish();execute_host(f,c->rs1);gf_publish();}
            else at_fail("table_kind",kind);
        }
        gf_publish();graph_done(f);
        while(!ppu_done[0]){ppu_service();watchdog();}
        finish(f);
    }
}
/* Use exactly the same frontend scheduler for one lane and three lanes.
 * Only admission capacity/quota changes; HOST, DRAIN, PPU and refill do not. */
static void parallel_batch(unsigned active_lanes) {
    if((active_lanes!=1&&active_lanes!=LANES)||FRAMES%active_lanes)at_fail("active_lanes",active_lanes);
    __asm__ volatile("csrs mie,%0"::"r"(1UL<<13):"memory");
    __asm__ volatile("csrsi mstatus,8":::"memory");
    while(completed<FRAMES) {
        watchdog();
        if(irq_event||held_events) {irq_event=0;held_events=gf_pending();}
        /* Retire every completion first, then serve one CPU/RVV boundary.
         * Other lanes continue fetching/executing while that CPU work runs. */
        for(unsigned d=0;d<3;d++)if(held_events&(1U<<d)) {
            if(bound[d]<0)at_fail("unbound_event",d);
            unsigned f=bound[d];current_frame=f;current_lane=d;
            uint64_t s=gf_status(d);
            if(s&GF_FAULT)at_fail("frontend_fault",s);
            if(s&GF_DONE) {
                uint64_t cursor=gf_read(d,2,0),counts=gf_read(d,1,0);struct Plan *p=frames[f].plan;
                if((cursor>>32)!=p->count||(uint32_t)cursor!=p->count||(counts>>32)!=p->count||(uint32_t)counts!=p->raw)
                    at_fail("frontend_incomplete",cursor);
                require(gf_ack(d,0,0),"ack");held_events&=~(1U<<d);gf_publish();graph_done(f);
            }else if(!(s&GF_HOST_WAIT))at_fail("unexpected_event",s);
        }
        ppu_service();
        for(unsigned d=0;d<3;d++) {
            if(bound[d]>=0&&frames[bound[d]].state==2&&ppu_done[d])finish(bound[d]);
            if(d<active_lanes&&bound[d]<0&&next_frame<FRAMES&&use[d]<FRAMES/active_lanes) {
                unsigned f=next_frame++;admit(f,d);
                require(gf_launch(d,frames[f].plan->commands,frames[f].plan->count,0,0,1),"launch");launches++;
            }
        }
        for(unsigned n=0;n<3;n++) {
            unsigned d=(rr+n)%3;if(!(held_events&(1U<<d)))continue;
            unsigned f=bound[d],tag=(unsigned)gf_read(d,3,0);
            gf_publish();execute_host(f,tag);gf_publish();require(gf_resume(d,tag,0),"resume");
            held_events&=~(1U<<d);rr=(d+1)%3;break;
        }
        if(!held_events)__asm__ volatile("csrs mie,%0"::"r"(1UL<<13):"memory");
        uint64_t now=clock_cycle();
        if(now-last_sample>=100000){last_sample=now;busy_samples++;triple_samples+=((gf_global_read(1)>>8)&7)==7;}
    }
    __asm__ volatile("csrc mie,%0"::"r"(1UL<<13):"memory");
}
static void prepare_batch(void) {
    memset(activation_arenas,0,sizeof(activation_arenas));memset(memory_pad,0,sizeof(memory_pad));memset(memory_intermediate,0,sizeof(memory_intermediate));
    memset(conv_input_scratches,0,sizeof(conv_input_scratches));memset(conv_output_scratches,0,sizeof(conv_output_scratches));
    memset(frames,0,sizeof(frames));memset(use,0,sizeof(use));for(unsigned d=0;d<3;d++)bound[d]=-1;
    next_frame=completed=held_events=rr=irq_event=0;launches=host_calls=pad_cycles=triple_samples=busy_samples=last_sample=irq_count=irq_cycles=0;
#if YOLO32_FRONTEND_DIAG
    host_service_cycles=head_publish_cycles=ppu_service_cycles=host_max_cycles=0;
    host_max_kind=host_max_phase=0;
#endif
    gf_publish();
}
static const char *executor_name(unsigned mode) {
    if(!mode)return "direct_serial";
    return ATSOFT_THREE_WAY&&mode==1?"frontend_serial":"frontend_parallel";
}
static unsigned report(unsigned mode) {
    unsigned bad=0;
    for(unsigned f=0;f<FRAMES;f++) {
        struct PpuResult *p=&output[mode][f],*ref=&output[0][f];unsigned errors=0;
        if(mode){errors+=p->count!=ref->count;for(unsigned i=0;i<10;i++)for(unsigned j=0;j<4;j++)errors+=p->words[i][j]!=ref->words[i][j];}
        text("ATSOFT1,FRAME_END,executor=");text(executor_name(mode));field(",frame=",f);
        const struct Frame *t=&frames[f];
        field(",device=",t->device);field(",image=",t->image);field(",slot=",t->slot);
        field(",begin_cycles=",t->begin-batch_begin);field(",end_cycles=",t->end-batch_begin);
        field(",frame_cycles=",t->end-t->begin);field(",host_calls=",t->host_next);
#if YOLO32_FRONTEND_DIAG
        field(",graph_done_cycles=",t->graph_end-batch_begin);
#endif
        if(errors)field(",word_errors=",errors);
        text(errors?",marker=MISMATCH\n":",marker=COMPLETE\n");bad+=errors!=0;
    }
    return bad;
}
#endif

int main(int argc,char **argv) {
    (void)argc;(void)argv;
#ifdef __riscv
    volatile uint32_t *u=(volatile uint32_t *)AT_UART_BASE;u[2]=1;u[4]=0;u[6]=867;
#if YOLO32_FRONTEND_DIAG
    text("YOLO32_FRONTEND,BUILD,schema=1,version=33,diagnostics=1,frames=12,modes=3,clock_hz=100000000,control_abi=131072,entries_per_frame=10870,raw_per_frame=10478,drains_per_frame=380,hosts_per_frame=12,ppu=hardware\n");
#else
    text("YOLO32_FRONTEND,BUILD,schema=1,version=33,diagnostics=9,frames=12,modes=3,clock_hz=100000000,control_abi=131072,entries_per_frame=10870,raw_per_frame=10478,drains_per_frame=380,hosts_per_frame=12,ppu=hardware\n");
#endif
    uint64_t vlenb;__asm__ volatile("csrr %0,vlenb":"=r"(vlenb));if(vlenb!=32)at_fail("rvv_vlenb",vlenb);
    for(unsigned d=0;d<3;d++){uint64_t s=gf_status(d);if((s>>32)!=0x20000||!(s&GF_START_READY))at_fail("frontend_abi_or_not_idle",s);}
#endif
#ifndef __riscv
    tensor_fill(0x35);uint64_t before=tensor_hash();
#endif
    text("L2PROBE,PREPARE_MODEL_BEGIN\n");prepare_model();text("L2PROBE,PREPARE_MODEL_END\n");
#ifndef __riscv
    if(before!=tensor_hash())at_fail("planning_wrote_tensors",0);
    uint64_t plan_hash=hash_bytes(plans,sizeof(plans));tensor_fill(0xce);before=tensor_hash();prepare_model();
    if(before!=tensor_hash()||plan_hash!=hash_bytes(plans,sizeof(plans)))at_fail("data_dependent_plans",0);
    test_padding();
    if(argc==2) {
        FILE *out=fopen(argv[1],"w");if(!out)at_fail("dump_open",0);
        struct Plan *p=&plans[0][0][0];
        for(unsigned i=0;i<p->count;i++){GfCommand c=normalize(p->commands[i],0,0,0);fprintf(out,"%016llx %016llx %016llx %016llx\n",(unsigned long long)c.control,(unsigned long long)c.rs1,(unsigned long long)c.rs2,(unsigned long long)c.reserved);}
        for(unsigned i=0;i<p->host_count;i++) {
            struct Host *h=p->hosts+i;
            fprintf(out,"host %u %u %u %d %d %d %016llx %016llx\n",h->kind,h->phase,h->head,h->h,h->w,h->c,
                (unsigned long long)normalized_address((uintptr_t)h->src,0,0,0,0),
                (unsigned long long)normalized_address((uintptr_t)h->dst,0,0,0,1));
        }
        fclose(out);
    }
    field("ATSOFT1,PLAN_PASS,tables=18,entries_per_frame=",plans[0][0][0].count);
    field(",raw=",plans[0][0][0].raw);text(",conv=462,ws=224,pad_hosts=6,head_hosts=6,owned_operands=1,hardware_executed=0\n");
    return 0;
#else
    text("L2PROBE,PPU_INIT_BEGIN\n");ppu_init();text("L2PROBE,PPU_INIT_END\n");uint64_t cycles[MODES];
    for(executor=0;executor<MODES;executor++) {
        unsigned active_lanes=executor&&(!ATSOFT_THREE_WAY||executor==2)?LANES:1;
        text("L2PROBE,PREPARE_BATCH_BEGIN\n");prepare_batch();text("L2PROBE,PREPARE_BATCH_END\n");batch_begin=clock_cycle();
        if(executor)parallel_batch(active_lanes);else serial_batch();
        cycles[executor]=clock_cycle()-batch_begin;
        if(completed!=FRAMES||host_calls!=FRAMES*12||(executor&&launches!=FRAMES))at_fail("batch_incomplete",completed);
        for(unsigned d=0;d<LANES;d++)if(use[d]!=(d<active_lanes?FRAMES/active_lanes:0))at_fail("unequal_frame_allocation",d);
        if(report(executor))at_fail("ppu_result_mismatch",executor);
#if ATSOFT_THREE_WAY
        text("ATSOFT1,MODE,executor=");text(executor_name(executor));field(",frames=",FRAMES);
        field(",devices=",active_lanes);field(",cycles=",cycles[executor]);
        field(",device0_frames=",use[0]);field(",device1_frames=",use[1]);field(",device2_frames=",use[2]);
        field(",launches=",launches);field(",host_calls=",host_calls);field(",cpu_pad_cycles=",pad_cycles);
        field(",irqs=",irq_count);field(",irq_body_cycles=",irq_cycles);field(",triple_samples=",triple_samples);
        field(",busy_samples=",busy_samples);field(",diagnostics=",YOLO32_FRONTEND_DIAG);
#if YOLO32_FRONTEND_DIAG
        field(",host_service_cycles=",host_service_cycles);field(",head_publish_cycles=",head_publish_cycles);
        field(",ppu_service_cycles=",ppu_service_cycles);field(",host_max_cycles=",host_max_cycles);
        field(",host_max_kind=",host_max_kind);field(",host_max_phase=",host_max_phase);
#endif
        text(",ppu=hardware,comparison_outside_timing=1\n");
#endif
    }
#if ATSOFT_THREE_WAY
    field("ATSOFT1,PERF,direct_cycles=",cycles[0]);field(",frontend_single_cycles=",cycles[1]);field(",frontend_parallel_cycles=",cycles[2]);
    field(",direct_to_single_x1000=",cycles[1]?cycles[0]*1000/cycles[1]:0);
    field(",frontend_scaling_x1000=",cycles[2]?cycles[1]*1000/cycles[2]:0);
    field(",direct_to_parallel_x1000=",cycles[2]?cycles[0]*1000/cycles[2]:0);
    text("\nATSOFT1,PASS,modes=3");field(",frames_per_mode=",FRAMES);
    text(",direct_vs_frontend_single=bit_exact,direct_vs_frontend_parallel=bit_exact");
#else
    field("ATSOFT1,PERF,serial_cycles=",cycles[0]);field(",parallel_cycles=",cycles[1]);
    field(",speedup_x1000=",cycles[1]?cycles[0]*1000/cycles[1]:0);
    text("\n");
    field("ATSOFT1,PASS,serial_frames=",FRAMES);field(",parallel_frames=",FRAMES);
#endif
    field(",device0_frames=",use[0]);field(",device1_frames=",use[1]);field(",device2_frames=",use[2]);
#if ATSOFT_THREE_WAY
    text(",ppu=hardware,pad_hosts_per_frame=6,head_hosts_per_frame=6,independent_accuracy=not_proven");
#endif
    text(",ppu_results=bit_exact,marker=ALL_COMPLETE\n");
    for(;;)__asm__ volatile("wfi");
#endif
}
