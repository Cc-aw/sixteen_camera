#include "buddy_int8_silu.h"

#include "gemcc_kernel_ops.h"

#include <stdint.h>

/* I: ptr 为 NHWC i8，尺寸 n/h/w/c，siluc=output_scale/127
 * P: compat 入口，转发 gemcc_kernel_silu_i8_scalar 原地 SiLU
 * O: 写入 ptr；无返回值
 * A: shiroha_suki
 * T: 2026-08-25, 2026-08-29
 */
void _mlir_ciface_buddy_int8_silu_nhwc(int64_t ptr, int64_t n, int64_t h,
                                       int64_t w, int64_t c, float siluc) {
  int8_t *buf = (int8_t *)(uintptr_t)ptr;
  gemcc_kernel_silu_i8_scalar(buf, buf, n, h, w, c, siluc);
}

/* I: 同 _mlir_ciface_buddy_int8_silu_nhwc
 * P: 转发到 MLIR C iface
 * O: 原地写入 i8
 * A: shiroha_suki
 * T: 2026-08-25, 2026-08-29
 */
void buddy_int8_silu_nhwc(int64_t ptr, int64_t n, int64_t h, int64_t w,
                          int64_t c, float siluc) {
  _mlir_ciface_buddy_int8_silu_nhwc(ptr, n, h, w, c, siluc);
}

/* I: dst NHWC f32，src NHWC i8，尺寸与 siluc；dst 与 src 不能是同一缓冲
 * P: compat 入口，转发 gemcc_kernel_silu_dequant_i8_f32_scalar；默认链走
 *    gemcc.silu_dequant_i8_f32 -> gemcc_rt_silu_dequant_i8_f32
 * O: 写入 dst
 * A: shiroha_suki
 * T: 2026-08-25, 2026-08-29, 2026-08-30
 */
void _mlir_ciface_buddy_int8_silu_dequant_nhwc(int64_t dst_ptr, int64_t src_ptr,
                                              int64_t n, int64_t h, int64_t w,
                                              int64_t c, float siluc) {
  gemcc_kernel_silu_dequant_i8_f32_scalar((float *)(uintptr_t)dst_ptr,
                                          (const int8_t *)(uintptr_t)src_ptr, n,
                                          h, w, c, siluc);
}

/* I: 同 _mlir_ciface_buddy_int8_silu_dequant_nhwc
 * P: compat dequant 入口
 * O: 写入 dst f32
 * A: shiroha_suki
 * T: 2026-08-25, 2026-08-29
 */
void buddy_int8_silu_dequant_nhwc(int64_t dst_ptr, int64_t src_ptr, int64_t n,
                                 int64_t h, int64_t w, int64_t c,
                                 float siluc) {
  _mlir_ciface_buddy_int8_silu_dequant_nhwc(dst_ptr, src_ptr, n, h, w, c,
                                            siluc);
}
