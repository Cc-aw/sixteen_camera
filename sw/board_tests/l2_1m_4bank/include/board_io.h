#ifndef L2_BOARD_IO_H
#define L2_BOARD_IO_H
#include <stdint.h>
#include <stddef.h>
uint32_t board_read32(unsigned offset);
void board_write32(unsigned offset, uint32_t value);
uint64_t board_cycles(void);
void board_fence(void);
void board_text(const char *text);
void board_number(uint64_t value);
void board_field(const char *name, uint64_t value);
void board_fail(const char *reason, uint64_t value) __attribute__((noreturn));
int l2_smoke_run(void);
#endif
