#ifndef TINYYOLOV2_RUNTIME_H
#define TINYYOLOV2_RUNTIME_H

#include <stdint.h>

#include "tinyyolov2_input_contract.h"

#define TINYYOLOV2_MAX_DETECTIONS          8
#define TINYYOLOV2_SCORE_THRESHOLD_MILLI 300
#define TINYYOLOV2_NMS_IOU_MILLI          450

struct tinyyolov2_detection {
  int score_milli;
  int class_id;
  int x_min;
  int y_min;
  int x_max;
  int y_max;
};

struct tinyyolov2_result {
  int count;
  struct tinyyolov2_detection detections[TINYYOLOV2_MAX_DETECTIONS];
};

typedef void (*tinyyolov2_layer_metrics_fn)(
    unsigned layer_index, uint64_t macs, uint64_t cycles,
    uint32_t load_active_cycles, uint32_t exe_active_cycles,
    uint32_t store_active_cycles, uint32_t output_elems);

typedef void (*tinyyolov2_layer_begin_fn)(
    unsigned layer_index, uint32_t input_height, uint32_t input_width,
    uint32_t input_channels, uint32_t output_height,
    uint32_t output_width, uint32_t output_channels);

/* Return a stable printable label for a VOC class ID. */
const char *tinyyolov2_class_name(int class_id);

/* Enable or suppress detailed per-layer and decode diagnostics. */
void tinyyolov2_set_diagnostics(int enabled);
void tinyyolov2_set_layer_begin_callback(tinyyolov2_layer_begin_fn callback);
void tinyyolov2_set_layer_metrics_callback(tinyyolov2_layer_metrics_fn callback);

/* Run inference and return thresholded, class-aware NMS detections. */
int tinyyolov2_run_detect(const int8_t *input, const char *input_name,
                          struct tinyyolov2_result *result);

/* Run one inference from a contract-compatible [1,H,W,C] NHWC RGB INT8 tensor. */
int tinyyolov2_run(const int8_t *input, const char *input_name);

/* Run the generated, embedded dog.jpg tensor and require a dog detection. */
int tinyyolov2_run_builtin_dog(void);

#endif
