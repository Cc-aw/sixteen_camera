#ifndef AI_TINYYOLOV2_RUNTIME_ADAPTER_H
#define AI_TINYYOLOV2_RUNTIME_ADAPTER_H

#include <stdint.h>

#include "ai_inference_runtime.h"
#include "tinyyolov2_runtime.h"

int inference_tinyyolov2_open(void);
int inference_tinyyolov2_run(const int8_t *input, const char *input_name,
                             struct tinyyolov2_result *result);
int inference_tinyyolov2_close(void);

#endif
