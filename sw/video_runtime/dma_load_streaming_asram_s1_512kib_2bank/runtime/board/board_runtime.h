#ifndef BOARD_RUNTIME_H
#define BOARD_RUNTIME_H

#include <stdint.h>

void board_uart_init(void);
void board_uart_putc(char value);
void board_uart_puts(const char *text);
void board_uart_puthex(uint64_t value);
void board_trap_report(uint64_t cause, uint64_t epc, uint64_t tval);

#endif
