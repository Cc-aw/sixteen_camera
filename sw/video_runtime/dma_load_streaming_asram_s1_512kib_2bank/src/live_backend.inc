/* S1 native command frontend adapter for the existing video Runtime. */
#include "ai/backend/rt_backend.h"
#include "ai/postprocess/ai_detection.h"
#include "ai/postprocess/ai_ppu_publication.h"
#include "ai/postprocess/ai_ppu_queue.h"
#include "ai/runtime/ai_head_slot_queue.h"
#ifndef S1_HOST_TEST
#include "mmio.h"
#else
#include "hw_mock.h"
#endif
#include "platform/platform.h"

enum { LIVE_HEADS=6, LIVE_PATCHES=256 };
struct InputPatch { uint64_t *operand; uintptr_t offset; };
struct LiveHead { AiModelFrameRequest request; unsigned mask, received, reported; uint32_t count; uint64_t start, compute_end; };
struct LiveWorker { unsigned state, key, host_next; struct Plan *plan; uint64_t start; };
static AiHeadSlotQueue head_queue;
static struct LiveHead live_heads[LIVE_HEADS];
static struct LiveWorker live_workers[LANES];
static struct InputPatch input_patches[LANES][2][LIVE_PATCHES];
static unsigned input_patch_count[LANES][2];
static unsigned live_initialized, live_fault, live_rr;
static AiDetectionResult borrowed_result;
static uint32_t pget(unsigned o){return mmio_read32(POSTPROCESS_DIAG_BASE+o);}
static void pput(unsigned o,uint32_t v){mmio_write32(POSTPROCESS_DIAG_BASE+o,v);}
void at_io_commit(void) {
    __asm__ volatile("":::"memory");
    if(pget(0x1a0)!=UINT32_C(0x50505532))at_fail("ppu_mmio_ordering",0);
    __asm__ volatile("":::"memory");
}
volatile unsigned memory_probe_active,memory_probe_failed;
void at_irq_fault(uint64_t cause,uint64_t pc,uint64_t val) {
    field("S1RT,TRAP,pc=",pc);field(",value=",val);text("\n");at_fail("trap",cause);
}
static int live_error(unsigned reason) {
    if(!live_fault){field("S1RT,FAULT,reason=",reason);text(",ownership=retained\n");}
    live_fault=reason;return AI_RT_BACKEND_FAULT_HELD;
}
static void input_patch_add(unsigned d,unsigned s,uint64_t *operand) {
    uintptr_t a=*operand,b=(uintptr_t)yolo32_inputs[0];
    if(a<b || a-b>=YOLO32_INPUT_BYTES)return;
    unsigned *n=&input_patch_count[d][s];
    if(*n==LIVE_PATCHES)at_fail("input_patch_capacity",*n);
    input_patches[d][s][(*n)++]=(struct InputPatch){operand,a-b};
}
static void prepare_live_inputs(void) {
    for(unsigned d=0;d<LANES;d++)for(unsigned s=0;s<2;s++) {
        struct Plan *p=&plans[d][s][0];
        for(unsigned i=0;i<p->count;i++) {
            GfCommand *c=p->commands+i;
            if((c->control&255)!=GF_RAW)continue;
            unsigned f=c->control>>8;
            if(f==20||f==21||f==10||f==11) {
                input_patch_add(d,s,&c->rs1);input_patch_add(d,s,&c->rs2);
            }else if(f==1||f==2||f==3||f==14)input_patch_add(d,s,&c->rs1);
        }
        if(!input_patch_count[d][s])at_fail("live_input_missing",d);
        /* None of the six SPPF padding sources is the input image. */
        for(unsigned i=0;i<p->host_count;i++) {
            uintptr_t a=(uintptr_t)p->hosts[i].src,b=(uintptr_t)yolo32_inputs[0];
            if(a>=b&&a-b<YOLO32_INPUT_BYTES)at_fail("unpatched_host_input",i);
        }
    }
}
static int valid_input(uintptr_t input) {
    for(unsigned slot=0;slot<32;slot++) {
        uintptr_t physical=(slot<16?UINT64_C(0x30000000):UINT64_C(0x31000000))+(slot%16)*YOLO32_INPUT_BYTES;
        if(input==physical||input==AI_DDR_CPU_ALIAS(physical))return 1;
    }
    return 0;
}
static void bind_live_input(unsigned d,unsigned s,uintptr_t input) {
    for(unsigned i=0;i<input_patch_count[d][s];i++) {
        struct InputPatch *p=&input_patches[d][s][i];*p->operand=AI_DDR_CPU_ALIAS(input)+p->offset;
    }
}
static void hardware_check(void) {
#ifndef S1_HOST_TEST
    uint64_t vlenb;__asm__ volatile("csrr %0,vlenb":"=r"(vlenb));
    if(vlenb!=32)at_fail("rvv_vlenb",vlenb);
    for(unsigned d=0;d<LANES;d++) {
        if(gf_read(d,10,0)!=EXPECTED_HW_ID)at_fail("hardware_identity",d);
        if(gf_read(d,7,0)!=0x10004||gf_read(d,8,0)!=2)at_fail("read_assembled_required",d);
        uint64_t status=gf_status(d);
        if((status>>32)!=0x20000||!(status&GF_START_READY)||
           (status&(GF_OWNED|GF_DONE|GF_HOST_WAIT|GF_FAULT|GF_ARMED|GF_GEMMINI_BUSY|GF_FENCE_BUSY)))
            at_fail("frontend_not_clean_reprogram_bitstream",status);
    }
    volatile uint64_t *a=(volatile uint64_t *)(uintptr_t)ASRAM_CONTROL_BASE;
    arena_caps=(ActivationSramCapabilities){.magic=a[0],.abi=a[1],.enabled_mask=a[2],
        .physical_bytes=a[3],.logical_bytes=a[4],.data_width_bits=a[5],.clock_hz=a[6],
        .base={a[9],a[10],a[11]}};
    if(!activation_memory_capabilities_valid(&arena_caps)||a[7]!=2)at_fail("asram_capability",a[0]);
#endif
}
static void live_init(void) {
    if(live_initialized)return;
    hardware_check();
    if(pget(0x100)!=UINT32_C(0x50505531)||!ai_ppu_publication_available()||!ai_ppu_queue_init())at_fail("ppu_missing",0);
    /* Do not discard previous jobs after an ELF reload: a fresh bitstream is
     * required whenever the previous program left hardware ownership. */
    AiPpuQueueResult stale;
    if(ai_ppu_queue_peek(&stale))at_fail("stale_ppu_reprogram_bitstream",stale.frame);
    pput(0x148,1);if(!(pget(0x148)&1))at_fail("ppu_reader",0);
    ai_head_slot_queue_init(&head_queue,LANES);
    yolo_bind_storage(1,1);prepare_model();prepare_live_inputs();
    gf_publish();live_initialized=1;
#ifndef S1_HOST_TEST
    __asm__ volatile("csrs mie,%0"::"r"(1UL<<13):"memory");
    __asm__ volatile("csrsi mstatus,8":::"memory");
#endif
    text("S1RT,BACKEND_READY,hardware_id=" EXPECTED_HW_ID_TEXT ",workers=3,heads=6,dma_mode=2,asram=1,sppf_asram=0,entries=10870,hosts=12\n");
}
static int live_submit(const AiRtBackendRequest *r) {
    if(!live_initialized||live_fault)return AI_RT_BACKEND_FAULT_HELD;
    if(!r||r->worker_id>=LANES||r->stream_id>=VIDEO_CHANNEL_COUNT||!r->job_id||!r->version||
       r->input_bytes!=YOLO32_INPUT_BYTES||!valid_input(r->input_addr))return -1;
    unsigned d=r->worker_id;
    if(live_workers[d].state)return AI_RT_BACKEND_HEAD_BUSY;
    unsigned key;
    if(ai_head_slot_acquire(&head_queue,d,AI_MODEL_OUTPUT0_PHYS_BASE+d*AI_MODEL_OUTPUT_ARENA_BYTES,r,&key))return AI_RT_BACKEND_HEAD_BUSY;
    AiHeadSlot *slot=ai_head_slot_get(&head_queue,key);
    live_heads[key]=(struct LiveHead){.request=*r,.start=clock_cycle()};
    struct LiveWorker *w=&live_workers[d];
    *w=(struct LiveWorker){.state=1,.key=key,.plan=&plans[d][slot->slot_id][0],.start=clock_cycle()};
    if(ai_ppu_publication_begin(slot->descriptor.base_addr)!=1)return live_error(1);
    ai_ppu_queue_expect(r->stream_id,r->frame_id,r->version);
    bind_live_input(d,slot->slot_id,r->input_addr);gf_publish();
    if(gf_launch(d,w->plan->commands,w->plan->count,0,0,1))return live_error(2);
    return 0;
}
static int publish_host(unsigned d,unsigned tag) {
    struct LiveWorker *w=&live_workers[d];
    if(w->state!=1||tag!=w->host_next+1||tag>w->plan->host_count)return live_error(3);
    struct Host *h=&w->plan->hosts[tag-1];current_lane=d;current_phase=h->phase;
    if(h->kind==HOST_PAD) {
        memory_pad_input(h->src,h->dst,h->h,h->w,h->c);yolo_commit_lane(d);
    }else if(h->kind==HOST_HEAD) {
        AiHeadSlot *s=ai_head_slot_get(&head_queue,w->key);struct LiveHead *head=&live_heads[w->key];
        if(!s||s->state!=AI_HEAD_SLOT_WRITING||h->head>=6||(head->mask&(1U<<h->head)))return live_error(4);
        ai_ppu_publication_publish(s->descriptor.base_addr,1U<<h->head);at_io_commit();head->mask|=1U<<h->head;
        uint64_t start=clock_cycle();uint32_t generation=ai_ppu_publication_generation(s->descriptor.base_addr);
        for(;;) {
            uint32_t status=pget(0x1b4);
            if(pget(0x1bc)!=generation||(status&4)||!(status&1))return live_error(5);
            if(((pget(0x1b8)>>8)&63)==head->mask)break;
            if(clock_cycle()-start>1000000)return live_error(6);
        }
    }else return live_error(7);
    w->host_next++;gf_publish();
    if(gf_resume(d,tag,0))return live_error(8);
    return 0;
}
static int service_ppu(void) {
    AiPpuQueueResult r;
    if(ai_ppu_queue_peek(&r)) {
        AiHeadSlot *s=ai_head_slot_get(&head_queue,r.bank);
        if(!s||s->state!=AI_HEAD_SLOT_PROCESSING||!s->producer_complete||r.stream>=VIDEO_CHANNEL_COUNT||r.count>10||r.status||
           r.stream!=s->descriptor.stream_id||r.frame!=s->descriptor.frame_id||r.version!=s->descriptor.version||
           r.generation!=ai_ppu_publication_generation(s->descriptor.base_addr))return live_error(9);
        struct LiveHead *h=&live_heads[r.bank];
        if(h->received)return live_error(10);
        h->count=r.count;h->received=1;ai_ppu_queue_pop();at_io_commit();
    }
    while(head_queue.ready_count&&ai_ppu_queue_ready()) {
        AiHeadSlot *s;
        if(ai_head_slot_start_next(&head_queue,&s)!=1||ai_ppu_queue_submit(&s->descriptor)!=1)return live_error(11);
        if(pget(0x204)!=UINT32_C(0x50505132))return live_error(12);
        head_queue.active=AI_HEAD_SLOT_INVALID;
    }
    for(unsigned k=0;k<LIVE_HEADS;k++) {
        AiHeadSlot *slot=&head_queue.slots[k];struct LiveHead *h=&live_heads[k];
        if(slot->state>=AI_HEAD_SLOT_READY&&!h->received&&clock_cycle()-h->compute_end>SOC_CLOCK_HZ*50)
            return live_error(21);
    }
    return 0;
}
static int service_frontend(void) {
    unsigned pending=gf_pending();irq_event=0;
    for(unsigned d=0;d<LANES;d++)if(pending&(1U<<d)) {
        struct LiveWorker *w=&live_workers[d];if(w->state!=1)return live_error(13);
        uint64_t status=gf_status(d);
        if(status&GF_FAULT)return live_error(14);
        if(status&GF_DONE) {
            uint64_t cursor=gf_read(d,2,0),counts=gf_read(d,1,0);struct Plan *p=w->plan;
            if((cursor>>32)!=p->count||(uint32_t)cursor!=p->count||(counts>>32)!=p->count||
               (uint32_t)counts!=p->raw||w->host_next!=12||live_heads[w->key].mask!=63)return live_error(15);
            if(gf_ack(d,0,0))return live_error(16);
            gf_publish();
            if(ai_head_slot_publish(&head_queue,w->key))return live_error(17);
            w->state=2;live_heads[w->key].compute_end=clock_cycle();pending&=~(1U<<d);
        }else if(!(status&GF_HOST_WAIT))return live_error(18);
    }
    for(unsigned n=0;n<LANES;n++) {
        unsigned d=(live_rr+n)%LANES;
        if(pending&(1U<<d)) {
            gf_publish();int rc=publish_host(d,(unsigned)gf_read(d,3,0));live_rr=(d+1)%LANES;
            if(rc)return rc;
            pending&=~(1U<<d);break;
        }
    }
#ifndef S1_HOST_TEST
    if(!pending)__asm__ volatile("csrs mie,%0"::"r"(1UL<<13):"memory");
#endif
    return service_ppu();
}
static int live_progress(AiRtBackendPhase phase,uint32_t worker,AiRtBackendPayload *payload) {
    if(!live_initialized||live_fault)return AI_RT_BACKEND_FAULT_HELD;
    if(service_frontend())return AI_RT_BACKEND_FAULT_HELD;
    if(phase==AI_RT_BACKEND_COMPUTE) {
        if(worker>=LANES)return -1;
        struct LiveWorker *w=&live_workers[worker];if(w->state!=2)return 0;
        struct LiveHead *h=&live_heads[w->key];AiModelFrameRequest *r=&h->request;
        payload->compute=(AiRtBackendComputeCompletion){.job_id=r->job_id,.worker_id=r->worker_id,
            .stream_id=r->stream_id,.frame_id=r->frame_id,.version=r->version,.compute_cycles=h->compute_end-h->start};
        h->reported=1;w->state=0;return 1;
    }
    for(unsigned key=0;key<LIVE_HEADS;key++) {
        struct LiveHead *h=&live_heads[key];
        if(!h->received||!h->reported)continue;
        AiModelFrameRequest *r=&h->request;
        if(worker!=AI_RT_BACKEND_ANY_WORKER&&worker!=r->worker_id)continue;
        borrowed_result=(AiDetectionResult){.job_id=r->job_id,.worker_id=r->worker_id,.stream_id=r->stream_id,
            .frame_id=r->frame_id,.timestamp=r->timestamp,.version=r->version,.count=h->count,
            .flags=AI_RESULT_HARDWARE_OVERLAY|AI_RESULT_METADATA_ONLY};
        payload->result=(AiRtBackendResultCompletion){.job_id=r->job_id,.worker_id=r->worker_id,.stream_id=r->stream_id,
            .frame_id=r->frame_id,.version=r->version,.compute_cycles=h->compute_end-h->start,
            .output_addr=(uintptr_t)&borrowed_result,.output_desc={.dtype=AI_TENSOR_DTYPE_CUSTOM,.bytes=sizeof(borrowed_result)}};
        payload->result.profile.ppu_queue_wait_cycles=clock_cycle()-h->compute_end;
        head_queue.active=key;if(ai_head_slot_complete(&head_queue,0))return live_error(19);
        memset(h,0,sizeof(*h));return 1;
    }
    return 0;
}
static int live_abort(uint32_t worker){(void)worker;return live_error(20);}
static uint32_t live_idle(void) {
    if(!live_initialized||live_fault||head_queue.ready_count)return 0;
    for(unsigned d=0;d<LANES;d++)if(live_workers[d].state)return 0;
    for(unsigned k=0;k<LIVE_HEADS;k++)if(head_queue.slots[k].state!=AI_HEAD_SLOT_FREE)return 0;
    return 1;
}
static void live_resources(AiRtBackendResources *out) {
    memset(out,0,sizeof(*out));out->unsafe_fault=live_fault!=0;
    for(unsigned d=0;d<LANES;d++)if(live_workers[d].state) {
        struct LiveHead *h=&live_heads[live_workers[d].key];AiModelFrameRequest *r=&h->request;
        out->activation_held|=1U<<d;out->arenas[d]=(AiRtArenaLease){.identity=rt_job_identity(r->job_id,d,r->stream_id,r->frame_id,r->version),
            .state=live_fault?AI_RT_FAULT_HELD:AI_RT_OWNED,.activation_base=arena_views[d].dma_base,
            .head_pool_base=AI_MODEL_OUTPUT0_PHYS_BASE+d*AI_MODEL_OUTPUT_ARENA_BYTES};
    }
    for(unsigned k=0;k<LIVE_HEADS;k++)if(head_queue.slots[k].state!=AI_HEAD_SLOT_FREE) {
        AiHeadSlot *s=&head_queue.slots[k];AiModelFrameRequest *r=&live_heads[k].request;
        out->owned_head|=1U<<k;out->heads[k]=(AiRtHeadLease){.identity=rt_job_identity(r->job_id,r->worker_id,r->stream_id,r->frame_id,r->version),
            .state=live_fault?AI_RT_FAULT_HELD:AI_RT_OWNED,.generation=r->job_id,
            .hardware_generation=ai_ppu_publication_generation(s->descriptor.base_addr),.producer_mask=live_heads[k].mask,
            .producer_complete=s->producer_complete,.queue_state=s->state,.base=s->descriptor.base_addr};
    }
}
const AiRtBackendOps *rt_backend_selected_ops(void) {
    static const AiRtBackendOps ops={.name="s1_dma_stream_asram",.profile=3,.worker_count=3,.gemmini_dim=32,
        .init=live_init,.submit=live_submit,.progress=live_progress,.abort=live_abort,.is_idle=live_idle,.get_resources=live_resources};
    return &ops;
}

void s1_runtime_check_guards(void) {
    if(!live_idle())at_fail("guard_check_not_idle",0);
    yolo_check_guards();text("S1RT,GUARDS_PASS,asram=1,scratch=original\n");
}
