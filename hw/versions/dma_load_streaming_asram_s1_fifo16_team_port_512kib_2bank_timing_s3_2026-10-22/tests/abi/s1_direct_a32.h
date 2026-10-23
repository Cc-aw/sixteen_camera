#ifndef S1_DIRECT_A32_H
#define S1_DIRECT_A32_H

#include <stdint.h>

/* Independent extension of the unchanged S1 DIM32/FP16 mathematical ABI.
 * CONFIG_LD rs1: type[1:0]=1, enable[2], state[4:3], marker[7],
 * source1 FP16 scale[47:32]. rs2 is a modulo-2^33 physical DMA delta.
 * Ordinary CONFIG_LD clears dual mode for its state. The ordinary stride,
 * source0 scale and block stride are configured before the descriptor.
 * One MVIN with cols=32 emits source0/source1 16-byte requests per row;
 * source1 occupies bytes 16..31. Both sources use the ordinary row stride.
 */
#define S1_DIRECT_A32_ABI_VERSION 1u
#define S1_DIRECT_A32_DMA_ADDRESS_BITS 33u
#define S1_DIRECT_A32_DMA_ADDRESS_MASK UINT64_C(0x1ffffffff)
#define S1_DIRECT_A32_DESCRIPTOR_MARKER UINT64_C(0x80)

static inline uint64_t s1_direct_a32_descriptor(uint16_t second_scale,
                                               unsigned state, unsigned enable) {
    return ((uint64_t)second_scale << 32) | S1_DIRECT_A32_DESCRIPTOR_MARKER |
        ((uint64_t)(state & 3u) << 3) | ((uint64_t)(enable & 1u) << 2) | 1u;
}

static inline uint64_t s1_direct_a32_dma_delta(uint64_t source0_dma,
                                             uint64_t source1_dma) {
    return (source1_dma - source0_dma) & S1_DIRECT_A32_DMA_ADDRESS_MASK;
}

#endif
