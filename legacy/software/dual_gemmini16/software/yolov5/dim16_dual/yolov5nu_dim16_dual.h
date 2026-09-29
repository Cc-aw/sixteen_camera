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
    YOLOV5NU_DIM16_DONE = 1
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

void yolov5nu_dim16_dual_init(void);
int yolov5nu_dim16_worker_is_idle(uint32_t worker_id);
int yolov5nu_dim16_worker_start(uint32_t worker_id, const int8_t *input);
int yolov5nu_dim16_worker_start_reference(uint32_t worker_id);
int yolov5nu_dim16_worker_poll(uint32_t worker_id,
                              struct yolov5nu_dim16_result *result);
uint32_t yolov5nu_dim16_worker_stage(uint32_t worker_id);
uint64_t yolov5nu_dim16_worker_busy(uint32_t worker_id);

#endif
