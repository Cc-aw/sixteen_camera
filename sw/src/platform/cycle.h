#ifndef PLATFORM_CYCLE_H
#define PLATFORM_CYCLE_H

#include <stdint.h>

/* Clock-only interface for software policy; same rdcycle primitive as MMIO. */
static inline uint64_t platform_read_cycle(void)
{
    uint64_t value;
    __asm__ volatile("rdcycle %0" : "=r"(value));
    return value;
}

#endif
