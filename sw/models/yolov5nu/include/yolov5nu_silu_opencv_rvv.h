#ifndef YOLOV5NU_SILU_OPENCV_RVV_H
#define YOLOV5NU_SILU_OPENCV_RVV_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

void opencv_rvv_silu_two_step_i8(const int8_t *src, int8_t *dst,
    size_t count, float input_scale, float sigmoid_scale, float output_scale);

#ifdef __cplusplus
}
#endif

#endif
