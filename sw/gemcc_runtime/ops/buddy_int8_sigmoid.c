#include "buddy_int8_sigmoid.h"

#include "gemcc_kernel_ops.h"

#include <stdint.h>

/* I: dst NHWC f32，src NHWC i8，尺寸 n/h/w/c，out_scale 为输入激活 scale；
 *    dst 与 src 不能是同一缓冲
 * P: compat 入口，转发 gemcc_kernel_sigmoid_dequant_i8_f32_scalar；默认链走
 *    gemcc.sigmoid_dequant_i8_f32 -> gemcc_rt_sigmoid_dequant_i8_f32
 * O: 写入 dst f32
 * A: shiroha_suki
 * T: 2026-08-30
 */
void _mlir_ciface_buddy_int8_sigmoid_dequant_nhwc(int64_t dst_ptr,
                                                  int64_t src_ptr, int64_t n,
                                                  int64_t h, int64_t w,
                                                  int64_t c, float out_scale) {
  gemcc_kernel_sigmoid_dequant_i8_f32_scalar(
      (float *)(uintptr_t)dst_ptr, (const int8_t *)(uintptr_t)src_ptr, n, h, w,
      c, out_scale);
}

/* I: 同 _mlir_ciface_buddy_int8_sigmoid_dequant_nhwc
 * P: compat dequant 入口
 * O: 写入 dst f32
 * A: shiroha_suki
 * T: 2026-08-30
 */
void buddy_int8_sigmoid_dequant_nhwc(int64_t dst_ptr, int64_t src_ptr, int64_t n,
                                     int64_t h, int64_t w, int64_t c,
                                     float out_scale) {
  _mlir_ciface_buddy_int8_sigmoid_dequant_nhwc(dst_ptr, src_ptr, n, h, w, c,
                                               out_scale);
}
