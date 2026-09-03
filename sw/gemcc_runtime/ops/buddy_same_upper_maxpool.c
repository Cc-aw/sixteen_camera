#include "buddy_same_upper_maxpool.h"

#include <stdint.h>

/* Match wzr tinyyolov2.c: inline RVV e8/m1, Saturn vLen=128. */

static inline void enable_vector_state(void) {
#ifdef BAREMETAL
  const uintptr_t state_mask = (3UL << 9) | (3UL << 13) | (3UL << 15);
  __asm__ volatile("csrs mstatus, %0" : : "r"(state_mask) : "memory");
#endif
}

static inline void rvv_max4_i8(const int8_t *a, const int8_t *b,
                               const int8_t *c, const int8_t *d, int8_t *out,
                               int elems) {
  uintptr_t vl = 0;
  uintptr_t offset = 0;
  uintptr_t remaining = (uintptr_t)elems;
  while (remaining != 0) {
    __asm__ volatile(
        "vsetvli %[vl], %[n], e8, m1, ta, ma\n\t"
        "vle8.v v0, (%[a])\n\t"
        "vle8.v v1, (%[b])\n\t"
        "vmax.vv v0, v0, v1\n\t"
        "vle8.v v1, (%[c])\n\t"
        "vmax.vv v0, v0, v1\n\t"
        "vle8.v v1, (%[d])\n\t"
        "vmax.vv v0, v0, v1\n\t"
        "vse8.v v0, (%[out])\n\t"
        : [vl] "=&r"(vl)
        : [n] "r"(remaining), [a] "r"(a + offset), [b] "r"(b + offset),
          [c] "r"(c + offset), [d] "r"(d + offset), [out] "r"(out + offset)
        : "v0", "v1", "memory");
    if (vl == 0)
      break;
    offset += vl;
    remaining -= vl;
  }
}

static inline void rvv_max2_i8(const int8_t *a, const int8_t *b, int8_t *out,
                               int elems) {
  uintptr_t vl = 0;
  uintptr_t offset = 0;
  uintptr_t remaining = (uintptr_t)elems;
  while (remaining != 0) {
    __asm__ volatile(
        "vsetvli %[vl], %[n], e8, m1, ta, ma\n\t"
        "vle8.v v0, (%[a])\n\t"
        "vle8.v v1, (%[b])\n\t"
        "vmax.vv v0, v0, v1\n\t"
        "vse8.v v0, (%[out])\n\t"
        : [vl] "=&r"(vl)
        : [n] "r"(remaining), [a] "r"(a + offset), [b] "r"(b + offset),
          [out] "r"(out + offset)
        : "v0", "v1", "memory");
    if (vl == 0)
      break;
    offset += vl;
    remaining -= vl;
  }
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

static void maxpool2x2_stride1_same_upper_rvv(const int8_t *restrict src,
                                             int8_t *restrict dst, int height,
                                             int width, int channels) {
  const int row_stride = width * channels;
  const int last_row = height - 1;
  const int last_col = width - 1;

  for (int row = 0; row < last_row; ++row) {
    const int8_t *row0 = src + row * row_stride;
    const int8_t *row1 = row0 + row_stride;
    int8_t *out = dst + row * row_stride;
    for (int col = 0; col < last_col; ++col) {
      const int8_t *p00 = row0 + col * channels;
      const int8_t *p01 = p00 + channels;
      const int8_t *p10 = row1 + col * channels;
      const int8_t *p11 = p10 + channels;
      rvv_max4_i8(p00, p01, p10, p11, out + col * channels, channels);
    }
    rvv_max2_i8(row0 + last_col * channels, row1 + last_col * channels,
                out + last_col * channels, channels);
  }

  const int8_t *bottom = src + last_row * row_stride;
  int8_t *bottom_out = dst + last_row * row_stride;
  for (int col = 0; col < last_col; ++col) {
    rvv_max2_i8(bottom + col * channels, bottom + (col + 1) * channels,
                bottom_out + col * channels, channels);
  }
  rvv_copy_i8(bottom + last_col * channels, bottom_out + last_col * channels,
              channels);
}

void _mlir_ciface_buddy_same_upper_maxpool_nhwc_i8(int64_t dst_ptr,
                                                   int64_t src_ptr, int64_t n,
                                                   int64_t h, int64_t w,
                                                   int64_t c) {
  enable_vector_state();
  int8_t *dst = (int8_t *)(uintptr_t)dst_ptr;
  const int8_t *src = (const int8_t *)(uintptr_t)src_ptr;
  const int64_t plane = h * w * c;
  for (int64_t ni = 0; ni < n; ++ni) {
    maxpool2x2_stride1_same_upper_rvv(src + ni * plane, dst + ni * plane,
                                      (int)h, (int)w, (int)c);
  }
}

void buddy_same_upper_maxpool_nhwc_i8(int64_t dst_ptr, int64_t src_ptr,
                                      int64_t n, int64_t h, int64_t w,
                                      int64_t c) {
  _mlir_ciface_buddy_same_upper_maxpool_nhwc_i8(dst_ptr, src_ptr, n, h, w, c);
}

static void maxpool2x2_stride2_valid(const int8_t *restrict src,
                                     int8_t *restrict dst, int height,
                                     int width, int channels) {
  const int out_h = height / 2;
  const int out_w = width / 2;
  const int row_stride = width * channels;
  for (int oh = 0; oh < out_h; ++oh) {
    const int8_t *row0 = src + (2 * oh) * row_stride;
    const int8_t *row1 = row0 + row_stride;
    int8_t *out = dst + oh * out_w * channels;
    for (int ow = 0; ow < out_w; ++ow) {
      const int8_t *p00 = row0 + (2 * ow) * channels;
      const int8_t *p01 = p00 + channels;
      const int8_t *p10 = row1 + (2 * ow) * channels;
      const int8_t *p11 = p10 + channels;
      rvv_max4_i8(p00, p01, p10, p11, out + ow * channels, channels);
    }
  }
}

void _mlir_ciface_buddy_maxpool_nhwc_2x2_s2_i8(int64_t dst_ptr, int64_t src_ptr,
                                               int64_t n, int64_t h, int64_t w,
                                               int64_t c) {
  enable_vector_state();
  int8_t *dst = (int8_t *)(uintptr_t)dst_ptr;
  const int8_t *src = (const int8_t *)(uintptr_t)src_ptr;
  const int64_t in_plane = h * w * c;
  const int64_t out_plane = (h / 2) * (w / 2) * c;
  for (int64_t ni = 0; ni < n; ++ni) {
    maxpool2x2_stride2_valid(src + ni * in_plane, dst + ni * out_plane, (int)h,
                             (int)w, (int)c);
  }
}

void buddy_maxpool_nhwc_2x2_s2_i8(int64_t dst_ptr, int64_t src_ptr, int64_t n,
                                  int64_t h, int64_t w, int64_t c) {
  _mlir_ciface_buddy_maxpool_nhwc_2x2_s2_i8(dst_ptr, src_ptr, n, h, w, c);
}
