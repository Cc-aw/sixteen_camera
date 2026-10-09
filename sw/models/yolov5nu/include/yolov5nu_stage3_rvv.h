#ifndef YOLOV5NU_STAGE3_RVV_H
#define YOLOV5NU_STAGE3_RVV_H

#include <stdint.h>

#ifdef __riscv_vector
static inline void yolov5nu_rvv_copy_i8(const int8_t *src, int8_t *dst,
    uintptr_t count) {
  while (count) {
    uintptr_t vl;
    asm volatile(
      "vsetvli %[vl], %[n], e8, m8, ta, ma\n\t"
      "vle8.v v0, (%[src])\n\t"
      "vse8.v v0, (%[dst])"
      : [vl] "=&r" (vl)
      : [n] "r" (count), [src] "r" (src), [dst] "r" (dst)
      : "memory", "v0", "v1", "v2", "v3", "v4", "v5", "v6", "v7");
    src += vl;
    dst += vl;
    count -= vl;
  }
}

static inline void yolov5nu_rvv_requant_i8(const int8_t *src, int8_t *dst,
    uintptr_t count, float ratio) {
  asm volatile("csrwi frm, 0" ::: "memory");
  while (count) {
    uintptr_t vl;
    asm volatile(
      "vsetvli %[vl], %[n], e8, m1, ta, ma\n\t"
      "vle8.v v1, (%[src])\n\t"
      "vsetvli zero, %[vl], e16, m2, ta, ma\n\t"
      "vsext.vf2 v2, v1\n\t"
      "vsetvli zero, %[vl], e32, m4, ta, ma\n\t"
      "vsext.vf2 v4, v2\n\t"
      "vfcvt.f.x.v v4, v4\n\t"
      "vfmul.vf v4, v4, %[ratio]\n\t"
      "vfcvt.x.f.v v4, v4\n\t"
      "vsetvli zero, %[vl], e16, m2, ta, ma\n\t"
      "vnclip.wi v8, v4, 0\n\t"
      "vsetvli zero, %[vl], e8, m1, ta, ma\n\t"
      "vnclip.wi v10, v8, 0\n\t"
      "vse8.v v10, (%[dst])"
      : [vl] "=&r" (vl)
      : [n] "r" (count), [src] "r" (src), [dst] "r" (dst),
        [ratio] "f" (ratio)
      : "memory", "v1", "v2", "v3", "v4", "v5", "v6", "v7", "v8",
        "v9", "v10");
    src += vl;
    dst += vl;
    count -= vl;
  }
}

static inline void yolov5nu_rvv_concat_slice_i8(const int8_t *src,
    int8_t *dst, uintptr_t count, float ratio) {
  if (ratio == 1.0f) {
    yolov5nu_rvv_copy_i8(src, dst, count);
    return;
  }
  asm volatile("csrwi frm, 0" ::: "memory");
  while (count) {
    uintptr_t vl;
    asm volatile(
      "vsetvli %[vl], %[n], e8, m2, ta, ma\n\t"
      "vle8.v v2, (%[src])\n\t"
      "vsetvli zero, %[vl], e16, m4, ta, ma\n\t"
      "vsext.vf2 v4, v2\n\t"
      "vsetvli zero, %[vl], e32, m8, ta, ma\n\t"
      "vsext.vf2 v8, v4\n\t"
      "vfcvt.f.x.v v8, v8\n\t"
      "vfmul.vf v8, v8, %[ratio]\n\t"
      "vfcvt.x.f.v v8, v8\n\t"
      "vsetvli zero, %[vl], e16, m4, ta, ma\n\t"
      "vnclip.wi v16, v8, 0\n\t"
      "vsetvli zero, %[vl], e8, m2, ta, ma\n\t"
      "vnclip.wi v20, v16, 0\n\t"
      "vse8.v v20, (%[dst])"
      : [vl] "=&r" (vl)
      : [n] "r" (count), [src] "r" (src), [dst] "r" (dst),
        [ratio] "f" (ratio)
      : "memory", "v2", "v3", "v4", "v5", "v6", "v7", "v8",
        "v9", "v10", "v11", "v12", "v13", "v14", "v15", "v16",
        "v17", "v18", "v19", "v20", "v21");
    src += vl;
    dst += vl;
    count -= vl;
  }
}

static inline void yolov5nu_rvv_concat_nhwc_slice_i8(const int8_t *src,
    int8_t *dst, uintptr_t positions, uintptr_t channels,
    uintptr_t dst_stride, float ratio) {
  for (uintptr_t position = 0; position < positions; position++) {
    yolov5nu_rvv_concat_slice_i8(src, dst, channels, ratio);
    src += channels;
    dst += dst_stride;
  }
}

