#include "diagnostics.h"
#if YOLO32_SUPPLY_DIAG
#include <string.h>
#include "yolo32.h"
#include "mmio.h"
#include "console.h"
static Yolo32DiagCredit credits[3][DIAG_SOURCES];
static Yolo32DiagSupply supplies[3];
static Yolo32DiagStage stages[3][YOLO32_GRAPH_STAGES];
static struct {
    unsigned stage, category, known, next, episode, native_token;
    uint64_t status, gap[3]; /* peer, scheduler, self; sampled-capacity episode. */
    uint32_t hw_start[6];
} workers[3];
static unsigned enabled, owner;
static unsigned requested_detail=1, detail;
static uint32_t totals[3][6];
static uint64_t last_cycle;
static unsigned same(const char *a,const char *b) {
    while (*a && *a==*b) { ++a; ++b; }
    return *a==*b;
}
static void diag_tick(void) {
    uint64_t now=read_cycle(), delta=now-last_cycle;
    if (detail && owner<3 && workers[owner].stage<YOLO32_GRAPH_STAGES)
        stages[owner][workers[owner].stage].cpu[workers[owner].category]+=delta;
    for (unsigned w=0; w<3; ++w) if (workers[w].episode)
        workers[w].gap[owner==3 ? 1 : owner==w ? 2 : 0]+=delta;
    last_cycle=now;
}
unsigned yolo32_diag_enabled(void) { return enabled; }
unsigned yolo32_diag_detail_enabled(void) { return detail; }
void yolo32_diag_set_detail(unsigned on) { requested_detail=on!=0; }
void yolo32_diag_reset(unsigned on) {
    memset(credits,0,sizeof(credits)); memset(supplies,0,sizeof(supplies));
    memset(stages,0,sizeof(stages)); memset(workers,0,sizeof(workers));
    memset(totals,0,sizeof(totals));
    for (unsigned w=0;w<3;++w) workers[w].stage=YOLO32_GRAPH_STAGES;
    enabled=on; detail=on && requested_detail; owner=3; last_cycle=on ? read_cycle() : 0;
}
void yolo32_diag_owner(unsigned actor) {
    if (!enabled) return;
    if (actor>3) yolo32_fail("diag_owner");
    diag_tick(); owner=actor;
}
void yolo32_diag_stage_begin(unsigned w,unsigned stage,const char *kind) {
    if (!enabled) return;
    diag_tick(); workers[w].stage=stage;
    workers[w].category=same(kind,"resize") ? DIAG_RESIZE :
        same(kind,"maxpool") ? DIAG_MAXPOOL : DIAG_OTHER;
}
void yolo32_diag_stage_end(unsigned w) {
    if (!enabled) return;
    diag_tick(); workers[w].stage=YOLO32_GRAPH_STAGES;
}
unsigned yolo32_diag_push(unsigned w,unsigned category) {
    if (!detail || owner!=w || workers[w].stage>=YOLO32_GRAPH_STAGES) return 0;
    if (category>=DIAG_CATEGORIES) yolo32_fail("diag_category");
    diag_tick(); unsigned token=workers[w].category+1; workers[w].category=category; return token;
}
void yolo32_diag_pop(unsigned w,unsigned token) {
    if (!token) return;
    if (!enabled || owner!=w || token>DIAG_CATEGORIES) yolo32_fail("diag_scope");
    diag_tick(); workers[w].category=token-1;
}
void yolo32_diag_credit_status(unsigned w,uint64_t status) {
    if (enabled) workers[w].status=status;
}
static void close_episode(unsigned w,unsigned submitted) {
    if (!workers[w].episode) return;
    Yolo32DiagSupply *s=&supplies[w]; uint64_t *g=workers[w].gap;
    uint64_t total=g[0]+g[1]+g[2];
    if (submitted) {
        ++s->events; s->gap_cycles+=total;
        s->peer_cycles+=g[0]; s->scheduler_cycles+=g[1]; s->self_cycles+=g[2];
        if (total>s->max_gap) s->max_gap=total;
        if (workers[w].stage<YOLO32_GRAPH_STAGES) {
            Yolo32DiagFlow *f=&stages[w][workers[w].stage].flow;
            ++f->events; f->gap_cycles+=total;
            f->peer_cycles+=g[0]; f->scheduler_cycles+=g[1]; f->self_cycles+=g[2];
        }
    } else { ++s->withdrawn_events; s->withdrawn_cycles+=total; }
    workers[w].episode=0; memset(g,0,sizeof(workers[w].gap));
}
void yolo32_diag_credit_record(unsigned w,unsigned pending,unsigned source,uint64_t cycles) {
    if (!enabled) return;
    if (pending>3 || source>=DIAG_SOURCES) yolo32_fail("diag_credit");
    diag_tick(); Yolo32DiagCredit *r=&credits[w][source];
    ++r->checks; r->cycles+=cycles; ++r->pending[pending];
    unsigned budget=pending==3, hardware=!(workers[w].status&2);
    if (hardware) {
        unsigned slots=((workers[w].status>>2)&7)>=4;
        unsigned queue=((workers[w].status>>8)&3)>=2;
        unsigned partial=(workers[w].status>>12)&1;
        r->hw_slots_full+=slots; r->hw_queue_full+=queue; r->hw_partial+=partial;
        r->hw_unknown+=!(slots||queue||partial);
    }
    if (budget && hardware) ++r->both;
    else if (budget) ++r->budget_only;
    else if (hardware) ++r->hardware_only;
    else ++r->ready;
    if (workers[w].known && workers[w].stage<YOLO32_GRAPH_STAGES) {
        Yolo32DiagFlow *f=&stages[w][workers[w].stage].flow;
        ++f->checks; ++f->pending[pending];
        if (budget && hardware) ++f->both;
        else if (budget) ++f->budget_only;
        else if (hardware) ++f->hardware_only;
        else ++f->ready;
    }
    if (!workers[w].known) return;
    if (budget || hardware) close_episode(w,0);
    else {
        ++supplies[w].positive_samples;
        if (!workers[w].episode) workers[w].episode=1;
    }
}
void yolo32_diag_admitted(unsigned w,unsigned pending) {
    if (enabled) ++supplies[w].admitted[pending];
}
void yolo32_diag_work(unsigned w,unsigned known) {
    if (!enabled) return;
    diag_tick();
    if (!known) close_episode(w,0);
    else if (!workers[w].known) ++supplies[w].known_packets;
    workers[w].known=known;
}
void yolo32_diag_conv_next(unsigned w,unsigned next) { if (enabled) workers[w].next=next; }
void yolo32_diag_packet_start(unsigned w) {
    if (!enabled) return;
    diag_tick(); close_episode(w,1); workers[w].known=0; ++supplies[w].submitted_packets;
}
void yolo32_diag_packet_return(unsigned w,unsigned funct) {
    if (enabled && funct==15) yolo32_diag_work(w,workers[w].next);
}
void yolo32_diag_native_begin(unsigned w) {
    if (detail) workers[w].native_token=yolo32_diag_push(w,DIAG_NATIVE);
}
void yolo32_diag_native_end(unsigned w) { if (detail) yolo32_diag_pop(w,workers[w].native_token); }
void yolo32_diag_counter(unsigned w,unsigned index,uint32_t value) {
    if (enabled && index<6) totals[w][index]=value;
}
void yolo32_diag_hw_begin(unsigned w,const uint32_t values[6]) {
    if (enabled) memcpy(workers[w].hw_start,values,sizeof(workers[w].hw_start));
}
void yolo32_diag_hw_end(unsigned w,const uint32_t values[6]) {
    if (!enabled || workers[w].stage>=YOLO32_GRAPH_STAGES) return;
    Yolo32DiagStage *s=&stages[w][workers[w].stage];
    for (unsigned i=0;i<6;++i) s->hw[i]+=values[i]-workers[w].hw_start[i];
    ++s->hw_valid;
}
void yolo32_diag_copy(unsigned w,uint64_t read_bytes,uint64_t write_bytes) {
    if (enabled && workers[w].stage<YOLO32_GRAPH_STAGES) {
        stages[w][workers[w].stage].copy_read_bytes+=read_bytes;
        stages[w][workers[w].stage].copy_write_bytes+=write_bytes;
    }
}
void yolo32_diag_scheduler_bind(unsigned w,uint64_t cycles) {
    if (enabled && owner==3) supplies[w].scheduler_bind_cycles+=cycles;
}
const Yolo32DiagCredit *yolo32_diag_credit(unsigned w,unsigned source) { return &credits[w][source]; }
const Yolo32DiagSupply *yolo32_diag_supply(unsigned w) { return &supplies[w]; }
const Yolo32DiagStage *yolo32_diag_stage(unsigned w,unsigned stage) { return &stages[w][stage]; }
static void field(const char *name,uint64_t value) {
    console_putc(' '); console_puts(name); console_putc('=');
    if (value<=UINT32_MAX) console_put_u32((uint32_t)value); else console_put_hex64(value);
}
void yolo32_diag_print(unsigned independent) {
    if (!enabled) return;
    yolo32_diag_owner(3);
    static const char *const names[]={"peer","scheduler","admit","resume","observer"};
    if (independent) for (unsigned w=0;w<3;++w) {
        for (unsigned source=0;source<DIAG_SOURCES;++source) {
            const Yolo32DiagCredit *r=&credits[w][source];
            console_puts("YOLO32_CREDIT_SOURCE"); field("worker",w);
            console_puts(" source="); console_puts(names[source]);
            field("checks",r->checks); field("cycles",r->cycles); field("ready",r->ready);
            field("budget_only",r->budget_only); field("hardware_only",r->hardware_only); field("both",r->both);
            field("hw_slots_full",r->hw_slots_full); field("hw_queue_full",r->hw_queue_full);
            field("hw_partial",r->hw_partial); field("hw_unknown",r->hw_unknown);
            field("pending0",r->pending[0]); field("pending1",r->pending[1]);
            field("pending2",r->pending[2]); field("pending3",r->pending[3]); console_puts("\r\n");
        }
        const Yolo32DiagSupply *s=&supplies[w];
        console_puts("YOLO32_SUPPLY"); field("worker",w); field("events",s->events);
        field("gap_cycles",s->gap_cycles); field("peer_cycles",s->peer_cycles);
        field("scheduler_cycles",s->scheduler_cycles); field("self_cycles",s->self_cycles); field("max_gap",s->max_gap);
        field("withdrawn_events",s->withdrawn_events); field("withdrawn_cycles",s->withdrawn_cycles);
        field("positive_samples",s->positive_samples); field("known_packets",s->known_packets);
        field("submitted_packets",s->submitted_packets); field("scheduler_bind_cycles",s->scheduler_bind_cycles);
        for(unsigned i=0;i<4;++i) { static const char *const n[]={"admit0","admit1","admit2","admit3"}; field(n[i],s->admitted[i]); }
        console_puts("\r\n");
    }
    static const char *const cats[]={"other","interpret","prepare","address","bind","credit","native","policy","copy","resize","maxpool","instrument"};
    static const char *const hw[]={"busy","load_dma","load_spad","exec","store_dma","store_spad"};
    for (unsigned w=0;w<3;++w) {
        console_puts("YOLO32_HW_TOTAL"); field("worker",w);
        for (unsigned i=0;i<6;++i) field(hw[i],totals[w][i]);
        console_puts("\r\n");
    }
    for (unsigned w=0;w<3;++w) for (unsigned stage=0;stage<YOLO32_GRAPH_STAGES;++stage) {
        const Yolo32DiagStage *s=&stages[w][stage];
        if (detail) {
        console_puts("YOLO32_CPU_DETAIL"); field("worker",w); field("stage",stage);
        for(unsigned i=0;i<DIAG_CATEGORIES;++i) field(cats[i],s->cpu[i]);
        field("copy_read",s->copy_read_bytes); field("copy_write",s->copy_write_bytes); console_puts("\r\n");
        console_puts("YOLO32_HW_STAGE"); field("worker",w); field("stage",stage); field("samples",s->hw_valid);
        for(unsigned i=0;i<6;++i) field(hw[i],s->hw[i]);
        console_puts("\r\n");
        }
        if (independent && s->flow.checks) {
            const Yolo32DiagFlow *f=&s->flow;
            console_puts("YOLO32_FEED_STAGE"); field("worker",w); field("stage",stage);
            field("checks",f->checks); field("ready",f->ready); field("budget_only",f->budget_only);
            field("hardware_only",f->hardware_only); field("both",f->both);
            field("pending0",f->pending[0]); field("pending1",f->pending[1]);
            field("pending2",f->pending[2]); field("pending3",f->pending[3]);
            field("events",f->events); field("gap_cycles",f->gap_cycles);
            field("peer_cycles",f->peer_cycles); field("scheduler_cycles",f->scheduler_cycles);
            field("self_cycles",f->self_cycles); console_puts("\r\n");
        }
    }
}
#endif
