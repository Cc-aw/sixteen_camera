/* Freeze the existing RV64-facing software ABI before adding Runtime types. */
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include "ai/backend/ai_model_backend.h"
#include "ai/runtime/ai_head_slot_queue.h"
#include "ai/runtime/ai_tensor_slot_pool.h"

_Static_assert(sizeof(uintptr_t) == 8, "R0 requires an RV64-compatible host ABI");
_Static_assert(sizeof(AiModelFrameRequest) == 72, "request ABI changed");
_Static_assert(offsetof(AiModelFrameRequest, version) == 32, "request identity moved");
_Static_assert(offsetof(AiModelFrameRequest, input_addr) == 40, "input pointer moved");
_Static_assert(offsetof(AiModelFrameRequest, output_addr) == 56, "output pointer moved");
_Static_assert(sizeof(AiFrameProfile) == 104, "profile ABI changed");
_Static_assert(sizeof(AiModelComputeCompletion) == 144, "compute event ABI changed");
_Static_assert(offsetof(AiModelComputeCompletion, profile) == 40, "compute profile moved");
_Static_assert(sizeof(AiModelFrameCompletion) == 192, "result event ABI changed");
_Static_assert(offsetof(AiModelFrameCompletion, output_addr) == 144, "result pointer moved");
_Static_assert(sizeof(AiTensorDesc) == 36, "tensor descriptor ABI changed");
_Static_assert(sizeof(AiHeadSlotDescriptor) == 96, "Head identity ABI changed");
_Static_assert(offsetof(AiHeadSlotDescriptor, base_addr) == 40, "Head base moved");
_Static_assert(sizeof(AiHeadSlot) == 112, "legacy Head slot ABI changed");
_Static_assert(sizeof(AiTensorSlot) == 48, "legacy Tensor metadata ABI changed");
_Static_assert(AI_TENSOR_SLOT_COUNT == 32 && AI_HEAD_SLOT_QUEUE_CAPACITY == 6,
               "hardware pool limits changed");
_Static_assert(AI_MODEL_RESULT_QUEUE_CAPACITY == AI_MODEL_WORKER_COUNT * 2,
               "backend result capacity changed");
_Static_assert(AI_MODEL_POSTPROCESS_CAPACITY == AI_MODEL_WORKER_COUNT * 4,
               "runtime post-job capacity changed");
_Static_assert(TENSOR_MEMBER_BYTES == 921600 && YOLOV5NU_HEAD_PAYLOAD_BYTES == 907200,
               "model payload ABI changed");

int main(void)
{
    printf("R0_ABI=PASS workers=%u request=%zu compute=%zu result=%zu head_descriptor=%zu tensor_metadata=%zu\n",
           AI_MODEL_WORKER_COUNT, sizeof(AiModelFrameRequest), sizeof(AiModelComputeCompletion),
           sizeof(AiModelFrameCompletion), sizeof(AiHeadSlotDescriptor), sizeof(AiTensorSlot));
    return 0;
}
