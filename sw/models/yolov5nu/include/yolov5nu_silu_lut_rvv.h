#ifndef YOLOV5NU_SILU_LUT_RVV_H
#define YOLOV5NU_SILU_LUT_RVV_H

#include <stdint.h>

#ifdef __riscv_vector
static inline void yolov5nu_silu_lut_rvv_e8m1(const int8_t *src, int8_t *dst,
    uintptr_t count, const int8_t lut[256]) {
  while (count) {
    uintptr_t vl;
    asm volatile(
      "vsetvli %[vl], %[n], e8, m1, ta, ma\n\t"
      "vle8.v v2, (%[src])\n\t"
      "vluxei8.v v4, (%[lut]), v2\n\t"
      "vse8.v v4, (%[dst])"
      : [vl] "=&r" (vl)
      : [n] "r" (count), [src] "r" (src), [dst] "r" (dst), [lut] "r" (lut)
      : "memory", "v2", "v4");
    src += vl;
    dst += vl;
    count -= vl;
  }
}

static inline void yolov5nu_silu_lut_rvv_e8m2(const int8_t *src, int8_t *dst,
    uintptr_t count, const int8_t lut[256]) {
  while (count) {
    uintptr_t vl;
    asm volatile(
      "vsetvli %[vl], %[n], e8, m2, ta, ma\n\t"
      "vle8.v v2, (%[src])\n\t"
      "vluxei8.v v4, (%[lut]), v2\n\t"
      "vse8.v v4, (%[dst])"
      : [vl] "=&r" (vl)
      : [n] "r" (count), [src] "r" (src), [dst] "r" (dst), [lut] "r" (lut)
      : "memory", "v2", "v3", "v4", "v5");
    src += vl;
    dst += vl;
    count -= vl;
  }
}
#endif

#endif
