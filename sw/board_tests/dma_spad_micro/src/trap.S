.section .text.trap,"ax",@progbits
.globl trap_entry
.balign 4
trap_entry:
    csrr a0, mcause
    csrr a1, mepc
    csrr a2, mtval
    tail micro_trap
