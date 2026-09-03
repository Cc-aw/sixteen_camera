#ifndef BUDDY_SAME_UPPER_MAXPOOL_H
#define BUDDY_SAME_UPPER_MAXPOOL_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Compat runtime symbols. Typed ABI is gemcc_rt_pool_same_upper_i8 /
 * gemcc_rt_maxpool_valid_s2_i8 over gemcc_kernel_*_scalar. This file
 * keeps the existing RVV board implementation until P8.2.
 *
 * Darknet stride-1 SAME_UPPER maxpool on NHWC int8.
 * Pointers are passed as i64 so MLIR can call via
 * memref.extract_aligned_pointer_as_index without a memref C ABI.
 * Matches wzr tinyyolov2.c (RVV vmax, edge = max2 / copy). */
void buddy_same_upper_maxpool_nhwc_i8(int64_t dst_ptr, int64_t src_ptr,
                                      int64_t n, int64_t h, int64_t w,
                                      int64_t c);
void _mlir_ciface_buddy_same_upper_maxpool_nhwc_i8(int64_t dst_ptr,
                                                   int64_t src_ptr, int64_t n,
                                                   int64_t h, int64_t w,
                                                   int64_t c);

/* VALID 2x2 stride-2 NHWC int8. Unfused fallback; the INT8 rewrite pass
 * folds this into tile_conv poolSize=2. */
void buddy_maxpool_nhwc_2x2_s2_i8(int64_t dst_ptr, int64_t src_ptr, int64_t n,
                                  int64_t h, int64_t w, int64_t c);
void _mlir_ciface_buddy_maxpool_nhwc_2x2_s2_i8(int64_t dst_ptr, int64_t src_ptr,
                                               int64_t n, int64_t h, int64_t w,
                                               int64_t c);

#ifdef __cplusplus
}
#endif

#endif
