#include "independent.h"
#if YOLO32_CAPACITY_DIAG
#include <string.h>
#include "capacity_observer.h"
#include "yolo32.h"
#include "mmio.h"
#include "console.h"

/* Observations never decide readiness. Positive windows mean "last observed
 * eligible", not continuously measured hardware eligibility or idle time.
 * Keep aggregate counts and only the largest eight completed gaps per worker;
 * no unbounded event stream or UART output occurs in the timed path. */
static Yolo32CapacityStats results[3];
static struct {
    uint32_t issued, sampled_issued, sampled_pending;
    unsigned known, more, stage, sampled, pending;
    unsigned ready_open, refill_open;
    unsigned ready_owner, ready_stage, refill_owner, refill_stage;
    unsigned ready_pending, refill_pending, ready_busy, refill_busy;
    uint64_t ready_at, refill_at, sample_at;
} state[3];
static unsigned period, active, owner, owner_stage;
static uint64_t begin, owner_at;

void yolo32_capacity_configure(unsigned value) {
    if (active || (value && value!=16U && value!=64U)) yolo32_fail("capacity_period");
    period=value;
}
unsigned yolo32_capacity_period(void) { return period; }
static uint64_t account(void) {
    uint64_t now=read_cycle();
    for (unsigned w=0;w<3;++w)
        if (state[w].ready_open) results[w].owner_cycles[owner]+=now-owner_at;
    owner_at=now;
    return now;
}
void yolo32_capacity_owner(unsigned next, unsigned stage) {
    if (!active) return;
    if (next>3U) yolo32_fail("capacity_owner");
    (void)account(); owner=next; owner_stage=stage;
}
void yolo32_capacity_begin(void) {
    if (active) yolo32_fail("capacity_nested");
    if (!period) return;
    memset(results,0,sizeof(results)); memset(state,0,sizeof(state));
    owner=3; owner_stage=YOLO32_GRAPH_STAGES;
    begin=owner_at=read_cycle(); active=1;
}
static void cancel(unsigned w) {
    if (state[w].ready_open) ++results[w].ready_canceled;
    if (state[w].refill_open) ++results[w].refill_canceled;
    state[w].ready_open=state[w].refill_open=0;
}
static void probe(unsigned w, uint32_t issued) {
    /* Fresh, extra observation: do not reuse the policy's conservative cache.
     * The two reads are observations at different instants, not a reservation. */
    unsigned pending=yolo32_independent_credit_pending(w,issued);
    if (pending>YOLO32_CREDIT_LIMIT || pending>4U) yolo32_fail("capacity_pending");
    uint64_t status=yolo32_capacity_status(w), now=account();
    Yolo32CapacityStats *r=&results[w];
    unsigned can=(status&2U)!=0;
    ++r->probes; ++r->pending_samples[pending];
    uint32_t retired=0;
    if (state[w].sampled) {
        uint32_t new_issued=issued-state[w].sampled_issued;
        retired=new_issued+state[w].sampled_pending-pending;
        if (retired>new_issued+state[w].sampled_pending) yolo32_fail("capacity_retired");
        r->pending_cycles[state[w].sampled_pending]+=now-state[w].sample_at;
        r->observed_span+=now-state[w].sample_at;
        r->retired_observed+=retired;
        if (retired) ++r->retired_progress;
    }
    state[w].sampled=1; state[w].sampled_issued=issued;
    state[w].sampled_pending=pending; state[w].pending=pending; state[w].sample_at=now;
    if (!state[w].known) { cancel(w); return; }
    ++r->known_probes;
    if (status&1U) ++r->known_busy;
    if (pending==YOLO32_CREDIT_LIMIT) {
        if (can) ++r->full_can; else ++r->full_no;
    } else {
        if (can) ++r->allowed_can; else ++r->allowed_no;
    }
    /* A full software budget with can=1 is a capacity opportunity, recorded
     * separately above. It is not an eligible packet under THIS policy. */
    if (!can || pending>=YOLO32_CREDIT_LIMIT) { cancel(w); return; }
    if (status&1U) ++r->eligible_busy; else ++r->eligible_idle;
    if (!state[w].ready_open) {
        state[w].ready_open=1; state[w].ready_at=now;
        state[w].ready_owner=owner; state[w].ready_stage=owner_stage;
        state[w].ready_pending=pending; state[w].ready_busy=(status&1U)!=0;
    }
    if (retired && !state[w].refill_open) {
        state[w].refill_open=1; state[w].refill_at=now;
        state[w].refill_owner=owner; state[w].refill_stage=owner_stage;
        state[w].refill_pending=pending; state[w].refill_busy=(status&1U)!=0;
    }
}
void yolo32_capacity_query(unsigned w, uint32_t issued, unsigned source,
                           unsigned decision_pending, unsigned decision_ready) {
    if (!active) return;
    if (w>=3 || source>=4) yolo32_fail("capacity_query_source");
    Yolo32CapacityStats *r=&results[w];
    ++r->sources[source]; ++r->queries;
    if (decision_pending>YOLO32_CREDIT_LIMIT || decision_ready>1 ||
        (decision_ready && decision_pending==YOLO32_CREDIT_LIMIT)) yolo32_fail("capacity_decision");
    if (decision_ready) ++r->ready_queries;
    else if (decision_pending==YOLO32_CREDIT_LIMIT) ++r->budget_rejects;
    else ++r->entrance_rejects;
    if (((r->queries-1U)&(period-1U))==0U) probe(w,issued);
}
void yolo32_capacity_prepare(unsigned w, unsigned stage, unsigned more) {
    if (!active) return;
    if (w>=3 || stage>=YOLO32_GRAPH_STAGES || more>1) yolo32_fail("capacity_prepare");
    state[w].known=1; state[w].more=more; state[w].stage=stage;
}
static void gap(unsigned w, unsigned kind, uint64_t cycles, unsigned start_owner,
                unsigned start_stage, unsigned pending, unsigned busy) {
    Yolo32CapacityStats *r=&results[w]; ++r->gap_candidates;
    unsigned slot=r->gap_count;
    if (slot<YOLO32_CAPACITY_TOP_GAPS) ++r->gap_count;
    else {
        slot=0;
        for (unsigned i=1;i<YOLO32_CAPACITY_TOP_GAPS;++i)
            if (r->gaps[i].cycles<r->gaps[slot].cycles) slot=i;
        if (cycles<=r->gaps[slot].cycles) return;
    }
    r->gaps[slot]=(Yolo32CapacityGap){cycles,kind,state[w].stage,start_owner,start_stage,pending,busy};
}
void yolo32_capacity_return(unsigned w, uint32_t issued) {
    if (!active) return;
    if (w>=3 || issued!=state[w].issued+1U) yolo32_fail("capacity_packet_accounting");
    uint64_t now=account(); Yolo32CapacityStats *r=&results[w];
    state[w].issued=issued; ++r->submitted;
    if (r->submitted==1) r->first_submit=now-begin;
    r->last_submit=now-begin;
    if (state[w].ready_open) {
        uint64_t elapsed=now-state[w].ready_at;
        ++r->ready_events; r->ready_cycles+=elapsed;
        if (elapsed>r->ready_max) r->ready_max=elapsed;
        gap(w,0,elapsed,state[w].ready_owner,state[w].ready_stage,state[w].ready_pending,state[w].ready_busy);
    }
    if (state[w].refill_open) {
        uint64_t elapsed=now-state[w].refill_at;
        ++r->refill_events; r->refill_cycles+=elapsed;
        if (elapsed>r->refill_max) r->refill_max=elapsed;
        gap(w,1,elapsed,state[w].refill_owner,state[w].refill_stage,state[w].refill_pending,state[w].refill_busy);
    }
    state[w].ready_open=state[w].refill_open=0;
    state[w].known=state[w].more;
}
void yolo32_capacity_done(unsigned w) {
    if (!active) return;
    if (w>=3 || results[w].graph_done) yolo32_fail("capacity_done");
    uint64_t now=account(); cancel(w); state[w].known=0;
    results[w].graph_done=now-begin;
}
void yolo32_capacity_end(void) {
    if (!active) return;
    for (unsigned w=0;w<3;++w) {
        if (!results[w].graph_done) yolo32_fail("capacity_missing_done");
        probe(w,state[w].issued);
        if (state[w].pending) yolo32_fail("capacity_pending_at_end");
    }
    active=0;
}
const Yolo32CapacityStats *yolo32_capacity_stats(unsigned w) { return w<3 ? &results[w] : 0; }
static void field(const char *key, uint64_t value) {
    console_putc(' '); console_puts(key); console_putc('='); console_put_hex64(value);
}
void yolo32_capacity_print(void) {
    for (unsigned w=0;w<3;++w) {
        const Yolo32CapacityStats *r=&results[w];
        console_puts("YOLO32_CAPACITY"); field("worker",w); field("schema",1); field("period",period);
#define F(name) field(#name,r->name)
        F(queries); F(probes); field("retired_reads",r->probes); field("status_reads",r->probes);
        F(budget_rejects); F(entrance_rejects); F(ready_queries);
        field("peer_queries",r->sources[0]); field("scheduler_queries",r->sources[1]);
        field("admit_queries",r->sources[2]); field("resume_queries",r->sources[3]);
        F(known_probes); F(full_can); F(full_no); F(allowed_can); F(allowed_no);
        F(known_busy); F(eligible_busy); F(eligible_idle);
        F(retired_progress); F(retired_observed); F(ready_events); F(ready_canceled);
        F(ready_cycles); F(ready_max); F(refill_events); F(refill_canceled); F(refill_cycles); F(refill_max);
        F(submitted); F(first_submit); F(last_submit); F(graph_done); F(observed_span); F(gap_candidates);
        field("gap_kept",r->gap_count);
        const char *const samples[]={"pending0_samples","pending1_samples","pending2_samples","pending3_samples","pending4_samples"};
        const char *const cycles[]={"pending0_cycles","pending1_cycles","pending2_cycles","pending3_cycles","pending4_cycles"};
        const char *const owners[]={"owner0_cycles","owner1_cycles","owner2_cycles","scheduler_cycles"};
        for (unsigned i=0;i<5;++i) { field(samples[i],r->pending_samples[i]); field(cycles[i],r->pending_cycles[i]); }
        for (unsigned i=0;i<4;++i) field(owners[i],r->owner_cycles[i]);
        console_puts("\r\n");
        for (unsigned i=0;i<r->gap_count;++i) {
            const Yolo32CapacityGap *g=&r->gaps[i]; console_puts("YOLO32_CAPACITY_GAP");
            field("worker",w); field("index",i); field("kind",g->kind); field("cycles",g->cycles);
            field("stage",g->stage); field("start_owner",g->start_owner); field("start_stage",g->start_stage);
            field("pending",g->pending); field("start_busy",g->start_busy); console_puts("\r\n");
        }
#undef F
    }
}
#endif
