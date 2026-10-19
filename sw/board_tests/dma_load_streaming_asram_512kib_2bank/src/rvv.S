.section .text,"ax",@progbits
.globl hw_rvv_copy
.balign 4
hw_rvv_copy:
    beqz a2, 2f
1:  vsetvli t0, a2, e8, m1, ta, ma
    vle8.v v0, (a1)
    vse8.v v0, (a0)
    add a0, a0, t0
    add a1, a1, t0
    sub a2, a2, t0
    bnez a2, 1b
2:  fence rw,rw
    ret
