#ifndef S1_TEST_MMIO_H
#define S1_TEST_MMIO_H
#include <stdint.h>
#include <stddef.h>
extern uint64_t test_cycle;
extern uint64_t test_cycle_step;
uint32_t mmio_read32(uintptr_t address);
void mmio_write32(uintptr_t address,uint32_t value);
static inline uint64_t read_cycle(void){uint64_t value=test_cycle;test_cycle+=test_cycle_step;return value;}
static inline void mmio_fence(void){}
#endif
