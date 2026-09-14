/* I: even-sized NHWC RGB int8 image and separate output buffer.
 * P: gather each 2x2 pixel block into channels [top-left RGB, top-right RGB,
 * bottom-left RGB, bottom-right RGB], without numerical conversion.
 * O: NHWC H/2 x W/2 x 12 bytes. A: 王志瑞. T: 2026-09-11. */
#ifndef N6_M01_PACK_H
#define N6_M01_PACK_H
#include <stdint.h>
#include <stddef.h>
static void n6_m01_pack_scalar(const int8_t *src, int8_t *dst, size_t h, size_t w) {
  for(size_t y=0;y<h/2;y++) for(size_t x=0;x<w/2;x++)
    for(size_t dy=0;dy<2;dy++) for(size_t dx=0;dx<2;dx++) for(size_t c=0;c<3;c++)
      dst[(y*(w/2)+x)*12+(dy*2+dx)*3+c]=src[((2*y+dy)*w+2*x+dx)*3+c];
}
#if defined(__riscv_vector) && !defined(N6_M01_SCALAR_PACK)
/* I: non-overlapping RGB/packed buffers. P: RVV strided byte loads/stores;
 * vector tails preserve exactly the same channel order as scalar reference.
 * O: packed bytes, no UART. A: 王志瑞. T: 2026-09-11. */
static void n6_m01_pack(const int8_t *src,int8_t *dst,size_t h,size_t w) {
  for(size_t y=0;y<h/2;y++) for(size_t x=0;x<w/2;) {
    size_t vl,remaining=w/2-x;
    __asm__ volatile("vsetvli %0, %1, e8, m1, ta, ma" : "=r"(vl) : "r"(remaining));
    for(size_t dy=0;dy<2;dy++) for(size_t c=0;c<6;c++) {
      const int8_t *a=src+(2*y+dy)*w*3+x*6+c;
      int8_t *b=dst+(y*(w/2)+x)*12+dy*6+c;
      __asm__ volatile("vlse8.v v0, (%0), %2\n\tvsse8.v v0, (%1), %3"
        :: "r"(a),"r"(b),"r"((uintptr_t)6),"r"((uintptr_t)12) : "v0","memory");
    }
    x+=vl;
  }
}
#else
#define n6_m01_pack n6_m01_pack_scalar
#endif
#endif
