#ifndef YOLO32_PPU_H
#define YOLO32_PPU_H
#include <stdint.h>
#define YOLO32_PPU_DETECTIONS 10U
/* Preserve the PPU's entire 128-bit result word, including score/class. */
typedef struct {
    uint32_t count;
    uint32_t words[YOLO32_PPU_DETECTIONS][4];
    uint32_t core_cycles;
    uint64_t wall_cycles, completed_cycle;
} Yolo32PpuResult;
void yolo32_ppu_init(void);
uintptr_t yolo32_ppu_begin(unsigned worker, uint64_t run);
void yolo32_ppu_head(unsigned worker, unsigned head);
void yolo32_ppu_graph_done(unsigned worker);
void yolo32_ppu_service(void);
unsigned yolo32_ppu_done(unsigned worker);
const Yolo32PpuResult *yolo32_ppu_result(unsigned worker);
typedef struct {
    uint64_t graph_done_cycle, publication_cycle, enqueue_cycle, result_cycle;
    uint64_t progress_cycle;
    unsigned enqueue_done_mask, result_done_mask, progress_done_mask;
} Yolo32PpuEvent;
typedef struct {
    unsigned published_mask, enqueued_mask, result_mask, progress_mask;
    uint64_t service_calls, service_cycles;
    Yolo32PpuEvent workers[3];
} Yolo32PpuEarlyStats;
void yolo32_ppu_early_begin(uint64_t batch_start, unsigned analysis);
void yolo32_ppu_early_service(void);
const Yolo32PpuEarlyStats *yolo32_ppu_early_stats(void);
typedef struct {
    uint64_t completed_cycle, publication_cycle, ready_cycle;
    uint32_t requests;
} Yolo32PpuHeadEvent;
typedef struct {
    unsigned published_heads[3], ready_at_finish[3], allocated_at_finish[3];
    uint64_t finish_sample_cycle[3], publication_transactions;
    Yolo32PpuHeadEvent heads[3][6];
} Yolo32PpuHeadStats;
const Yolo32PpuHeadStats *yolo32_ppu_head_stats(void);
void yolo32_ppu_io_barrier(void);
#endif
