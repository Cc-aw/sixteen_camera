#ifndef BUDDY_INT8_LEAKY_H
#define BUDDY_INT8_LEAKY_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Compat runtime symbol wrapping gemcc_kernel_leaky_relu_i8_scalar.
 * MyBoard LEAKY_RELU (act=5): y = x >= 0 ? x : (x-5)/10, trunc toward 0.
 * Unfused fallback; --gemmini-int8-rewrite=fuse-leaky-pool folds the
 * typed gemcc.leaky_relu_i8 into tile_conv. Pointers are i64 for the
 * memref extract ABI. */
void buddy_int8_leaky_relu(int64_t ptr, int64_t n);
void _mlir_ciface_buddy_int8_leaky_relu(int64_t ptr, int64_t n);

#ifdef __cplusplus
}
#endif

#endif
