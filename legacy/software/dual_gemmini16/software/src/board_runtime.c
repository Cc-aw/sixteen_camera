#include "board_runtime.h"

#define UART_BASE   ((uintptr_t)0x10020000UL)
#define UART_TXDATA (*(volatile uint32_t *)(UART_BASE + 0x00U))
#define UART_TXCTRL (*(volatile uint32_t *)(UART_BASE + 0x08U))
#define UART_DIV    (*(volatile uint32_t *)(UART_BASE + 0x18U))
#define UART_FULL   (UINT32_C(1) << 31)

void board_uart_init(void)
{
    UART_DIV = 868U; /* 100 MHz peripheral clock, 115200 baud. */
    UART_TXCTRL = 1U;
}

void board_uart_putc(char value)
{
    while ((UART_TXDATA & UART_FULL) != 0U) {
    }
    UART_TXDATA = (uint32_t)(unsigned char)value;
}

void board_uart_puts(const char *text)
{
    board_uart_init();
    while (*text != '\0') {
        if (*text == '\n')
            board_uart_putc('\r');
        board_uart_putc(*text++);
    }
}

void board_uart_puthex(uint64_t value)
{
    static const char digits[] = "0123456789abcdef";
    board_uart_puts("0x");
    for (int shift = 60; shift >= 0; shift -= 4)
        board_uart_putc(digits[(value >> shift) & 0xfU]);
}

void board_trap_report(uint64_t cause, uint64_t epc, uint64_t tval)
{
    board_uart_puts("\nTRAP cause=");
    board_uart_puthex(cause);
    board_uart_puts(" epc=");
    board_uart_puthex(epc);
    board_uart_puts(" tval=");
    board_uart_puthex(tval);
    board_uart_puts("\n");
    for (;;)
        __asm__ volatile("wfi");
}
