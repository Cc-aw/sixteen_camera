#include "buddy_int8_leaky.h"

#include "gemcc_kernel_ops.h"

#include <stdint.h>

/* I: 原地 i8 指针与元素个数
 * P: compat 入口，转发 gemcc_kernel_leaky_relu_i8_scalar
 * O: 原地写入
 * A: shiroha_suki
 * T: 2026-08-29
 */
void _mlir_ciface_buddy_int8_leaky_relu(int64_t ptr, int64_t n) {
  gemcc_kernel_leaky_relu_i8_scalar((int8_t *)(uintptr_t)ptr, n);
}

/* I: 同 _mlir_ciface_buddy_int8_leaky_relu
 * P: 转发 MLIR C iface
 * O: 原地写入
 * A: shiroha_suki
 * T: 2026-08-29
 */
void buddy_int8_leaky_relu(int64_t ptr, int64_t n) {
  _mlir_ciface_buddy_int8_leaky_relu(ptr, n);
}
