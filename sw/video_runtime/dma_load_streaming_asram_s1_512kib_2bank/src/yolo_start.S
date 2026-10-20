.section .text.init,"ax",@progbits
.globl _start
.balign 4
_start:
    csrw mie, zero
    /* XS/FS/VS=Dirty: RoCC, hard-float ABI and actual RVV tests. */
    li t0, 0x1e600
    csrw mstatus, t0
    fscsr zero
    csrw satp, zero
    sfence.vma
    /* Explicit NAPOT ASRAM 16MiB RW, DDR 2GiB RWX. Gemmini DTLB
       checks PMP even with translation disabled. ASRAM is not executable. */
    csrw pmpcfg0, zero
    li t0, 0x081fffff
    csrw pmpaddr0, t0
    li t0, 0x2fffffff
    csrw pmpaddr1, t0
    li t0, 0x1f1b
    csrw pmpcfg0, t0
    csrw vstart, zero
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
