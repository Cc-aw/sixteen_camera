#include "buddy_rvv_mem.h"

#include <stdint.h>

static inline void enable_vector_state(void) {
#ifdef BAREMETAL
  const uintptr_t state_mask = (3UL << 9) | (3UL << 13) | (3UL << 15);
  __asm__ volatile("csrs mstatus, %0" : : "r"(state_mask) : "memory");
#endif
}

static inline void rvv_copy_i8(const int8_t *src, int8_t *dst, int elems) {
  uintptr_t vl = 0;
  uintptr_t offset = 0;
  uintptr_t remaining = (uintptr_t)elems;
  while (remaining != 0) {
    __asm__ volatile(
        "vsetvli %[vl], %[n], e8, m1, ta, ma\n\t"
        "vle8.v v0, (%[src])\n\t"
        "vse8.v v0, (%[dst])\n\t"
        : [vl] "=&r"(vl)
        : [n] "r"(remaining), [src] "r"(src + offset), [dst] "r"(dst + offset)
        : "v0", "memory");
    if (vl == 0)
      break;
    offset += vl;
    remaining -= vl;
  }
}

static inline void rvv_memset_i8(int8_t *dst, int8_t value, int elems) {
  uintptr_t vl = 0;
  uintptr_t offset = 0;
  uintptr_t remaining = (uintptr_t)elems;
  while (remaining != 0) {
    __asm__ volatile(
        "vsetvli %[vl], %[n], e8, m1, ta, ma\n\t"
        "vmv.v.x v0, %[val]\n\t"
        "vse8.v v0, (%[dst])\n\t"
        : [vl] "=&r"(vl)
        : [n] "r"(remaining), [val] "r"((int)value), [dst] "r"(dst + offset)
        : "v0", "memory");
    if (vl == 0)
      break;
    offset += vl;
    remaining -= vl;
  }
}

void _mlir_ciface_buddy_rvv_memset_i8(int64_t dst_ptr, int64_t value,
                                      int64_t nbytes) {
  enable_vector_state();
  if (nbytes <= 0)
    return;
  rvv_memset_i8((int8_t *)(uintptr_t)dst_ptr, (int8_t)value, (int)nbytes);
}

void buddy_rvv_memset_i8(int64_t dst_ptr, int64_t value, int64_t nbytes) {
  _mlir_ciface_buddy_rvv_memset_i8(dst_ptr, value, nbytes);
}

void _mlir_ciface_buddy_rvv_memcpy_i8(int64_t dst_ptr, int64_t src_ptr,
                                      int64_t nbytes) {
  enable_vector_state();
  if (nbytes <= 0)
    return;
  rvv_copy_i8((const int8_t *)(uintptr_t)src_ptr, (int8_t *)(uintptr_t)dst_ptr,
              (int)nbytes);
}

void buddy_rvv_memcpy_i8(int64_t dst_ptr, int64_t src_ptr, int64_t nbytes) {
  _mlir_ciface_buddy_rvv_memcpy_i8(dst_ptr, src_ptr, nbytes);
}

void _mlir_ciface_buddy_rvv_copy_rows_i8(int64_t dst_ptr, int64_t src_ptr,
                                         int64_t rows, int64_t cols,
                                         int64_t dst_stride,
                                         int64_t src_stride) {
  enable_vector_state();
  if (rows <= 0 || cols <= 0)
    return;
  int8_t *dst = (int8_t *)(uintptr_t)dst_ptr;
  const int8_t *src = (const int8_t *)(uintptr_t)src_ptr;
  const int ncols = (int)cols;
  if (dst == src && dst_stride < src_stride) {
    for (int64_t row = rows - 1; row >= 0; --row) {
      rvv_copy_i8(src + row * src_stride, dst + row * dst_stride, ncols);
    }
    return;
  }
  for (int64_t row = 0; row < rows; ++row) {
    rvv_copy_i8(src + row * src_stride, dst + row * dst_stride, ncols);
  }
}

void buddy_rvv_copy_rows_i8(int64_t dst_ptr, int64_t src_ptr, int64_t rows,
                            int64_t cols, int64_t dst_stride,
                            int64_t src_stride) {
  _mlir_ciface_buddy_rvv_copy_rows_i8(dst_ptr, src_ptr, rows, cols, dst_stride,
                                      src_stride);
}

uint64_t buddy_layer_cycles[BUDDY_LAYER_TICK_CAP];
int buddy_layer_nticks;

void buddy_layer_tick(int64_t id) {
  uint64_t value;
#ifdef BAREMETAL
  __asm__ volatile("csrr %0, mcycle" : "=r"(value));
#else
  /* pk is U-mode; mcycle (0xB00) illegal. rdcycle / cycle (0xC00) is the
   * unprivileged counter (Spike --isa=..._zicntr). */
  __asm__ volatile("rdcycle %0" : "=r"(value));
#endif
  if (id < 0 || id >= BUDDY_LAYER_TICK_CAP)
    return;
  buddy_layer_cycles[id] = value;
  if ((int)id + 1 > buddy_layer_nticks)
    buddy_layer_nticks = (int)id + 1;
}

void _mlir_ciface_buddy_layer_tick(int64_t id) { buddy_layer_tick(id); }
