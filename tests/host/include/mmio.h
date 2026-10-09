#ifndef TEST_MMIO_H
#define TEST_MMIO_H

#include <stdint.h>

extern uint64_t test_cycle;

static inline uint64_t read_cycle(void)
{
    return ++test_cycle;
}

#ifdef AI_STREAM_RUNTIME_HOST_TEST
uint32_t mmio_read32(uintptr_t address);
void mmio_write32(uintptr_t address, uint32_t value);
void mmio_fence(void);
#endif

#endif
