#ifndef BUDDY_RVV_MEM_H
#define BUDDY_RVV_MEM_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Pointers are i64 so MLIR can call via extract_aligned_pointer_as_index. */

void buddy_rvv_memset_i8(int64_t dst_ptr, int64_t value, int64_t nbytes);
void _mlir_ciface_buddy_rvv_memset_i8(int64_t dst_ptr, int64_t value,
                                      int64_t nbytes);

void buddy_rvv_memcpy_i8(int64_t dst_ptr, int64_t src_ptr, int64_t nbytes);
void _mlir_ciface_buddy_rvv_memcpy_i8(int64_t dst_ptr, int64_t src_ptr,
                                      int64_t nbytes);

/* Copy `rows` rows of `cols` bytes. Strides are in bytes (i8 elems).
 * In-place with dst_stride < src_stride copies last row first. */
void buddy_rvv_copy_rows_i8(int64_t dst_ptr, int64_t src_ptr, int64_t rows,
                            int64_t cols, int64_t dst_stride,
                            int64_t src_stride);
void _mlir_ciface_buddy_rvv_copy_rows_i8(int64_t dst_ptr, int64_t src_ptr,
                                         int64_t rows, int64_t cols,
                                         int64_t dst_stride,
                                         int64_t src_stride);

/* Store mcycle into buddy_layer_cycles[id]. Dump from the runner AFTER
 * forward so UART does not pollute later layers. */
enum { BUDDY_LAYER_TICK_CAP = 16 };
extern uint64_t buddy_layer_cycles[BUDDY_LAYER_TICK_CAP];
extern int buddy_layer_nticks;
void buddy_layer_tick(int64_t id);
void _mlir_ciface_buddy_layer_tick(int64_t id);

#ifdef __cplusplus
}
#endif

#endif
