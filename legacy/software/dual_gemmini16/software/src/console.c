#include "console.h"

#include "mmio.h"
#include "platform.h"

#define UART_TXDATA UINT32_C(0x00)
#define UART_RXDATA UINT32_C(0x04)
#define UART_TXCTRL UINT32_C(0x08)
#define UART_RXCTRL UINT32_C(0x0C)
#define UART_IE     UINT32_C(0x10)
#define UART_DIV    UINT32_C(0x18)
#define UART_FULL   (UINT32_C(1) << 31)
#define UART_EMPTY  (UINT32_C(1) << 31)

void console_init(void)
{
    mmio_write32(UART_BASE + UART_IE, 0U);
    mmio_write32(UART_BASE + UART_DIV,
                 (uint32_t)(SOC_CLOCK_HZ / UART_BAUD) - 1U);
    mmio_write32(UART_BASE + UART_TXCTRL, 1U);
    mmio_write32(UART_BASE + UART_RXCTRL, 1U);
    mmio_fence();

    for (unsigned count = 0U; count < 256U; ++count) {
        if ((mmio_read32(UART_BASE + UART_RXDATA) & UART_EMPTY) != 0U)
            break;
    }
}

void console_putc(char value)
{
    while ((mmio_read32(UART_BASE + UART_TXDATA) & UART_FULL) != 0U) {
    }
    mmio_write32(UART_BASE + UART_TXDATA, (uint8_t)value);
}

void console_puts(const char *text)
{
    while (*text != '\0')
        console_putc(*text++);
}

static void console_put_nibble(uint32_t value)
{
    value &= UINT32_C(0xF);
    console_putc((char)((value < 10U) ? ('0' + value) :
                                      ('A' + value - 10U)));
}

void console_put_hex32(uint32_t value)
{
    console_puts("0x");
    for (int shift = 28; shift >= 0; shift -= 4)
        console_put_nibble(value >> (unsigned)shift);
}

void console_put_hex64(uint64_t value)
{
    console_puts("0x");
    for (int shift = 60; shift >= 0; shift -= 4)
        console_put_nibble((uint32_t)(value >> (unsigned)shift));
}

void console_put_u32(uint32_t value)
{
    char buffer[10];
    unsigned count = 0U;

    if (value == 0U) {
        console_putc('0');
        return;
    }
    while (value != 0U) {
        buffer[count++] = (char)('0' + value % 10U);
        value /= 10U;
    }
    while (count != 0U)
        console_putc(buffer[--count]);
}

int console_getc_nonblock(void)
{
    uint32_t value = mmio_read32(UART_BASE + UART_RXDATA);
    return ((value & UART_EMPTY) != 0U) ? -1 : (int)(value & 0xFFU);
}
