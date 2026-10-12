/* Cooperative C ABI switch, plus FP environment and VCSR.
 * gp/tp are shared; caller-saved scalar/FP registers follow the normal ABI.
 * Full mode additionally preserves all RVV registers and VL/VTYPE.
 * Reading VCSR waits for Saturn before another task reuses its vector unit. */
#include "task_context_config.h"
.text
.align 2
.global yolo32_task_switch
.type yolo32_task_switch, @function
yolo32_task_switch:
    la t0, yolo32_task_switch_profile
    lw t0, 0(t0)
    beqz t0, .Lswitch_begin
    rdcycle t2
.Lswitch_begin:
    sd ra, 0(a0)
    sd sp, 8(a0)
    sd s0, 16(a0)
    sd s1, 24(a0)
    sd s2, 32(a0)
    sd s3, 40(a0)
    sd s4, 48(a0)
    sd s5, 56(a0)
    sd s6, 64(a0)
    sd s7, 72(a0)
    sd s8, 80(a0)
    sd s9, 88(a0)
    sd s10, 96(a0)
    sd s11, 104(a0)
    fsd fs0, 112(a0)
    fsd fs1, 120(a0)
    fsd fs2, 128(a0)
    fsd fs3, 136(a0)
    fsd fs4, 144(a0)
    fsd fs5, 152(a0)
    fsd fs6, 160(a0)
    fsd fs7, 168(a0)
    fsd fs8, 176(a0)
    fsd fs9, 184(a0)
    fsd fs10, 192(a0)
    fsd fs11, 200(a0)
    csrr t0, fcsr
    sd t0, 208(a0)
#if YOLO32_CONTEXT_FULL
    csrr t0, vl
    sd t0, 216(a0)
    csrr t0, vtype
    sd t0, 224(a0)
#endif
    csrr t0, vcsr
    sd t0, 232(a0)
    csrw vstart, zero
#if YOLO32_CONTEXT_FULL
    addi t0, a0, 240
    vs8r.v v0, (t0)
    addi t0, t0, 256
    vs8r.v v8, (t0)
    addi t0, t0, 256
    vs8r.v v16, (t0)
    addi t0, t0, 256
    vs8r.v v24, (t0)
    /* Drain vector save stores before another task can access its context. */
    csrr t0, vl
    addi t0, a1, 240
    vl8re8.v v0, (t0)
    addi t0, t0, 256
    vl8re8.v v8, (t0)
    addi t0, t0, 256
    vl8re8.v v16, (t0)
    addi t0, t0, 256
    vl8re8.v v24, (t0)
    ld t0, 216(a1)
    ld t1, 224(a1)
    vsetvl zero, t0, t1
#endif
    ld t0, 232(a1)
    csrw vcsr, t0
    ld t0, 208(a1)
    csrw fcsr, t0
    fld fs0, 112(a1)
    fld fs1, 120(a1)
    fld fs2, 128(a1)
    fld fs3, 136(a1)
    fld fs4, 144(a1)
    fld fs5, 152(a1)
    fld fs6, 160(a1)
    fld fs7, 168(a1)
    fld fs8, 176(a1)
    fld fs9, 184(a1)
    fld fs10, 192(a1)
    fld fs11, 200(a1)
    ld ra, 0(a1)
    ld sp, 8(a1)
    ld s0, 16(a1)
    ld s1, 24(a1)
    ld s2, 32(a1)
    ld s3, 40(a1)
    ld s4, 48(a1)
    ld s5, 56(a1)
    ld s6, 64(a1)
    ld s7, 72(a1)
    ld s8, 80(a1)
    ld s9, 88(a1)
    ld s10, 96(a1)
    ld s11, 104(a1)
    la t0, yolo32_task_switch_profile
    lw t0, 0(t0)
    beqz t0, .Lswitch_return
    rdcycle t0
    sub t0, t0, t2
    la t1, yolo32_task_switch_cycles
    ld t2, 0(t1)
    add t0, t0, t2
    sd t0, 0(t1)
    la t1, yolo32_task_switch_count
    ld t0, 0(t1)
    addi t0, t0, 1
    sd t0, 0(t1)
.Lswitch_return:
    ret
.size yolo32_task_switch, .-yolo32_task_switch
