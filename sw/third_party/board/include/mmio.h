#ifndef VIDEO_CTRL_MMIO_H
#define VIDEO_CTRL_MMIO_H

#include <stdint.h>
#include <stddef.h>

static inline void mmio_write32(uintptr_t address, uint32_t value)
{
    *(volatile uint32_t *)address = value;
}

static inline uint32_t mmio_read32(uintptr_t address)
{
    return *(volatile const uint32_t *)address;
}

static inline void mmio_fence(void)
{
    __asm__ volatile ("fence iorw, iorw" ::: "memory");
}

static inline uint64_t read_cycle(void)
{
    uint64_t value;
    __asm__ volatile ("rdcycle %0" : "=r"(value));
    return value;
}

static inline void cpu_wfi(void)
{
    __asm__ volatile ("wfi");
}

#endif
