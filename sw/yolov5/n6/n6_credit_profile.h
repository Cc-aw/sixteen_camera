/* I: LoopConv admission hook, included before gemmini.h.
 * P: accumulate admitted calls and time spent waiting for credit, without UART.
 * O: per-group snapshot deltas. A: 王志瑞. T: 2026-09-10. */
#ifndef N6_CREDIT_PROFILE_H
#define N6_CREDIT_PROFILE_H
#include <stdint.h>
static uint64_t n6_credit_calls, n6_credit_waits, n6_credit_cycles;
static inline void n6_credit_sample(uint64_t cycles) {
  n6_credit_calls++;
  n6_credit_waits += cycles != 0;
  n6_credit_cycles += cycles;
}
#define GEMMINI_LOOPCONV_CREDIT_WAIT_HOOK(cycles) n6_credit_sample(cycles)
#endif
