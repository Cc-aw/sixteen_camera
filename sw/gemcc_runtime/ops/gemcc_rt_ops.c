#include "gemcc_rt_ops.h"

#include "gemcc_kernel_ops.h"

#include <stdint.h>

/* I: dst/src i64 指针，NHWC 尺寸，silu scale（siluc=output_scale/127）
 * P: typed gemcc.silu_i8 ABI，转发 scalar kernel
 * O: 写入 dst；无返回值
 * A: shiroha_suki
 * T: 2026-08-29
 */
void gemcc_rt_silu_i8(int64_t dst, int64_t src, int64_t n, int64_t h,
                      int64_t w, int64_t c, float scale) {
  gemcc_kernel_silu_i8_scalar((int8_t *)(uintptr_t)dst,
                              (const int8_t *)(uintptr_t)src, n, h, w, c,
                              scale);
}

/* I: dst 为 f32 缓冲的 i64 指针，src 为 i8，NHWC 尺寸，scale=output_scale
 * P: typed gemcc.silu_dequant_i8_f32 ABI，转发 scalar kernel
 * O: 写入 dst f32；无返回值
 * A: shiroha_suki
 * T: 2026-08-30
 */
void gemcc_rt_silu_dequant_i8_f32(int64_t dst, int64_t src, int64_t n,
                                  int64_t h, int64_t w, int64_t c,
                                  float scale) {
  gemcc_kernel_silu_dequant_i8_f32_scalar((float *)(uintptr_t)dst,
                                          (const int8_t *)(uintptr_t)src, n, h,
                                          w, c, scale);
}

/* I: dst 为 f32 缓冲的 i64 指针，src 为 i8，NHWC 尺寸，scale 为输入激活 scale
 * P: typed gemcc.sigmoid_dequant_i8_f32 ABI，转发 scalar kernel
 * O: 写入 dst f32；无返回值
 * A: shiroha_suki
 * T: 2026-08-30
 */
void gemcc_rt_sigmoid_dequant_i8_f32(int64_t dst, int64_t src, int64_t n,
                                     int64_t h, int64_t w, int64_t c,
                                     float scale) {
  gemcc_kernel_sigmoid_dequant_i8_f32_scalar((float *)(uintptr_t)dst,
                                             (const int8_t *)(uintptr_t)src, n,
                                             h, w, c, scale);
}

/* I: dst/src i64 指针，NHWC 尺寸
 * P: SAME_UPPER maxpool 的 typed runtime 入口，转发 scalar kernel
 * O: 写入 dst
 * A: shiroha_suki
 * T: 2026-08-29
 */
void gemcc_rt_pool_same_upper_i8(int64_t dst, int64_t src, int64_t n,
                                 int64_t h, int64_t w, int64_t c) {
  gemcc_kernel_pool_same_upper_i8_scalar((int8_t *)(uintptr_t)dst,
                                         (const int8_t *)(uintptr_t)src, n, h,
                                         w, c);
}

/* I: dst/src i64 指针，元素个数，input/output scale
 * P: 对称 per-tensor INT8 requant ABI
 * O: 写入 dst
 * A: shiroha_suki
 * T: 2026-08-29
 */
void gemcc_rt_requantize_i8(int64_t dst, int64_t src, int64_t count,
                            float input_scale, float output_scale) {
  gemcc_kernel_requantize_i8_scalar((int8_t *)(uintptr_t)dst,
                                    (const int8_t *)(uintptr_t)src, count,
                                    input_scale, output_scale);
}

/* I: 原地 i8 指针与元素个数
 * P: typed gemcc.leaky_relu_i8 ABI
 * O: 原地写入
 * A: shiroha_suki
 * T: 2026-08-29
 */
void gemcc_rt_leaky_relu_i8(int64_t buf, int64_t n) {
  gemcc_kernel_leaky_relu_i8_scalar((int8_t *)(uintptr_t)buf, n);
}

/* I: dst/src i64 指针，VALID 输入 NHWC 尺寸
 * P: typed gemcc.maxpool_valid_s2_i8 ABI
 * O: 写入 dst
 * A: shiroha_suki
 * T: 2026-08-29
 */
void gemcc_rt_maxpool_valid_s2_i8(int64_t dst, int64_t src, int64_t n,
                                  int64_t h, int64_t w, int64_t c) {
  gemcc_kernel_maxpool_valid_s2_i8_scalar((int8_t *)(uintptr_t)dst,
                                          (const int8_t *)(uintptr_t)src, n, h,
                                          w, c);
}

/* I: kind 0=fence 1=cpu_to_gemmini 2=gemmini_to_cpu
 * P: 占位；convert-gemcc-to-runtime 不得调用，真实 fence 接入前 fail closed
 * O: 无
 * A: shiroha_suki
 * T: 2026-08-29
 */
void gemcc_rt_sync(int64_t kind) { (void)kind; }
