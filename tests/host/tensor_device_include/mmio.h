#ifndef TEST_TENSOR_DEVICE_MMIO_H
#define TEST_TENSOR_DEVICE_MMIO_H
#include <stdint.h>
uint32_t mmio_read32(uintptr_t address);
void mmio_write32(uintptr_t address, uint32_t value);
void mmio_fence(void);
uint64_t read_cycle(void);
#endif
