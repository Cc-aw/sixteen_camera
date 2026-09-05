    .section .text.init
    .align 4
    .globl _start
    .type _start, @function
_start:
    csrwi mie, 0
    csrwi mip, 0

    .option push
    .option norelax
    la gp, __global_pointer$
    .option pop

    la sp, __stack_top
    la t0, trap_entry
    csrw mtvec, t0

    la t0, __bss_start
    la t1, __bss_end
1:
    bgeu t0, t1, 2f
    sd zero, 0(t0)
    addi t0, t0, 8
    j 1b
2:
    /* TinyYOLOv2 uses both floating-point scales and RVV pooling helpers. */
    li t0, (3 << 13) | (3 << 9)
    csrs mstatus, t0
    call main
3:
    wfi
    j 3b

    .align 4
trap_entry:
    csrr a0, mcause
    csrr a1, mepc
    csrr a2, mtval
    la sp, __stack_top
    call runtime_trap
4:
    wfi
    j 4b

    .size _start, .-_start