static inline void yolov5nu_rvv_add_i8(const int8_t *a, const int8_t *b,
    int8_t *dst, uintptr_t count, float a_scale, float b_scale,
    float dst_scale) {
  asm volatile("csrwi frm, 0" ::: "memory");
  while (count) {
    uintptr_t vl;
    asm volatile(
      "vsetvli %[vl], %[n], e8, m1, ta, ma\n\t"
      "vle8.v v1, (%[a])\n\t"
      "vle8.v v8, (%[b])\n\t"
      "vsetvli zero, %[vl], e16, m2, ta, ma\n\t"
      "vsext.vf2 v2, v1\n\t"
      "vsext.vf2 v10, v8\n\t"
      "vsetvli zero, %[vl], e32, m4, ta, ma\n\t"
      "vsext.vf2 v4, v2\n\t"
      "vsext.vf2 v12, v10\n\t"
      "vfcvt.f.x.v v4, v4\n\t"
      "vfcvt.f.x.v v12, v12\n\t"
      "vfmul.vf v4, v4, %[as]\n\t"
      "vfmul.vf v12, v12, %[bs]\n\t"
      "vfadd.vv v4, v4, v12\n\t"
      "vfdiv.vf v4, v4, %[ds]\n\t"
      "vfcvt.x.f.v v4, v4\n\t"
      "vsetvli zero, %[vl], e16, m2, ta, ma\n\t"
      "vnclip.wi v16, v4, 0\n\t"
      "vsetvli zero, %[vl], e8, m1, ta, ma\n\t"
      "vnclip.wi v18, v16, 0\n\t"
      "vse8.v v18, (%[dst])"
      : [vl] "=&r" (vl)
      : [n] "r" (count), [a] "r" (a), [b] "r" (b), [dst] "r" (dst),
        [as] "f" (a_scale), [bs] "f" (b_scale), [ds] "f" (dst_scale)
      : "memory", "v1", "v2", "v3", "v4", "v5", "v6", "v7", "v8",
        "v9", "v10", "v11", "v12", "v13", "v14", "v15", "v16",
        "v17", "v18");
    a += vl;
    b += vl;
    dst += vl;
    count -= vl;
  }
}

static inline void yolov5nu_rvv_maxpool_nhwc_i8(const int8_t *src,
    int8_t *dst, int n, int c, int ih, int iw, int oh, int ow, int kh,
    int kw, int sh, int sw, int ph, int pw) {
  for (int bn = 0; bn < n; bn++) {
    for (int oy = 0; oy < oh; oy++) {
      for (int ox = 0; ox < ow; ox++) {
        int first_y = -1;
        int first_x = -1;
        for (int ky = 0; ky < kh && first_y < 0; ky++) {
          int iy = oy * sh + ky - ph;
          if (iy < 0 || iy >= ih) continue;
          for (int kx = 0; kx < kw; kx++) {
            int ix = ox * sw + kx - pw;
            if (ix >= 0 && ix < iw) {
              first_y = iy;
              first_x = ix;
              break;
            }
          }
        }
        uintptr_t offset = 0;
        uintptr_t remaining = (uintptr_t)c;
        while (remaining) {
          uintptr_t vl;
          const int8_t *first = src +
            ((bn * ih + first_y) * iw + first_x) * c + offset;
          asm volatile(
            "vsetvli %[vl], %[n], e8, m8, ta, ma\n\t"
            "vle8.v v0, (%[first])"
            : [vl] "=&r" (vl)
            : [n] "r" (remaining), [first] "r" (first)
            : "memory", "v0", "v1", "v2", "v3", "v4", "v5", "v6", "v7");
          for (int ky = 0; ky < kh; ky++) {
            int iy = oy * sh + ky - ph;
            if (iy < 0 || iy >= ih) continue;
            for (int kx = 0; kx < kw; kx++) {
              int ix = ox * sw + kx - pw;
              if (ix < 0 || ix >= iw || (iy == first_y && ix == first_x)) continue;
              const int8_t *value = src + ((bn * ih + iy) * iw + ix) * c + offset;
              asm volatile(
                "vle8.v v8, (%[value])\n\t"
                "vmax.vv v0, v0, v8"
                :: [value] "r" (value)
                : "memory", "v0", "v1", "v2", "v3", "v4", "v5", "v6", "v7",
                  "v8", "v9", "v10", "v11", "v12", "v13", "v14", "v15");
            }
          }
          int8_t *output = dst + ((bn * oh + oy) * ow + ox) * c + offset;
          asm volatile(
            "vse8.v v0, (%[output])"
            :: [output] "r" (output)
            : "memory", "v0", "v1", "v2", "v3", "v4", "v5", "v6", "v7");
          offset += vl;
          remaining -= vl;
        }
      }
    }
  }
}

