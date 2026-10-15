#ifndef YOLO32_DIAGNOSTICS_H
#define YOLO32_DIAGNOSTICS_H
#include <stdint.h>
#ifndef YOLO32_SUPPLY_DIAG
#define YOLO32_SUPPLY_DIAG 0
#endif
#if YOLO32_SUPPLY_DIAG != 0 && YOLO32_SUPPLY_DIAG != 1
#error "YOLO32_SUPPLY_DIAG must be 0 or 1"
#endif
enum { DIAG_PEER, DIAG_SCHEDULER, DIAG_ADMIT, DIAG_RESUME, DIAG_OBSERVE, DIAG_SOURCES };
enum { DIAG_OTHER, DIAG_INTERPRET, DIAG_PREPARE, DIAG_ADDRESS, DIAG_BIND,
       DIAG_CREDIT, DIAG_NATIVE, DIAG_POLICY, DIAG_COPY, DIAG_RESIZE,
       DIAG_MAXPOOL, DIAG_INSTRUMENT, DIAG_CATEGORIES };
#if YOLO32_SUPPLY_DIAG
typedef struct {
    uint64_t checks, cycles, ready, budget_only, hardware_only, both;
    uint64_t hw_slots_full, hw_queue_full, hw_partial, hw_unknown;
    uint64_t pending[4];
} Yolo32DiagCredit;
typedef struct {
    uint64_t events, gap_cycles, peer_cycles, scheduler_cycles, self_cycles, max_gap;
    uint64_t withdrawn_events, withdrawn_cycles, positive_samples;
    uint64_t admitted[4], known_packets, submitted_packets, scheduler_bind_cycles;
} Yolo32DiagSupply;
typedef struct {
    uint64_t checks, ready, budget_only, hardware_only, both, pending[4];
    uint64_t events, gap_cycles, peer_cycles, scheduler_cycles, self_cycles;
} Yolo32DiagFlow;
typedef struct {
    uint64_t cpu[DIAG_CATEGORIES], copy_read_bytes, copy_write_bytes;
    Yolo32DiagFlow flow;
    uint32_t hw[6];
    unsigned hw_valid;
} Yolo32DiagStage;
void yolo32_diag_reset(unsigned enabled);
void yolo32_diag_set_detail(unsigned detail);
unsigned yolo32_diag_detail_enabled(void);
void yolo32_diag_owner(unsigned owner); /* 0..2 task, 3 scheduler. */
void yolo32_diag_stage_begin(unsigned worker, unsigned stage, const char *kind);
void yolo32_diag_stage_end(unsigned worker);
unsigned yolo32_diag_push(unsigned worker, unsigned category);
void yolo32_diag_pop(unsigned worker, unsigned token);
void yolo32_diag_credit_status(unsigned worker, uint64_t status);
void yolo32_diag_credit_record(unsigned worker, unsigned pending, unsigned source, uint64_t cycles);
void yolo32_diag_admitted(unsigned worker, unsigned pending);
void yolo32_diag_work(unsigned worker, unsigned known);
void yolo32_diag_conv_next(unsigned worker, unsigned next);
void yolo32_diag_packet_start(unsigned worker);
void yolo32_diag_packet_return(unsigned worker, unsigned funct);
void yolo32_diag_native_begin(unsigned worker);
void yolo32_diag_native_end(unsigned worker);
void yolo32_diag_hw_begin(unsigned worker, const uint32_t values[6]);
void yolo32_diag_hw_end(unsigned worker, const uint32_t values[6]);
void yolo32_diag_counter(unsigned worker, unsigned index, uint32_t value);
void yolo32_diag_copy(unsigned worker, uint64_t read_bytes, uint64_t write_bytes);
void yolo32_diag_scheduler_bind(unsigned worker, uint64_t cycles);
void yolo32_diag_print(unsigned independent);
const Yolo32DiagCredit *yolo32_diag_credit(unsigned worker, unsigned source);
const Yolo32DiagSupply *yolo32_diag_supply(unsigned worker);
const Yolo32DiagStage *yolo32_diag_stage(unsigned worker, unsigned stage);
unsigned yolo32_diag_enabled(void);
#else
/* Also usable by native-stream adapters borrowing the production clock hook. */
#define YOLO32_DIAG_NATIVE_BEGIN() ((void)0)
#define YOLO32_DIAG_NATIVE_END() ((void)0)
#endif
#endif
