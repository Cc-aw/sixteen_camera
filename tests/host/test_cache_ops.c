#define _GNU_SOURCE
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <sys/mman.h>
#include "platform/platform.h"
#include "platform/cache_ops.h"

static uint64_t fence_count;
_Static_assert(AI_DDR_CPU_ALIAS(UINT32_C(0x32000000)) == UINT32_C(0xb2000000),
               "The legacy CPU alias macro must remain a constant expression");
void mmio_fence(void)
{
    uint64_t value = *(volatile uint64_t *)UINT64_C(0x02010200);
    printf("F sample=%016llx\n", (unsigned long long)value); ++fence_count;
}
static void flush_case(uintptr_t address, size_t bytes, unsigned lines)
{
    *(volatile uint64_t *)UINT64_C(0x02010200) = UINT64_C(0xfedcba9876543210);
    fence_count = 0;
    printf("CASE address=%016llx bytes=%zu\n", (unsigned long long)address, bytes);
    cache_flush_range((const void *)address, bytes);
    assert(fence_count == 2 * lines);
    uint64_t value = *(volatile uint64_t *)UINT64_C(0x02010200);
    assert(value == (lines ? ((address & ~(uintptr_t)63) + (lines - 1) * 64) : UINT64_C(0xfedcba9876543210)));
}
int main(void)
{
    void *mapped = mmap((void *)(uintptr_t)UINT64_C(0x02010000), 4096, PROT_READ | PROT_WRITE,
                         MAP_PRIVATE | MAP_ANONYMOUS | MAP_FIXED_NOREPLACE, -1, 0);
    assert(mapped == (void *)(uintptr_t)UINT64_C(0x02010000));
    flush_case(0xb2000000, 0, 0);
    flush_case(0xb2000001, 0, 1); /* Preserve legacy unaligned zero-length behavior. */
    flush_case(0xb2000000, 1, 1);
    flush_case(0xb200003f, 1, 1);
    flush_case(0xb200003f, 2, 2);
    flush_case(0xb2000000, 64, 1);
    flush_case(0xb2000001, 64, 2);
    flush_case(0xb2000000, 128, 2);
    flush_case(0x32000000, 128, 2); /* Do not add/remove alias bits in flush. */
    flush_case(UINT64_C(0x1234567832000000), 129, 3);
    flush_case(UINTPTR_MAX - 31, 16, 0); /* Original unsigned wrap produces no writes. */
    static const uintptr_t addresses[] = {0, 0x30000000, 0x31000000, 0x32000000,
        0xb2000000, UINT64_C(0x1234567832000000), UINTPTR_MAX};
    for (unsigned i = 0; i < sizeof(addresses) / sizeof(addresses[0]); ++i) {
        uintptr_t expected = addresses[i] | UINT32_C(0x80000000);
        assert(AI_DDR_CPU_ALIAS(addresses[i]) == expected);
        assert(cache_cpu_ddr_alias(addresses[i]) == expected);
    }
    assert(munmap(mapped, 4096) == 0);
#ifdef R1C_CURRENT
    const AiCacheCapabilities *c = cache_capabilities();
    assert(c->cpu_alias_mask == 0x80000000 && c->flush64_address == 0x02010200 && c->line_bytes == 64);
    assert(c->accelerator_completion == AI_CACHE_ACCELERATOR_NATIVE_MODEL_COMPLETION);
#if YOLO32_LIVE
    assert(c->ppu_ordering == AI_CACHE_PPU_ORDERED_READBACK && c->cpu_fence == AI_CACHE_CPU_FENCE_IORW);
    assert(c->tensor_visibility == AI_CACHE_TENSOR_L2_COHERENT_AFTER_B);
#else
    assert(c->ppu_ordering == AI_CACHE_PPU_GLOBAL_FENCE && c->cpu_fence == AI_CACHE_CPU_FENCE_IORW);
    assert(c->tensor_visibility == AI_CACHE_TENSOR_LEGACY_READY_PROTOCOL);
#endif
#endif
    puts("CACHE_WORKLOAD=PASS flush_cases=11 alias_cases=7 store64_two_fences_per_line zero_length_wrap_preserved");
    return 0;
}
