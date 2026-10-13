#ifndef TEST_PPU_BACKEND_MMIO_H
#define TEST_PPU_BACKEND_MMIO_H
#include <stdint.h>
extern uint64_t test_cycle;
uint32_t mmio_read32(uintptr_t address);
void mmio_write32(uintptr_t address, uint32_t value);
void mmio_fence(void);
void test_wfi(void);
static inline uint64_t read_cycle(void) { return ++test_cycle; }
static inline void cpu_wfi(void) { test_wfi(); }
#if defined(YOLO32_PPU_ORDERED_MMIO) && YOLO32_PPU_ORDERED_MMIO
void yolo32_ppu_io_barrier(void);
#define mmio_fence yolo32_ppu_io_barrier
#endif
#endif
