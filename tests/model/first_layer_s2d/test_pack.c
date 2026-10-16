#include <stddef.h>
#include <stdint.h>
#include "first_layer_s2d.h"

enum { MAX_BYTES = 480 * 642 * 3, GUARD = 64 };
static int8_t input[MAX_BYTES + 2 * GUARD + 1], expected[MAX_BYTES + 2 * GUARD + 1], actual[MAX_BYTES + 2 * GUARD + 1];
int main(void) {
    const size_t heights[] = {2, 4, 18, 480}, widths[] = {2, 4, 14, 62, 64, 66, 640, 642};
    for (size_t n = 0; n < sizeof(input); ++n) input[n] = (int8_t)(n * 73 + n / 11);
    for (unsigned h = 0; h < sizeof(heights)/sizeof(*heights); ++h)
        for (unsigned w = 0; w < sizeof(widths)/sizeof(*widths); ++w)
            for (size_t alignment = 0; alignment < 2; ++alignment) {
                size_t bytes = heights[h] * widths[w] * 3;
                for (size_t n = 0; n < sizeof(actual); ++n) actual[n] = expected[n] = (int8_t)0xa5;
                if (first_layer_s2d_scalar(input + GUARD + alignment, expected + GUARD + alignment, heights[h], widths[w])) return 1;
                if (first_layer_s2d_rvv(input + GUARD + alignment, actual + GUARD + alignment, heights[h], widths[w])) return 2;
                for (size_t n = 0; n < bytes + 2 * GUARD + alignment; ++n) if (actual[n] != expected[n]) return 3;
            }
    if (first_layer_s2d_rvv(input, actual, 3, 2) != -1) return 4;
    if (first_layer_s2d_rvv(input, actual, 2, 3) != -1) return 5;
    if (first_layer_s2d_rvv(input, actual, 0, 2) != -1) return 6;
    if (first_layer_s2d_rvv(0, actual, 2, 2) != -1) return 7;
    return 0;
}
