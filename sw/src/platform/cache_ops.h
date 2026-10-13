#ifndef CACHE_OPS_H
#define CACHE_OPS_H

#include <stddef.h>
#include <stdint.h>

#define AI_CACHE_CPU_ALIAS_MASK UINT32_C(0x80000000)
#define AI_CACHE_LINE_BYTES 64U
#define AI_CACHE_FLUSH64_ADDRESS ((uintptr_t)UINT64_C(0x02010200))

typedef enum {
    AI_CACHE_TENSOR_LEGACY_READY_PROTOCOL,
    AI_CACHE_TENSOR_L2_COHERENT_AFTER_B
} AiCacheTensorVisibility;

typedef enum {
    AI_CACHE_PPU_GLOBAL_FENCE,
    AI_CACHE_PPU_ORDERED_READBACK
} AiCachePpuOrdering;

typedef enum {
    AI_CACHE_CPU_FENCE_IORW
} AiCacheCpuFence;

typedef enum {
    AI_CACHE_ACCELERATOR_NATIVE_MODEL_COMPLETION
} AiCacheAcceleratorCompletion;

typedef struct {
    uintptr_t cpu_alias_mask;
    uintptr_t flush64_address;
    uint32_t line_bytes;
    AiCacheTensorVisibility tensor_visibility;
    AiCachePpuOrdering ppu_ordering;
    AiCacheCpuFence cpu_fence;
    AiCacheAcceleratorCompletion accelerator_completion;
} AiCacheCapabilities;

/* Selected video build's existing protocols, not a unified DMA sync API.
 * V3 READY proves L2 visibility after B, not DDR writeback. Neither a CPU
 * fence nor PPU readback proves RoCC/DMA stopped: accepted/retired and local
 * Head completion remain model-owned protocols. */
const AiCacheCapabilities *cache_capabilities(void);

static inline uintptr_t cache_cpu_ddr_alias(uintptr_t address)
{
    return address | AI_CACHE_CPU_ALIAS_MASK;
}

static inline void cache_compiler_barrier(void)
{
    __asm__ volatile("" ::: "memory");
}

/* Ordinary CPU/IO fence (the bare "fence" spelling also encodes iorw,iorw),
 * never the PPU readback override. Model completion is a separate protocol. */
void cache_cpu_fence(void);

/* Legacy covering-line operation, including unaligned zero-length behavior.
 * Callers supply the CPU alias; the operation preserves its address bits. */
void cache_flush_range(const void *base, size_t bytes);

#endif
