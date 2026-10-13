/* Frozen R1b source: 0eb072a:sw/src/platform/cache_ops.c
 * Original SHA256: 77caa17b69854271dfbced076bfe702c98ae38a379de6367d907d5d29faaa52d
 */
#include "platform/cache_ops.h"

#include <stdint.h>

#include "mmio.h"

#define TAIHANG_L2_FLUSH64 ((uintptr_t)UINT64_C(0x02010200))

static void cache_flush_line(uintptr_t address)
{
    mmio_fence();
    *(volatile uint64_t *)TAIHANG_L2_FLUSH64 =
        (uint64_t)(address & ~(uintptr_t)63U);
    mmio_fence();
}

void cache_flush_range(const void *base, size_t bytes)
{
    uintptr_t first = (uintptr_t)base & ~(uintptr_t)63U;
    uintptr_t end = ((uintptr_t)base + bytes + 63U) & ~(uintptr_t)63U;

    for (uintptr_t address = first; address < end; address += 64U)
        cache_flush_line(address);
}
