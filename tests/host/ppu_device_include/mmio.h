#ifndef TEST_PPU_DEVICE_MMIO_H
#define TEST_PPU_DEVICE_MMIO_H
#include <stdint.h>
uint32_t mmio_read32(uintptr_t address);
void mmio_write32(uintptr_t address, uint32_t value);
void mmio_fence(void);
#if defined(YOLO32_PPU_ORDERED_MMIO) && YOLO32_PPU_ORDERED_MMIO
void yolo32_ppu_io_barrier(void);
#define mmio_fence yolo32_ppu_io_barrier
#endif
#endif
