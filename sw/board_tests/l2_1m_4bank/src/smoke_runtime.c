#include "board_io.h"
#include "build_id.h"

uint32_t board_read32(unsigned off) { return *(volatile uint32_t *)(uintptr_t)(0x02020000UL + off); }
void board_write32(unsigned off, uint32_t value) { *(volatile uint32_t *)(uintptr_t)(0x02020000UL + off) = value; }
uint64_t board_cycles(void) { uint64_t value; __asm__ volatile("rdcycle %0" : "=r"(value)); return value; }
void board_fence(void) { __asm__ volatile("fence rw,rw" ::: "memory"); }
void board_text(const char *s) {
    volatile uint32_t *uart = (volatile uint32_t *)0x10020000UL;
    while (*s) {
        if (*s == '\n') { while (uart[0] & 0x80000000U) {} uart[0] = '\r'; }
        while (uart[0] & 0x80000000U) {}
        uart[0] = (unsigned char)*s++;
    }
}
void board_number(uint64_t value) {
    char text[24]; unsigned n = sizeof(text); text[--n] = 0;
    do { text[--n] = '0' + value % 10; value /= 10; } while (value);
    board_text(text + n);
}
void board_field(const char *name, uint64_t value) { board_text(name); board_number(value); }
void board_fail(const char *reason, uint64_t value) {
    board_text("L2BTEST,FAIL,reason="); board_text(reason); board_field(",value=", value); board_text("\n");
    __asm__ volatile("csrw mie,zero" ::: "memory");
    for (;;) __asm__ volatile("nop");
}
void __attribute__((interrupt("machine"), aligned(4))) trap_entry(void) {
    uint64_t cause, pc, value;
    __asm__ volatile("csrr %0,mcause" : "=r"(cause));
    __asm__ volatile("csrr %0,mepc" : "=r"(pc));
    __asm__ volatile("csrr %0,mtval" : "=r"(value));
    board_text("L2BTEST,TRAP"); board_field(",cause=", cause); board_field(",pc=", pc);
    board_field(",address=", value); board_text("\n"); board_fail("trap", cause);
}
int main(void) {
    volatile uint32_t *uart = (volatile uint32_t *)0x10020000UL;
    uart[2] = 1; uart[4] = 0; uart[6] = 867;
    board_text("L2BTEST,BUILD,schema=1,test=smoke,build_id=" L2_BUILD_ID ",source=" L2_SOURCE_REVISION "\n");
    int result = l2_smoke_run();
    for (;;) __asm__ volatile("nop");
    return result;
}
