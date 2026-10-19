.section .text,"ax",@progbits
.globl probe_read, probe_read_fault, probe_read_resume
.globl probe_write, probe_write_fault, probe_write_resume
.balign 4
probe_read:
probe_read_fault:
    ld a0, 0(a0)
probe_read_resume:
    ret
.balign 4
probe_write:
probe_write_fault:
    sd zero, 0(a0)
probe_write_resume:
    ret
