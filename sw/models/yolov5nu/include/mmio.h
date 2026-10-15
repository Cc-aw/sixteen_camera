#ifndef VIDEO_CTRL_MMIO_H
#define VIDEO_CTRL_MMIO_H
#include <stdint.h>
static inline void mmio_write32(uintptr_t addr, uint32_t value) {
    *(volatile uint32_t *)addr = value;
}
static inline uint32_t mmio_read32(uintptr_t addr) {
    return *(volatile uint32_t *)addr;
}
static inline void mmio_fence(void) {
#if defined(YOLO32_PPU_ORDERED_MMIO) && YOLO32_PPU_ORDERED_MMIO
    /* This override is compiled into the two PPU driver objects only. */
    extern void yolo32_ppu_io_barrier(void);
    yolo32_ppu_io_barrier();
#else
    __asm__ volatile("fence" ::: "memory");
#endif
}
static inline uint64_t read_cycle(void) {
    uint64_t value;
    __asm__ volatile("rdcycle %0" : "=r"(value));
    return value;
}
static inline void cpu_wfi(void) { __asm__ volatile("wfi"); }
#endif
