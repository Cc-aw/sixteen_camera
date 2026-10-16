#ifndef FIRST_LAYER_S2D_H
#define FIRST_LAYER_S2D_H
#include <stddef.h>
#include <stdint.h>

/* NHWC RGB -> NHWC [top-left RGB, top-right RGB, bottom-left RGB,
 * bottom-right RGB]. Buffers must not overlap; dimensions must be even. */
static int first_layer_s2d_scalar(const int8_t *src, int8_t *dst,
                                 size_t height, size_t width) {
    if (!src || !dst || !height || !width || (height & 1) || (width & 1)) return -1;
    for (size_t y = 0; y < height; y += 2)
        for (size_t x = 0; x < width; x += 2)
            for (size_t dy = 0; dy < 2; ++dy)
                for (size_t k = 0; k < 6; ++k)
                    *dst++ = src[((y + dy) * width + x) * 3 + k];
    return 0;
}

static __attribute__((noinline)) int first_layer_s2d_rvv(
        const int8_t *src, int8_t *dst, size_t height, size_t width) {
#ifdef __riscv
    if (!src || !dst || !height || !width || (height & 1) || (width & 1)) return -1;
    for (size_t y = 0; y < height; y += 2) {
        const int8_t *top = src + y * width * 3;
        const int8_t *bottom = top + width * 3;
        size_t pairs = width / 2;
        while (pairs) {
            size_t vl;
            /* Six byte fields form one pair of horizontal RGB pixels.
             * Strided segment stores interleave the two source rows. */
            __asm__ volatile(
                "vsetvli %0,%1,e8,m1,ta,ma\n"
                "vlseg6e8.v v0,(%2)\n"
                "vlseg6e8.v v6,(%3)\n"
                "vssseg6e8.v v0,(%4),%6\n"
                "vssseg6e8.v v6,(%5),%6\n"
                : "=&r"(vl)
                : "r"(pairs), "r"(top), "r"(bottom), "r"(dst), "r"(dst + 6), "r"((size_t)12)
                : "v0", "v1", "v2", "v3", "v4", "v5", "v6", "v7", "v8", "v9", "v10", "v11", "memory");
            top += vl * 6;
            bottom += vl * 6;
            dst += vl * 12;
            pairs -= vl;
        }
    }
    return 0;
#else
    return first_layer_s2d_scalar(src, dst, height, width);
#endif
}
#endif
