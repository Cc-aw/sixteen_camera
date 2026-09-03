#include <stddef.h>
#include <stdint.h>
#include <stdarg.h>

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

int strcmp(const char *left, const char *right)
{
    while (*left != '\0' && *left == *right) {
        ++left;
        ++right;
    }
    return (unsigned char)*left - (unsigned char)*right;
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

/* newlib's libm uses this hook even in the freestanding image. */
int *__errno(void)
{
    static int error;
    return &error;
}

/* Minimal heap used by generated Gemmini code.  The model workspace wraps
 * allocations after initialization; these symbols cover setup-time libc
 * calls without requiring a full hosted libc/sbrk implementation. */
extern unsigned char _end[];
extern unsigned char __stack_bottom[];
static unsigned char *heap_cursor;

void *malloc(size_t bytes)
{
    if (heap_cursor == NULL)
        heap_cursor = _end;
    bytes = (bytes + 15U) & ~(size_t)15U;
    if (bytes == 0U || heap_cursor + bytes > __stack_bottom)
        return NULL;
    void *result = heap_cursor;
    heap_cursor += bytes;
    return result;
}

void free(void *ptr)
{
    (void)ptr;
}

int printf(const char *format, ...)
{
    (void)format;
    return 0;
}

__attribute__((noreturn)) void exit(int status)
{
    (void)status;
    for (;;) cpu_wfi();
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
