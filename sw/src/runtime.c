#include <stddef.h>
#include <stdint.h>

#include "console.h"
#include "mmio.h"
#include "platform.h"
#include "xil_types.h"

u32 Xil_AssertStatus;

void *memset(void *destination, int value, size_t count)
{
    unsigned char *out = destination;
    while (count-- != 0U)
        *out++ = (unsigned char)value;
    return destination;
}

void *memcpy(void *destination, const void *source, size_t count)
{
    unsigned char *out = destination;
    const unsigned char *in = source;
    while (count-- != 0U)
        *out++ = *in++;
    return destination;
}

int memcmp(const void *left, const void *right, size_t count)
{
    const unsigned char *a = left;
    const unsigned char *b = right;
    while (count-- != 0U) {
        if (*a != *b)
            return (int)*a - (int)*b;
        ++a;
        ++b;
    }
    return 0;
}

void usleep(unsigned long useconds)
{
    uint64_t cycles = (SOC_CLOCK_HZ * useconds) / UINT64_C(1000000);
    uint64_t until = read_cycle() + cycles;
    while ((int64_t)(read_cycle() - until) < 0) {
    }
}

void sleep(unsigned int seconds)
{
    while (seconds-- != 0U)
        usleep(1000000UL);
}

int xil_printf(const char *format, ...)
{
    (void)format;
    return 0;
}

__attribute__((noreturn))
void runtime_trap(uint64_t cause, uint64_t epc, uint64_t value)
{
    console_puts("\r\nFATAL TRAP mcause=");
    console_put_hex64(cause);
    console_puts(" mepc=");
    console_put_hex64(epc);
    console_puts(" mtval=");
    console_put_hex64(value);
    console_puts("\r\n");
    for (;;)
        cpu_wfi();
}
