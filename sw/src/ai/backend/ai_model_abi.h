#ifndef AI_MODEL_ABI_H
#define AI_MODEL_ABI_H

#include <stddef.h>
#include <stdint.h>

#define AI_YOLOV5NU_CHANNELS 84U
#define AI_YOLOV5NU_ANCHORS 6300U
#define AI_YOLOV5NU_CLASSES 80U
#define AI_YOLOV5NU_INPUT_WIDTH 640U
#define AI_YOLOV5NU_INPUT_HEIGHT 480U
#define AI_YOLOV5NU_INPUT_CHANNELS 3U
#define AI_YOLOV5NU_INPUT_BYTES (AI_YOLOV5NU_INPUT_WIDTH * \
                                 AI_YOLOV5NU_INPUT_HEIGHT * \
                                 AI_YOLOV5NU_INPUT_CHANNELS)

/* Temporary board model contract: TinyYOLOv2 consumes NHWC RGB INT8. */
#define AI_TINYYOLOV2_INPUT_WIDTH 416U
#define AI_TINYYOLOV2_INPUT_HEIGHT 416U
#define AI_TINYYOLOV2_INPUT_CHANNELS 3U
#define AI_TINYYOLOV2_INPUT_BYTES (AI_TINYYOLOV2_INPUT_WIDTH * \
                                   AI_TINYYOLOV2_INPUT_HEIGHT * \
                                   AI_TINYYOLOV2_INPUT_CHANNELS)

#ifdef AI_MODEL_YOLOV5NU
#define AI_MODEL_INPUT_WIDTH  AI_YOLOV5NU_INPUT_WIDTH
#define AI_MODEL_INPUT_HEIGHT AI_YOLOV5NU_INPUT_HEIGHT
#define AI_MODEL_INPUT_BYTES  AI_YOLOV5NU_INPUT_BYTES
#else
#define AI_MODEL_INPUT_WIDTH  AI_TINYYOLOV2_INPUT_WIDTH
#define AI_MODEL_INPUT_HEIGHT AI_TINYYOLOV2_INPUT_HEIGHT
#define AI_MODEL_INPUT_BYTES  AI_TINYYOLOV2_INPUT_BYTES
#endif

typedef enum {
    AI_TENSOR_DTYPE_F32 = 0,
    AI_TENSOR_DTYPE_I8,
    AI_TENSOR_DTYPE_I16,
    AI_TENSOR_DTYPE_Q16_16,
    /* output_addr points at an AiDetectionResult owned by the backend */
    AI_TENSOR_DTYPE_CUSTOM
} AiTensorDType;

typedef enum {
    AI_TENSOR_LAYOUT_CHANNEL_ANCHOR = 0,
    AI_TENSOR_LAYOUT_ANCHOR_CHANNEL
} AiTensorLayout;

/*
 * Quantized tensors may use different affine scales for decoded coordinates
 * and sigmoid class scores. Scales are represented directly in Q16.16.
 */
typedef struct {
    AiTensorDType dtype;
    AiTensorLayout layout;
    uint32_t channels;
    uint32_t anchors;
    uint32_t bytes;
    int32_t coordinate_scale_q16;
    int32_t score_scale_q16;
    int32_t coordinate_zero_point;
    int32_t score_zero_point;
} AiTensorDesc;

typedef struct {
    uint64_t job_id;
    uint32_t worker_id;
    uint32_t stream_id;
    uint64_t frame_id;
    uint64_t timestamp;
    uint32_t version;
    uintptr_t input_addr;
    uint32_t input_bytes;
    uintptr_t output_addr;
    uint32_t output_bytes;
} AiModelFrameRequest;

typedef struct {
    uint64_t cpu_scheduler_cycles;
    uint64_t rocc_submit_cycles;
    uint64_t gemmini_busy_cycles;
    uint64_t gemmini_load_stall_cycles;
    uint64_t gemmini_exec_cycles;
    uint64_t gemmini_store_stall_cycles;
    uint64_t rvv_maxpool_cycles;
    uint64_t rvv_resize_cycles;
    uint64_t rvv_copy_requant_cycles;
    uint64_t fence_cycles;
    uint64_t tensor_wait_cycles;
    uint64_t head_wait_cycles;
    uint64_t ppu_queue_wait_cycles;
} AiFrameProfile;

/*
 * The input tensor and Gemmini activation arena may be released after this
 * event.  Final detections are delivered separately because hardware
 * postprocessing can still own the raw-head slot.
 */
typedef struct {
    uint64_t job_id;
    uint32_t worker_id;
    uint32_t stream_id;
    uint64_t frame_id;
    uint32_t version;
    int32_t status;
    uint64_t compute_cycles;
    AiFrameProfile profile;
} AiModelComputeCompletion;

typedef struct {
    uint64_t job_id;
    uint32_t worker_id;
    uint32_t stream_id;
    uint64_t frame_id;
    uint32_t version;
    int32_t status;
    uint64_t compute_cycles;
    AiFrameProfile profile;
    uintptr_t output_addr;
    AiTensorDesc output_desc;
} AiModelFrameCompletion;

#endif
