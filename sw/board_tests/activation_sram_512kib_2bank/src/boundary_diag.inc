/* Software observations only. Query ABI checked against camera frontend RTL:
 * q0=status/FIFO, q1=fetched/issued, q2=completed/cursor, q4=FSM state.
 * FENCE_BUSY covers RUN as well as DRAIN; it is not a drain-wait counter.
 * No UART, allocation, or command-table mutation occurs in the timed path. */
enum { BOUNDARIES=13, BOUNDARY_SAMPLE_PERIOD=100000 };
static const char *executor_name(unsigned mode);
static void memory_boundary_begin(unsigned f,unsigned tag);
static void memory_boundary_end(unsigned f,unsigned tag);
struct Boundary {
    uint64_t start,ready_lo,pending,seen,cpu_begin,cpu_end,resume_begin,resume_end,irq_hint;
    uint64_t probe_cycles,cursor_hold_min,anchor_end;
    unsigned samples,run,drain,host,done,other,transition;
    unsigned run_empty,run_idle_empty,drain_busy,drain_idle;
    unsigned drain_barrier,drain_host,drain_finish;
    unsigned cursor_max,fetched_max,issued_max,fifo_max,last_cursor,anchor_valid;
    uint64_t direct_fence_cycles;
    unsigned direct_fence_calls;
};
struct BoundaryFrame {
    struct Boundary part[BOUNDARIES];
    uint64_t launch_begin,launch_end;
};
static struct BoundaryFrame boundary_frames[FRAMES];
static struct Boundary *boundary_current(unsigned f) {
    if(f>=FRAMES||frames[f].host_next>12)at_fail("boundary_index",f);
    return &boundary_frames[f].part[frames[f].host_next];
}
static void boundary_launch(unsigned f,uint64_t begin,uint64_t end) {
    struct BoundaryFrame *d=&boundary_frames[f];
    d->launch_begin=begin;d->launch_end=end;
    d->part[0].start=frames[f].begin;d->part[0].ready_lo=begin;
}
static void boundary_direct_start(unsigned f) {
    boundary_launch(f,frames[f].begin,clock_cycle());
}
static void boundary_seen(unsigned f,uint64_t at) {
    struct Boundary *b=boundary_current(f);
    if(!b->seen){b->seen=at;memory_boundary_end(f,frames[f].host_next+1);}
}
static void boundary_pending(unsigned mask,uint64_t at,uint64_t hint) {
    for(unsigned d=0;d<3;d++)if(mask&(1U<<d)) {
        if(bound[d]<0)at_fail("boundary_unbound_pending",d);
        unsigned f=bound[d];struct Boundary *b=boundary_current(f);
        if(!b->pending)b->pending=at;
        /* Shared IRQ timestamp is context, never a per-lane event timestamp. */
        if(!b->irq_hint&&hint>=b->ready_lo&&hint<=at)b->irq_hint=hint;
    }
}
static void boundary_cpu_begin(unsigned f,unsigned tag,uint64_t at) {
    if(tag<1||tag>12)at_fail("boundary_host_tag",tag);
    struct Boundary *b=&boundary_frames[f].part[tag-1];
    if(!b->seen||b->cpu_begin)at_fail("boundary_missing_seen",tag);
    b->cpu_begin=at;
}
static void boundary_cpu_end(unsigned f,unsigned tag,uint64_t at) {
    boundary_frames[f].part[tag-1].cpu_end=at;
}
static void boundary_resume_begin(unsigned f,unsigned tag,uint64_t at) {
    boundary_frames[f].part[tag-1].resume_begin=at;
}
static void boundary_resume_end(unsigned f,unsigned tag,uint64_t at) {
    struct Boundary *b=&boundary_frames[f].part[tag-1];b->resume_end=at;
    struct Boundary *next=&boundary_frames[f].part[tag];
    next->start=at;
    /* Hardware resumes inside the control call, possibly before its return. */
    next->ready_lo=b->resume_begin;
}
static void boundary_graph_end(unsigned f,uint64_t at) {
    struct Boundary *b=&boundary_frames[f].part[12];
    if(!b->seen)b->seen=at;
    if(!b->start||b->seen>at)at_fail("boundary_tail",f);
}
static void boundary_direct_fence(unsigned f) {
    struct Boundary *b=boundary_current(f);uint64_t begin=clock_cycle();
    gf_publish();b->direct_fence_cycles+=clock_cycle()-begin;b->direct_fence_calls++;
}
static void boundary_probe_active(void) {
    for(unsigned d=0;d<3;d++)if(bound[d]>=0&&frames[bound[d]].state==1) {
        unsigned f=bound[d];struct Boundary *b=boundary_current(f);struct Plan *p=frames[f].plan;
        uint64_t begin=clock_cycle();
        uint64_t a=gf_read(d,4,0),c0=gf_read(d,2,0),status=gf_status(d);
        uint64_t counts=gf_read(d,1,0),c1=gf_read(d,2,0),z=gf_read(d,4,0);
        uint64_t end=clock_cycle();unsigned cursor=(uint32_t)c1;
        if(a>6||z>6||(status&GF_FAULT))at_fail("boundary_probe_abi_or_fault",status);
        if(cursor>p->count||(uint32_t)counts>p->raw||(counts>>32)>p->count)
            at_fail("boundary_probe_counts",c1);
        b->probe_cycles+=end-begin;b->samples++;
        if(cursor>b->cursor_max)b->cursor_max=cursor;
        if((counts>>32)>b->fetched_max)b->fetched_max=counts>>32;
        if((uint32_t)counts>b->issued_max)b->issued_max=(uint32_t)counts;
        unsigned fifo=(status>>16)&65535;if(fifo>b->fifo_max)b->fifo_max=fifo;
        if(a!=z||c0!=c1) {b->transition++;b->anchor_valid=0;continue;}
        /* Reads are sequential, not an atomic hardware snapshot. Stability
         * checks reject visible transitions; classification remains sampled. */
        if(a==1) {
            b->run++;
            if(!fifo){b->run_empty++;if(!(status&GF_GEMMINI_BUSY))b->run_idle_empty++;}
        }else if(a==2) {
            b->drain++;
            if(status&GF_GEMMINI_BUSY)b->drain_busy++;else b->drain_idle++;
            unsigned kind=cursor?(p->commands[cursor-1].control&255):GF_RAW;
            if(kind==GF_DRAIN)b->drain_barrier++;
            else if(kind==GF_HOST)b->drain_host++;
            else b->drain_finish++;
        }else if(a==3){b->host++;boundary_seen(f,end);}
        else if(a==4){b->done++;boundary_seen(f,end);}
        else b->other++;
        if(a==1||a==2) {
            if(begin>b->ready_lo)b->ready_lo=begin;
            if(b->anchor_valid&&cursor==b->last_cursor) {
                uint64_t held=begin>b->anchor_end?begin-b->anchor_end:0;
                if(held>b->cursor_hold_min)b->cursor_hold_min=held;
            }else {b->anchor_end=end;b->last_cursor=cursor;b->anchor_valid=1;}
        }else b->anchor_valid=0;
    }
}
static uint64_t boundary_relative(uint64_t t) {return t?t-batch_begin:0;}
static void boundary_report(unsigned mode) {
    for(unsigned f=0;f<run_frames;f++) {
        const struct Frame *t=&frames[f];const struct Plan *p=t->plan;
        const struct BoundaryFrame *d=&boundary_frames[f];unsigned cursor=0;
        for(unsigned i=0;i<BOUNDARIES;i++) {
            const struct Boundary *b=&d->part[i];unsigned raw=0,barriers=0;
            while(cursor<p->count) {
                unsigned kind=p->commands[cursor++].control&255;
                if(kind==GF_HOST)break;
                raw+=kind==GF_RAW;barriers+=kind==GF_DRAIN;
            }
            unsigned phase=i<12?p->hosts[i].phase:165,kind=i<12?p->hosts[i].kind:0;
            if(!b->start||!b->seen||b->ready_lo>b->seen||
               (i<12&&!(b->seen<=b->cpu_begin&&b->cpu_begin<b->cpu_end&&
                 b->cpu_end<=b->resume_begin&&b->resume_begin<b->resume_end)))
                at_fail("boundary_accounting",f*13+i);
            text("ATSOFT1,BOUNDARY,executor=");text(executor_name(mode));
            field(",frame=",f);field(",device=",t->device);field(",image=",t->image);
            field(",tag=",i+1);field(",phase=",phase);field(",kind=",kind);
            field(",raw=",raw);field(",barriers=",barriers);
            field(",start_cycles=",boundary_relative(b->start));
            field(",ready_lo_cycles=",boundary_relative(b->ready_lo));
            field(",pending_cycles=",boundary_relative(b->pending));
            field(",seen_cycles=",boundary_relative(b->seen));
            field(",cpu_begin_cycles=",boundary_relative(b->cpu_begin));
            field(",cpu_end_cycles=",boundary_relative(b->cpu_end));
            field(",resume_begin_cycles=",boundary_relative(b->resume_begin));
            field(",resume_end_cycles=",boundary_relative(b->resume_end));
            field(",irq_hint_cycles=",boundary_relative(b->irq_hint));
            field(",launch_begin_cycles=",i?0:boundary_relative(d->launch_begin));
            field(",launch_end_cycles=",i?0:boundary_relative(d->launch_end));
            field(",samples=",b->samples);field(",run=",b->run);field(",drain=",b->drain);
            field(",host=",b->host);field(",done=",b->done);field(",other=",b->other);
            field(",transition=",b->transition);field(",run_empty=",b->run_empty);
            field(",run_idle_empty=",b->run_idle_empty);field(",drain_busy=",b->drain_busy);
            field(",drain_idle=",b->drain_idle);field(",drain_barrier=",b->drain_barrier);
            field(",drain_host=",b->drain_host);field(",drain_finish=",b->drain_finish);
            field(",cursor_max=",b->cursor_max);field(",fetched_max=",b->fetched_max);
            field(",issued_max=",b->issued_max);field(",fifo_max=",b->fifo_max);
            field(",cursor_hold_min_cycles=",b->cursor_hold_min);
            field(",probe_query_cycles=",b->probe_cycles);
            field(",direct_fence_calls=",b->direct_fence_calls);
            field(",direct_fence_cycles=",b->direct_fence_cycles);text("\n");
        }
        if(cursor!=p->count)at_fail("boundary_table_coverage",f);
    }
}
