#ifndef TEST_MMIO_H
#define TEST_MMIO_H

#include <stdint.h>

extern uint64_t test_cycle;

static inline uint64_t read_cycle(void)
{
    return ++test_cycle;
}

#endif
