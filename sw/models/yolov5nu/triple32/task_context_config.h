#ifndef YOLO32_TASK_CONTEXT_CONFIG_H
#define YOLO32_TASK_CONTEXT_CONFIG_H

/* Shared by C and preprocessed assembly. Switches are cooperative C calls,
 * never interrupts or calls from inside a live RVV assembly kernel. */
#ifndef YOLO32_CONTEXT_FULL
#define YOLO32_CONTEXT_FULL 0
#endif
#if YOLO32_CONTEXT_FULL != 0 && YOLO32_CONTEXT_FULL != 1
#error "YOLO32_CONTEXT_FULL must be 0 or 1"
#endif
#if YOLO32_CONTEXT_FULL
#define YOLO32_CONTEXT_NAME "full"
#define YOLO32_CONTEXT_SAVED_BYTES 1264
#define YOLO32_CONTEXT_VECTOR_BYTES 1024
#else
#define YOLO32_CONTEXT_NAME "light"
/* ra/sp/s0-s11, fs0-fs11, FCSR, VCSR. VL/VTYPE and v0-v31 are call-clobbered.
 * VCSR is deliberately preserved for the project's fixed-point operators;
 * reading it also waits for outstanding Saturn vector work before handoff. */
#define YOLO32_CONTEXT_SAVED_BYTES 224
#define YOLO32_CONTEXT_VECTOR_BYTES 0
#endif

#endif
