/* Execute existing Head ownership workloads unchanged, recording every PPU
 * transaction and UART argument against the frozen R1a backend/drivers. */
#include <stdio.h>
#include <stdint.h>
int trace_puts(const char *value);
#define mmio_read32 fixture_read32
#define mmio_write32 fixture_write32
#define mmio_fence fixture_fence
#define console_puts fixture_console_puts
#define console_putc fixture_console_putc
#define console_put_u32 fixture_console_put_u32
#define console_put_hex32 fixture_console_put_hex32
#define console_put_hex64 fixture_console_put_hex64
#define cache_flush_range fixture_cache_flush_range
#define puts trace_puts
#ifdef R1B_LEGACY
#include "test_runtime_ppu_legacy_trace.c"
#elif defined(R1B_ALL_WORKERS)
#include "test_v17a_backend.c"
#else
#include "test_runtime_baseline_trace.c"
#endif
#undef mmio_read32
#undef mmio_write32
#undef mmio_fence
#undef console_puts
#undef console_putc
#undef console_put_u32
#undef console_put_hex32
#undef console_put_hex64
#undef cache_flush_range
#undef puts

uint32_t mmio_read32(uintptr_t address)
{
    uint32_t value;
#ifdef R1B_LEGACY
    uintptr_t offset = address - POSTPROCESS_DIAG_BASE;
    if (offset == 0x238) value = 0;
    else if (offset == 0x100 && !legacy_core_present) value = 0;
    else if (offset == 0x1a0 && !legacy_publication_present) value = 0;
    else value = fixture_read32(address);
#else
    value = fixture_read32(address);
#endif
    printf("MMIO_R %lx %08x cycle=%llu\n", (unsigned long)(address - POSTPROCESS_DIAG_BASE),
           value, (unsigned long long)test_cycle);
    return value;
}
void mmio_write32(uintptr_t address, uint32_t value)
{
    printf("MMIO_W %lx %08x cycle=%llu\n", (unsigned long)(address - POSTPROCESS_DIAG_BASE),
           value, (unsigned long long)test_cycle);
    fixture_write32(address, value);
}
void mmio_fence(void)
{
#ifdef R1B_LEGACY
    printf("MMIO_F cycle=%llu\n", (unsigned long long)test_cycle);
#else
    fixture_fence(); /* Reject any live global fence. */
#endif
}
void cache_flush_range(const void *address, size_t bytes)
{
#ifdef R1B_LEGACY
    printf("CACHE_FLUSH address=%lx bytes=%zu cycle=%llu\n", (unsigned long)address,
           bytes, (unsigned long long)test_cycle);
#else
    fixture_cache_flush_range(address, bytes);
#endif
}
void console_puts(const char *value)
{
    fputs("UART_S hex=", stdout);
    for (const unsigned char *p = (const unsigned char *)value; *p; ++p)
        printf("%02x", *p);
    putchar('\n');
}
void console_putc(char value) { printf("UART_C %u\n", (unsigned char)value); }
void console_put_u32(uint32_t value) { printf("UART_U32 %u\n", value); }
void console_put_hex32(uint32_t value) { printf("UART_HEX32 %08x\n", value); }
void console_put_hex64(uint64_t value) { printf("UART_HEX64 %016llx\n", (unsigned long long)value); }
int trace_puts(const char *value)
{
    return printf("%s cycle=%llu\n", value, (unsigned long long)test_cycle);
}
