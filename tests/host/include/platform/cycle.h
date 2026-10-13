#ifndef TEST_PLATFORM_CYCLE_H
#define TEST_PLATFORM_CYCLE_H

#include "mmio.h"

static inline uint64_t platform_read_cycle(void)
{
    return read_cycle();
}

#endif
