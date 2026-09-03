#ifndef GEMCC_RT_OPS_H
#define GEMCC_RT_OPS_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Typed GemCC runtime ABI. Compiler lowering emits these symbols.
 * Implementations live in gemcc_kernel_*_scalar. buddy_* remains a
 * compat entry and must not be the semantic source. */

void gemcc_rt_silu_i8(int64_t dst, int64_t src, int64_t n, int64_t h,
                      int64_t w, int64_t c, float scale);
/* i8 -> f32: dst leaves the INT8 domain, so dst must not alias src. */
void gemcc_rt_silu_dequant_i8_f32(int64_t dst, int64_t src, int64_t n,
                                  int64_t h, int64_t w, int64_t c,
                                  float scale);
void gemcc_rt_sigmoid_dequant_i8_f32(int64_t dst, int64_t src, int64_t n,
                                     int64_t h, int64_t w, int64_t c,
                                     float scale);
void gemcc_rt_pool_same_upper_i8(int64_t dst, int64_t src, int64_t n,
                                 int64_t h, int64_t w, int64_t c);
void gemcc_rt_requantize_i8(int64_t dst, int64_t src, int64_t count,
                            float input_scale, float output_scale);
void gemcc_rt_leaky_relu_i8(int64_t buf, int64_t n);
void gemcc_rt_maxpool_valid_s2_i8(int64_t dst, int64_t src, int64_t n,
                                  int64_t h, int64_t w, int64_t c);

/* gemcc.sync is not lowered. This symbol is not a legal fence. */
void gemcc_rt_sync(int64_t kind);

#ifdef __cplusplus
}
#endif

#endif
