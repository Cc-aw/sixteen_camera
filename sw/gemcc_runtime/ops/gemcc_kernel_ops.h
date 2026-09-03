#ifndef GEMCC_KERNEL_OPS_H
#define GEMCC_KERNEL_OPS_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Scalar kernel implementations for typed gemcc semantic ops.
 * gemcc_rt_* is the compiler ABI; these functions are replaceable
 * implementations. buddy_* compat wrappers may call the same kernels.
 * RVV variants belong to a later CPU ISA strategy, not this file. */

void gemcc_kernel_silu_i8_scalar(int8_t *dst, const int8_t *src, int64_t n,
                                 int64_t h, int64_t w, int64_t c, float siluc);
/* The i8 -> f32 pair reads src while writing dst, so the buffers must not
 * overlap.  Disjointness is a caller contract checked by the op verifier; the
 * pointer-equality guard below is only a last-resort net and cannot see a
 * partial overlap. */
void gemcc_kernel_silu_dequant_i8_f32_scalar(float *dst, const int8_t *src,
                                             int64_t n, int64_t h, int64_t w,
                                             int64_t c, float siluc);
void gemcc_kernel_sigmoid_dequant_i8_f32_scalar(float *dst, const int8_t *src,
                                                int64_t n, int64_t h,
                                                int64_t w, int64_t c,
                                                float out_scale);
void gemcc_kernel_pool_same_upper_i8_scalar(int8_t *dst, const int8_t *src,
                                            int64_t n, int64_t h, int64_t w,
                                            int64_t c);
void gemcc_kernel_requantize_i8_scalar(int8_t *dst, const int8_t *src,
                                       int64_t count, float input_scale,
                                       float output_scale);
void gemcc_kernel_leaky_relu_i8_scalar(int8_t *buf, int64_t n);
void gemcc_kernel_maxpool_valid_s2_i8_scalar(int8_t *dst, const int8_t *src,
                                             int64_t n, int64_t h, int64_t w,
                                             int64_t c);

#ifdef __cplusplus
}
#endif

#endif
