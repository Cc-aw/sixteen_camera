#include "platform/cache_ops.h"

#include <stdint.h>

#include "mmio.h"

#if defined(YOLO32_PPU_ORDERED_MMIO) && YOLO32_PPU_ORDERED_MMIO
#error "Cache operations require ordinary fences, not the PPU readback override"
#endif

const AiCacheCapabilities *cache_capabilities(void)
{
    static const AiCacheCapabilities capabilities = {
        .cpu_alias_mask = AI_CACHE_CPU_ALIAS_MASK,
        .flush64_address = AI_CACHE_FLUSH64_ADDRESS,
        .line_bytes = AI_CACHE_LINE_BYTES,
        .accelerator_completion = AI_CACHE_ACCELERATOR_NATIVE_MODEL_COMPLETION,
        .cpu_fence = AI_CACHE_CPU_FENCE_IORW,
#if defined(YOLO32_LIVE) && YOLO32_LIVE
        .tensor_visibility = AI_CACHE_TENSOR_L2_COHERENT_AFTER_B,
        .ppu_ordering = AI_CACHE_PPU_ORDERED_READBACK
#else
        .tensor_visibility = AI_CACHE_TENSOR_LEGACY_READY_PROTOCOL,
        .ppu_ordering = AI_CACHE_PPU_GLOBAL_FENCE
#endif
    };
    return &capabilities;
}

void cache_cpu_fence(void)
{
    mmio_fence();
}

static void cache_flush_line(uintptr_t address)
{
    cache_cpu_fence();
    *(volatile uint64_t *)AI_CACHE_FLUSH64_ADDRESS =
        (uint64_t)(address & ~(uintptr_t)(AI_CACHE_LINE_BYTES - 1U));
    cache_cpu_fence();
}

void cache_flush_range(const void *base, size_t bytes)
{
    uintptr_t first = (uintptr_t)base & ~(uintptr_t)(AI_CACHE_LINE_BYTES - 1U);
    uintptr_t end = ((uintptr_t)base + bytes + AI_CACHE_LINE_BYTES - 1U) &
                    ~(uintptr_t)(AI_CACHE_LINE_BYTES - 1U);

    for (uintptr_t address = first; address < end; address += AI_CACHE_LINE_BYTES)
        cache_flush_line(address);
}
