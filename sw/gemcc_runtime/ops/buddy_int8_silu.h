#ifndef BUDDY_INT8_SILU_H
#define BUDDY_INT8_SILU_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Compat runtime symbols. INT8 SiLU implementation is
 * gemcc_kernel_silu_i8_scalar; do not treat these names as compiler
 * semantics.
 *
 * INT8 Conv+SiLU epilogue matching quant_apply.silu_i8:
 * siluc = output_scale/127.
 *   lut_scale = siluc * 127
 *   lut[u] = round(sigmoid((u-128)*lut_scale)*127) clipped to [0,127]
 *   out = saturate_i8((q * lut[q+128] + 64) >> 7)
 * buffer is tile_conv's (N*H*W, C) i8, updated in place. */
void buddy_int8_silu_nhwc(int64_t ptr, int64_t n, int64_t h, int64_t w,
                          int64_t c, float siluc);
void _mlir_ciface_buddy_int8_silu_nhwc(int64_t ptr, int64_t n, int64_t h,
                                       int64_t w, int64_t c, float siluc);

/* Mixed Conv+SiLU epilogue matching @layerN:
 * The remaining dequant splat is siluc = output_scale/127.
 *   lut_scale = siluc * 127
 *   lut[u] = round(sigmoid((u-128)*lut_scale)*127) clipped to [0,127]
 *   out = q * lut[q+128] * siluc
 * src is tile_conv's (N*H*W, C) i8; dst is contiguous NHWC f32. */
void buddy_int8_silu_dequant_nhwc(int64_t dst_ptr, int64_t src_ptr, int64_t n,
                                 int64_t h, int64_t w, int64_t c,
                                 float siluc);
void _mlir_ciface_buddy_int8_silu_dequant_nhwc(int64_t dst_ptr, int64_t src_ptr,
                                              int64_t n, int64_t h, int64_t w,
                                              int64_t c, float siluc);

#ifdef __cplusplus
}
#endif

#endif
