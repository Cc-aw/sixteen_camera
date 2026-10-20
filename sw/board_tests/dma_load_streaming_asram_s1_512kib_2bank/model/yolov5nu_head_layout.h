#ifndef YOLOV5NU_HEAD_LAYOUT_H
#define YOLOV5NU_HEAD_LAYOUT_H

#include <stdint.h>

/*
 * Device-memory layout for one raw YOLOv5nu head slot.  The six tensors are
 * deliberately contiguous and every boundary is one 64-byte cache line.
 * A 1 MiB stride leaves room for future descriptor/result metadata while two
 * slots still fit in the existing 4 MiB worker output arena.
 */
#define YOLOV5NU_HEAD_CLASS0_OFFSET UINT32_C(0x00000)
#define YOLOV5NU_HEAD_CLASS1_OFFSET UINT32_C(0x5dc00)
#define YOLOV5NU_HEAD_CLASS2_OFFSET UINT32_C(0x75300)
#define YOLOV5NU_HEAD_DFL0_OFFSET   UINT32_C(0x7b0c0)
#define YOLOV5NU_HEAD_DFL1_OFFSET   UINT32_C(0xc60c0)
#define YOLOV5NU_HEAD_DFL2_OFFSET   UINT32_C(0xd8cc0)

#define YOLOV5NU_HEAD_CLASS0_BYTES UINT32_C(384000)
#define YOLOV5NU_HEAD_CLASS1_BYTES UINT32_C(96000)
#define YOLOV5NU_HEAD_CLASS2_BYTES UINT32_C(24000)
#define YOLOV5NU_HEAD_DFL0_BYTES   UINT32_C(307200)
#define YOLOV5NU_HEAD_DFL1_BYTES   UINT32_C(76800)
#define YOLOV5NU_HEAD_DFL2_BYTES   UINT32_C(19200)

#define YOLOV5NU_HEAD_PAYLOAD_BYTES UINT32_C(907200)
#define YOLOV5NU_HEAD_SLOT_STRIDE   UINT32_C(0x00100000)
#define YOLOV5NU_HEAD_SLOTS_PER_WORKER UINT32_C(2)
#define YOLOV5NU_HEAD_POOL_BYTES \
    (YOLOV5NU_HEAD_SLOT_STRIDE * YOLOV5NU_HEAD_SLOTS_PER_WORKER)

#if YOLOV5NU_HEAD_DFL2_OFFSET + YOLOV5NU_HEAD_DFL2_BYTES != \
    YOLOV5NU_HEAD_PAYLOAD_BYTES
#error "YOLOv5nu head layout size mismatch"
#endif

#if (YOLOV5NU_HEAD_CLASS1_OFFSET & 63) || \
    (YOLOV5NU_HEAD_CLASS2_OFFSET & 63) || \
    (YOLOV5NU_HEAD_DFL0_OFFSET & 63) || \
    (YOLOV5NU_HEAD_DFL1_OFFSET & 63) || \
    (YOLOV5NU_HEAD_DFL2_OFFSET & 63) || \
    (YOLOV5NU_HEAD_PAYLOAD_BYTES & 63)
#error "YOLOv5nu head layout must remain 64-byte aligned"
#endif

#endif
