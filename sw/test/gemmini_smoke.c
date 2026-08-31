#include <stdint.h>

static inline void gemmini_cmd(uint64_t a, uint64_t b, int f)
{
    switch (f) {
    case 0: __asm__ volatile(".insn r CUSTOM_3, 0x3, 0, x0, %0, %1" :: "r"(a), "r"(b)); break;
    case 2: __asm__ volatile(".insn r CUSTOM_3, 0x3, 2, x0, %0, %1" :: "r"(a), "r"(b)); break;
    case 3: __asm__ volatile(".insn r CUSTOM_3, 0x3, 3, x0, %0, %1" :: "r"(a), "r"(b)); break;
    }
}

#define UART_BASE 0x10020000UL
#define UART_TXDATA (*(volatile uint32_t *)(UART_BASE + 0x00))
#define UART_TXCTRL (*(volatile uint32_t *)(UART_BASE + 0x08))
#define UART_DIV    (*(volatile uint32_t *)(UART_BASE + 0x18))
#define UART_FULL   (1u << 31)

static void putc_uart(char c)
{
    while (UART_TXDATA & UART_FULL) {}
    UART_TXDATA = (uint32_t)(unsigned char)c;
}

static void puts_uart(const char *s)
{
    UART_DIV = 868u;
    UART_TXCTRL = 1u;
    while (*s) {
        if (*s == '\n') putc_uart('\r');
        putc_uart(*s++);
    }
}

static uint8_t src[256] __attribute__((aligned(64)));
static uint8_t weights[256] __attribute__((aligned(64)));
static uint8_t dst[256] __attribute__((aligned(64)));

void runtime_trap(uint64_t cause, uint64_t epc, uint64_t value)
{
    (void)cause; (void)epc; (void)value;
    puts_uart("GEMMINI TEST TRAP\n");
    for (;;) __asm__ volatile("wfi");
}

int main(void)
{
    puts_uart("GEMMINI TEST BOOT\n");
    puts_uart("CONFIG START\n");
    gemmini_cmd(0, 0, 0);
    puts_uart("CONFIG DONE\n");

    puts_uart("MVIN START\n");
    gemmini_cmd((uint64_t)src, (UINT64_C(16) << 32) | (UINT64_C(16) << 16), 2);
    __asm__ volatile("fence");
    puts_uart("MVIN DONE\n");

    puts_uart("WEIGHT MVIN START\n");
    gemmini_cmd((uint64_t)weights, (UINT64_C(16) << 32) | (UINT64_C(16) << 16) | 256U, 2);
    __asm__ volatile("fence");
    puts_uart("WEIGHT MVIN DONE\n");
    puts_uart("PRELOAD START\n");
    gemmini_cmd(256U, 0U, 6);
    puts_uart("PRELOAD DONE\n");
    puts_uart("COMPUTE START\n");
    gemmini_cmd(0U, 256U, 4);
    puts_uart("COMPUTE DONE\n");
    puts_uart("MVOUT START\n");
    gemmini_cmd((uint64_t)dst, (UINT64_C(16) << 32) | (UINT64_C(16) << 16), 3);
    __asm__ volatile("fence");
    puts_uart("MVOUT DONE\n");
    puts_uart("GEMMINI TEST PASS\n");
    for (;;) __asm__ volatile("wfi");
}
