.section .text.init,"ax",@progbits
.globl _start
.balign 4
_start:
    csrw mie, zero
    /* XS=Dirty for RoCC, FS=Dirty for the hard-float ABI. GCC's machine
       interrupt entry saves fcsr/FP registers even for an integer-only ISR. */
    li t0, 0x1e600
    csrw mstatus, t0
    fscsr zero
    csrw satp, zero
    sfence.vma
    /* Gemmini's baseline DTLB still checks PMP with translation disabled.
       Explicit NAPOT RWX region: physical DDR 0x80000000..0xffffffff. */
    csrw pmpcfg0, zero
    li t0, 0x2fffffff
    csrw pmpaddr0, t0
    li t0, 0x1f
    csrw pmpcfg0, t0
    .option push
    .option norelax
    la gp, __global_pointer$
    la sp, __stack_top
    .option pop
    la t0, trap_entry
    csrw mtvec, t0
    la t0, __bss_start
    la t1, __bss_end
1:  bgeu t0, t1, 2f
    sd zero, 0(t0)
    addi t0, t0, 8
    j 1b
2:  fence.i
    call main
3:  j 3b
