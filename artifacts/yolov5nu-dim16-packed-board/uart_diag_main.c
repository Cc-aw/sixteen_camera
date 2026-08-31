#include <stdint.h>

/* Link with --wrap=main for BOARD=1 diagnostics.  This keeps the generated
 * model sources untouched while proving that the CPU reaches main and that
 * the UART MMIO path is alive before the long model run. */
extern int __real_main(void);

#define UART_BASE   0x10020000UL
#define UART_TXDATA (*(volatile uint32_t *)(UART_BASE + 0x00))
#define UART_TXCTRL (*(volatile uint32_t *)(UART_BASE + 0x08))
#define UART_DIV    (*(volatile uint32_t *)(UART_BASE + 0x18))
#define UART_FULL   (UINT32_C(1) << 31)

static void diag_putc(char c)
{
    while ((UART_TXDATA & UART_FULL) != 0U) {
    }
    UART_TXDATA = (uint32_t)(unsigned char)c;
}

static void diag_puts(const char *s)
{
    UART_DIV = 868U;
    UART_TXCTRL = 1U;
    while (*s != '\0') {
        if (*s == '\n')
            diag_putc('\r');
        diag_putc(*s++);
    }
}

int __wrap_main(void)
{
    diag_puts("AI BOOT: main reached\n");
    diag_puts("AI BOOT: entering model init/forward\n");
    int rc = __real_main();
    diag_puts("AI BOOT: main returned\n");
    return rc;
}