static inline void yolov5nu_rvv_maxpool_nhwc_i8_strided(const int8_t *src,
    int8_t *dst, int n, int c, int ih, int iw, int oh, int ow, int kh,
    int kw, int sh, int sw, int ph, int pw, int dst_stride) {
  for (int bn = 0; bn < n; bn++) {
    for (int oy = 0; oy < oh; oy++) {
      for (int ox = 0; ox < ow; ox++) {
        int first_y = -1;
        int first_x = -1;
        for (int ky = 0; ky < kh && first_y < 0; ky++) {
          int iy = oy * sh + ky - ph;
          if (iy < 0 || iy >= ih) continue;
          for (int kx = 0; kx < kw; kx++) {
            int ix = ox * sw + kx - pw;
            if (ix >= 0 && ix < iw) {
              first_y = iy;
              first_x = ix;
              break;
            }
          }
        }
        uintptr_t offset = 0;
        uintptr_t remaining = (uintptr_t)c;
        while (remaining) {
          uintptr_t vl;
          const int8_t *first = src +
            ((bn * ih + first_y) * iw + first_x) * c + offset;
          asm volatile(
            "vsetvli %[vl], %[n], e8, m8, ta, ma\n\t"
            "vle8.v v0, (%[first])"
            : [vl] "=&r" (vl)
            : [n] "r" (remaining), [first] "r" (first)
            : "memory", "v0", "v1", "v2", "v3", "v4", "v5", "v6", "v7");
          for (int ky = 0; ky < kh; ky++) {
            int iy = oy * sh + ky - ph;
            if (iy < 0 || iy >= ih) continue;
            for (int kx = 0; kx < kw; kx++) {
              int ix = ox * sw + kx - pw;
              if (ix < 0 || ix >= iw || (iy == first_y && ix == first_x)) continue;
              const int8_t *value = src + ((bn * ih + iy) * iw + ix) * c + offset;
              asm volatile(
                "vle8.v v8, (%[value])\n\t"
                "vmax.vv v0, v0, v8"
                :: [value] "r" (value)
                : "memory", "v0", "v1", "v2", "v3", "v4", "v5", "v6", "v7",
                  "v8", "v9", "v10", "v11", "v12", "v13", "v14", "v15");
            }
          }
          int8_t *output = dst + ((bn * oh + oy) * ow + ox) * dst_stride + offset;
          asm volatile(
            "vse8.v v0, (%[output])"
            :: [output] "r" (output)
            : "memory", "v0", "v1", "v2", "v3", "v4", "v5", "v6", "v7");
          offset += vl;
          remaining -= vl;
        }
      }
    }
  }
}

static inline void yolov5nu_rvv_resize_nearest_nhwc_i8(const int8_t *src,
    int8_t *dst, int n, int c, int ih, int iw, int oh, int ow) {
  for (int bn = 0; bn < n; bn++) {
    for (int oy = 0; oy < oh; oy++) {
      int iy = (oy * ih) / oh;
      for (int ox = 0; ox < ow; ox++) {
        int ix = (ox * iw) / ow;
        const int8_t *input = src + ((bn * ih + iy) * iw + ix) * c;
        int8_t *output = dst + ((bn * oh + oy) * ow + ox) * c;
        yolov5nu_rvv_copy_i8(input, output, (uintptr_t)c);
      }
    }
  }
}

static inline void yolov5nu_rvv_resize_nearest_nhwc_i8_strided(const int8_t *src,
    int8_t *dst, int n, int c, int ih, int iw, int oh, int ow, int dst_stride) {
  for (int bn = 0; bn < n; bn++) {
    for (int oy = 0; oy < oh; oy++) {
      int iy = (oy * ih) / oh;
      for (int ox = 0; ox < ow; ox++) {
        int ix = (ox * iw) / ow;
        const int8_t *input = src + ((bn * ih + iy) * iw + ix) * c;
        int8_t *output = dst + ((bn * oh + oy) * ow + ox) * dst_stride;
        yolov5nu_rvv_copy_i8(input, output, (uintptr_t)c);
      }
    }
  }
}
#endif

#endif
