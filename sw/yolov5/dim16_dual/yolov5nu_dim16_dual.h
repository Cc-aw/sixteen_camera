#ifndef YOLOV5NU_DIM16_DUAL_H
#define YOLOV5NU_DIM16_DUAL_H

#include <stdint.h>

#define YOLOV5NU_DIM16_WORKER_COUNT 2U
#define YOLOV5NU_DIM16_INPUT_WIDTH 640U
#define YOLOV5NU_DIM16_INPUT_HEIGHT 480U
#define YOLOV5NU_DIM16_INPUT_CHANNELS 3U
#define YOLOV5NU_DIM16_INPUT_BYTES \
    (YOLOV5NU_DIM16_INPUT_WIDTH * YOLOV5NU_DIM16_INPUT_HEIGHT * \
     YOLOV5NU_DIM16_INPUT_CHANNELS)
#define YOLOV5NU_DIM16_MAX_DETECTIONS 10U

enum {
    YOLOV5NU_DIM16_ERROR = -1,
    YOLOV5NU_DIM16_RUNNING = 0,
    YOLOV5NU_DIM16_DONE = 1,
    YOLOV5NU_DIM16_HEAD_READY = 2
};

struct yolov5nu_dim16_detection {
    float score;
    float center_x;
    float center_y;
    float width;
    float height;
    int class_id;
};

struct yolov5nu_dim16_result {
    uint32_t count;
    int64_t class_logits_checksum;
    uint64_t class_logits_fnv1a;
    int64_t class_scores_checksum;
    uint64_t class_scores_fnv1a;
    int64_t sparse_dfl_checksum;
    uint64_t sparse_dfl_fnv1a;
    uint32_t dfl_candidate_count;
    struct yolov5nu_dim16_detection detections[
        YOLOV5NU_DIM16_MAX_DETECTIONS];
};

/* Per-inference counters. Gemmini fields come from the accelerator's own
 * event counters; RVV/RoCC/fence fields are CPU rdcycle deltas. */
struct yolov5nu_dim16_profile {
    uint64_t rocc_submit_cycles;
    uint64_t gemmini_busy_cycles;
    uint64_t gemmini_load_stall_cycles;
    uint64_t gemmini_exec_cycles;
    uint64_t gemmini_store_stall_cycles;
    uint64_t rvv_maxpool_cycles;
    uint64_t rvv_resize_cycles;
    uint64_t rvv_copy_requant_cycles;
    uint64_t fence_cycles;
};

void yolov5nu_dim16_dual_init(void);
int yolov5nu_dim16_worker_is_idle(uint32_t worker_id);
int yolov5nu_dim16_worker_start(uint32_t worker_id, const int8_t *input);
int yolov5nu_dim16_worker_start_reference(uint32_t worker_id);
int yolov5nu_dim16_worker_poll(uint32_t worker_id,
                              struct yolov5nu_dim16_result *result);
uint32_t yolov5nu_dim16_worker_stage(uint32_t worker_id);
uint64_t yolov5nu_dim16_worker_busy(uint32_t worker_id);
int yolov5nu_dim16_worker_get_profile(
    uint32_t worker_id, struct yolov5nu_dim16_profile *profile);
void yolov5nu_dim16_worker_use_hardware(uint32_t worker_id, int enabled);
uintptr_t yolov5nu_dim16_worker_arena(uint32_t worker_id);
/*
 * Select a dedicated raw-head destination before the first worker poll.
 * A zero address preserves the legacy activation-arena layout used by the
 * software fallback and the static hardware/software comparison.
 */
void yolov5nu_dim16_worker_set_head_slot(uint32_t worker_id,
                                        uintptr_t head_slot_addr);
uintptr_t yolov5nu_dim16_worker_head_slot(uint32_t worker_id);
void yolov5nu_dim16_worker_finish_hardware(uint32_t worker_id);
// Resume the software head/Decode/NMS path from raw Gemmini heads retained
// after YOLOV5NU_DIM16_HEAD_READY. Used by the static PPU comparison.
int yolov5nu_dim16_worker_finish_software(uint32_t worker_id,
    struct yolov5nu_dim16_result *result);

#endif
