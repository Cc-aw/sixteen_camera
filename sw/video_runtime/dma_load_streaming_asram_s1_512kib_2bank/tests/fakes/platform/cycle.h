#ifndef PLATFORM_CYCLE_H
#define PLATFORM_CYCLE_H
#include <stdint.h>
extern uint64_t mock_cycle;
static inline uint64_t platform_read_cycle(void){return ++mock_cycle;}
#endif
