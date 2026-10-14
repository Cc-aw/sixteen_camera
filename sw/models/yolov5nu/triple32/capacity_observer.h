#ifndef YOLO32_CAPACITY_OBSERVER_H
#define YOLO32_CAPACITY_OBSERVER_H
#include <stdint.h>
#define YOLO32_CAPACITY_TOP_GAPS 8U
typedef struct {
    uint64_t cycles;
    unsigned kind, stage, start_owner, start_stage, pending, start_busy;
} Yolo32CapacityGap;
typedef struct {
    uint64_t sources[4], queries, probes, pending_samples[5], pending_cycles[5];
    uint64_t budget_rejects, entrance_rejects, ready_queries;
    uint64_t known_probes, full_can, full_no, allowed_can, allowed_no;
    uint64_t known_busy, eligible_busy, eligible_idle;
    uint64_t retired_progress, retired_observed;
    uint64_t ready_events, ready_canceled, ready_cycles, ready_max;
    uint64_t refill_events, refill_canceled, refill_cycles, refill_max;
    uint64_t owner_cycles[4], observed_span;
    uint64_t submitted, first_submit, last_submit, graph_done, gap_candidates;
    unsigned gap_count;
    Yolo32CapacityGap gaps[YOLO32_CAPACITY_TOP_GAPS];
} Yolo32CapacityStats;
void yolo32_capacity_configure(unsigned period);
unsigned yolo32_capacity_period(void);
void yolo32_capacity_begin(void);
void yolo32_capacity_end(void);
void yolo32_capacity_query(unsigned worker, uint32_t issued, unsigned source,
                           unsigned decision_pending, unsigned decision_ready);
void yolo32_capacity_prepare(unsigned worker, unsigned stage, unsigned more);
void yolo32_capacity_return(unsigned worker, uint32_t issued);
void yolo32_capacity_owner(unsigned owner, unsigned stage);
void yolo32_capacity_done(unsigned worker);
void yolo32_capacity_print(void);
const Yolo32CapacityStats *yolo32_capacity_stats(unsigned worker);
/* Existing status CSR, including busy/queue/partial; not a new performance CSR. */
uint64_t yolo32_capacity_status(unsigned worker);
#endif
