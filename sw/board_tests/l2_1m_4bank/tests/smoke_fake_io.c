/* Independent MMIO state model and fault injection for the actual smoke C. */
#include <assert.h>
#include <setjmp.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../src/l2_smoke.c"

static jmp_buf failure;
static unsigned fault, enabled, valid, sequence, selector, phase;
static uint64_t ticks;
static const char *reason;
uint64_t board_cycles(void) { ticks += 50000; return ticks; }
void board_fence(void) { __asm__ volatile("" ::: "memory"); }
void board_text(const char *text) { fputs(text, stdout); }
void board_number(uint64_t value) { printf("%llu", (unsigned long long)value); }
void board_field(const char *name, uint64_t value) { board_text(name); board_number(value); }
void board_fail(const char *text, uint64_t value) {
    board_text("L2BTEST,FAIL,reason="); board_text(text); board_field(",value=", value); board_text("\n");
    reason = text; longjmp(failure, 1);
}
uint32_t board_read32(unsigned offset) {
    uint64_t value = 0;
    switch (offset & ~7U) {
        case 0: value = UINT64_C(0x4d50563300010002) - (fault == 1); break;
        case 0x10: value = 8 | (enabled ? 2 : 0) | (valid ? 4 : 0) | (fault == 2 ? 1 : 0); break;
        case 0x18: value = sequence; break;
        case 0x20: value = selector ^ (fault == 6); break;
        case 0x28: {
            assert(valid && !enabled);
            unsigned block = selector / 32, slot = selector % 32;
            value = slot == 31 ? ticks : 1;
            if (block == 15 && slot == 1 && fault == 3) value = 0;
            if (block == 14 && slot == 11 && fault == 7) value = 33;
            break;
        }
        case 0x30: value = 0x3000; break;
        case 0x38: value = 1048576; break;
        case 0x40: value = 100000000; break;
        case 0x48: value = 300000000; break;
        case 0x50: value = 16; break;
        case 0x58: value = 4; break;
        case 0x60: value = 512; break;
        case 0x68: value = 32; break;
        default: abort();
    }
    return (uint32_t)(value >> ((offset & 4) ? 32 : 0));
}
void board_write32(unsigned offset, uint32_t value) {
    if (offset == 0x20) { assert(value < 512); selector = value; return; }
    assert(offset == 8);
    switch (value) {
        case 1: assert(!enabled && !valid); enabled = 1; phase++; break;
        case 2:
            assert(enabled); enabled = 0;
            if (fault == 5 && phase == 1) data[8192] ^= 1;
            break;
        case 3: assert(!enabled); valid = 0; break;
        case 4: assert(!enabled); valid = 1; sequence += fault == 4 ? 2 : 1; break;
        default: abort();
    }
}
int main(int argc, char **argv) {
    fault = argc > 1 ? (unsigned)atoi(argv[1]) : 0;
    if (!setjmp(failure)) {
        int result = l2_smoke_run();
        return fault ? 2 : result;
    }
    fprintf(stderr, "HOST_REJECTED=%s\n", reason);
    return fault ? 1 : 2;
}
