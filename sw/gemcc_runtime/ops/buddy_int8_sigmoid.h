#ifndef BUDDY_INT8_SIGMOID_H
#define BUDDY_INT8_SIGMOID_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Mixed detect-head sigmoid matching @layerN sigmoid_f32:
 *   lut[u] = round(sigmoid((u-128)*out_scale)*127)/127  clipped to [0,127]
 * src is tile_conv's (N*H*W, C) i8; dst is contiguous NHWC f32. */
void buddy_int8_sigmoid_dequant_nhwc(int64_t dst_ptr, int64_t src_ptr,
                                     int64_t n, int64_t h, int64_t w,
                                     int64_t c, float out_scale);
void _mlir_ciface_buddy_int8_sigmoid_dequant_nhwc(int64_t dst_ptr,
                                                  int64_t src_ptr, int64_t n,
                                                  int64_t h, int64_t w,
                                                  int64_t c, float out_scale);

#ifdef __cplusplus
}
#endif

#endif
