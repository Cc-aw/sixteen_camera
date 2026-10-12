#include <stddef.h>
#include <stdarg.h>
#include "yolo32.h"
#include "console.h"
#include "mmio.h"

void *memset(void *dest, int value, size_t count) {
    unsigned char *p = dest;
    while (count--) *p++ = (unsigned char)value;
    return dest;
}
void *memcpy(void *dest, const void *src, size_t count) {
    unsigned char *p = dest;
    const unsigned char *q = src;
    while (count--) *p++ = *q++;
    return dest;
}
int memcmp(const void *left, const void *right, size_t count) {
    const unsigned char *a = left, *b = right;
    while (count--) {
        if (*a != *b) return (int)*a - (int)*b;
        ++a; ++b;
    }
    return 0;
}
int *__errno(void) { static int error; return &error; }
int abs(int value) { return value < 0 ? -value : value; }

extern unsigned char _end[], __stack_bottom[];
static uintptr_t heap_cursor;
void *malloc(size_t bytes) {
    if (!heap_cursor) heap_cursor = (uintptr_t)_end;
    if (bytes == 0 || bytes > (size_t)-1 - 15U) return NULL;
    bytes = (bytes + 15U) & ~(size_t)15U;
    if (heap_cursor > (uintptr_t)__stack_bottom ||
        bytes > (uintptr_t)__stack_bottom - heap_cursor) return NULL;
    void *out = (void *)heap_cursor;
    heap_cursor += bytes;
    return out;
}
void free(void *ptr) { (void)ptr; }

/* Model profiling is disabled. Its remaining printf calls are fatal diagnostics;
 * preserve the full format string, followed by the exit marker. Test output
 * itself uses console functions and does not depend on printf formatting. */
int printf(const char *format, ...) {
    console_puts(format);
    int bytes = 0;
    while (format[bytes]) ++bytes;
    return bytes;
}
int puts(const char *text) { console_puts(text); console_puts("\r\n"); return 0; }

__attribute__((noreturn)) void yolo32_fail(const char *reason) {
    console_puts("YOLO32_RESULT FAIL reason="); console_puts(reason);
    console_puts("\r\nHALTED: reset accelerator before retry\r\n");
    for (;;) cpu_wfi();
}
__attribute__((noreturn)) void exit(int status) {
    console_puts("YOLO32_EXIT status="); console_put_hex32((uint32_t)status);
    console_puts("\r\n");
    yolo32_fail("model_exit");
}
__attribute__((noreturn)) void runtime_trap(uint64_t cause, uint64_t pc, uint64_t value) {
    console_puts("YOLO32_TRAP cause="); console_put_hex64(cause);
    console_puts(" pc="); console_put_hex64(pc);
    console_puts(" tval="); console_put_hex64(value);
    console_puts("\r\n");
    yolo32_fail("trap");
}
