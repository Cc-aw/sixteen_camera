#include <assert.h>
#include <stdio.h>
#include <string.h>
#include "ai/runtime/resources/rt_tensor_manager.h"
#include "ai/runtime/resources/rt_head_manager.h"
#include "ai/runtime/resources/rt_arena_manager.h"
#include "platform/platform.h"

static AiTensorDeviceDescriptor descriptor(uint32_t slot)
{
    return (AiTensorDeviceDescriptor){.tensor_addr =
        (slot < 16 ? TENSOR_ARENA0_PHYS_BASE : TENSOR_ARENA1_PHYS_BASE) + (slot % 16) * TENSOR_MEMBER_STRIDE,
        .stream_id = slot % 16, .frame_id = UINT64_C(0x100000065), .timestamp = UINT64_C(0x123456789),
        .version = 7, .byte_count = TENSOR_MEMBER_BYTES, .state = AI_TENSOR_DEVICE_READY};
}
int main(void)
{
    AiRtTensorManager tensor; rt_tensor_manager_init(&tensor);
    for (uint32_t slot = 0; slot < 32; ++slot) {
        AiTensorDeviceDescriptor d = descriptor(slot);
        AiRtJobIdentity id = rt_job_identity(4097 + slot, slot % 3, d.stream_id, d.frame_id, d.version);
        AiRtSlotHandle h, duplicate;
        assert(rt_tensor_claim(&tensor, slot, &d, &id, &h) == 0);
        assert(h.generation == 1 && h.generation != d.version);
        assert(rt_tensor_claim(&tensor, slot, &d, &id, &duplicate) < 0);
        assert(!rt_tensor_can_release(&tensor, h, &id));
        assert(rt_tensor_prove_compute(&tensor, h, &id) < 0); /* Not accepted yet. */
        assert(rt_tensor_accept(&tensor, h, &id) == 0);
        AiRtJobIdentity bad = id;
        bad.job_id++; assert(rt_tensor_prove_compute(&tensor, h, &bad) < 0);
        bad = id; bad.worker_id ^= 1; assert(rt_tensor_prove_compute(&tensor, h, &bad) < 0);
        bad = id; bad.stream_id ^= 1; assert(rt_tensor_prove_compute(&tensor, h, &bad) < 0);
        bad = id; bad.frame_id++; assert(rt_tensor_prove_compute(&tensor, h, &bad) < 0);
        bad = id; bad.version++; assert(rt_tensor_prove_compute(&tensor, h, &bad) < 0);
        assert(rt_tensor_prove_compute(&tensor, h, &id) == 0);
        assert(rt_tensor_can_release(&tensor, h, &id));
        rt_tensor_release_retry(&tensor); assert(tensor.held & (1U << slot));
        assert(rt_tensor_release_ack(&tensor, h, &id) == 0);
        assert(rt_tensor_release_ack(&tensor, h, &id) < 0);
        assert(rt_tensor_claim(&tensor, slot, &d, &id, &duplicate) == 0); /* Repeated producer version. */
        assert(duplicate.generation == 2 && !rt_tensor_can_release(&tensor, h, &id));
        assert(rt_tensor_prove_compute(&tensor, h, &id) < 0);
        assert(rt_tensor_reject(&tensor, duplicate, &id) == 0);
    }
    assert(!tensor.held && tensor.release_retry == 32);
    AiTensorDeviceDescriptor d = descriptor(31);
    AiRtJobIdentity id = rt_job_identity(5000, 2, 15, d.frame_id, 7);
    AiRtSlotHandle h;
    d.tensor_addr++; assert(rt_tensor_claim(&tensor, 31, &d, &id, &h) < 0); d.tensor_addr--;
    assert(rt_tensor_claim(&tensor, 31, &d, &id, &h) == 0);
    assert(rt_tensor_accept(&tensor, h, &id) == 0);
    rt_tensor_fault(&tensor, h); rt_tensor_fault(&tensor, h);
    assert(tensor.held == 0x80000000 && tensor.unsafe_fault == 1 && !rt_tensor_can_release(&tensor, h, &id));
    assert(rt_tensor_prove_compute(&tensor, h, &id) < 0);
    tensor.slots[0].generation = UINT64_MAX;
    d = descriptor(0); id = rt_job_identity(6000, 0, 0, d.frame_id, 7);
    assert(rt_tensor_claim(&tensor, 0, &d, &id, &h) < 0);

    for (uint32_t workers = 1; workers <= 3; ++workers) {
        AiRtArenaManager arena; rt_arena_manager_init(&arena, workers);
        AiHeadSlotQueue queue; ai_head_slot_queue_init(&queue, workers);
        AiRtHeadManager heads; rt_head_manager_init(&heads);
        for (uint32_t w = 0; w < workers; ++w) {
            AiModelFrameRequest r = {.job_id = 100 + w, .worker_id = w, .stream_id = w + 4,
                .frame_id = UINT64_C(0x100000001) + w, .version = 9};
            id = rt_job_identity(r.job_id, w, r.stream_id, r.frame_id, r.version);
            assert(rt_arena_claim(&arena, &id) == 0);
            assert(arena.workers[w].head_pool_base == AI_MODEL_OUTPUT0_PHYS_BASE + w * AI_MODEL_OUTPUT_ARENA_BYTES);
            uint32_t key;
            assert(ai_head_slot_acquire(&queue, w, arena.workers[w].head_pool_base, &r, &key) == 0);
            assert(rt_head_bind(&heads, &queue, key, 7) == 0);
            AiRtSlotHandle lease = {key, heads.slots[key].generation};
            assert(rt_head_retire(&heads, &queue, lease, &id) < 0); /* Compute != PPU completion. */
            assert(ai_head_slot_publish(&queue, key) == 0);
            assert(rt_arena_compute_done(&arena, &id) == 0);
            assert(heads.slots[key].state == AI_RT_OWNED && arena.workers[w].state == AI_RT_FREE);
            AiHeadSlot *active; assert(ai_head_slot_start_next(&queue, &active) == 1);
            AiPpuDeviceResult result = {.bank = key, .generation = 7, .stream = r.stream_id,
                                        .frame = r.frame_id, .version = r.version};
            assert(rt_head_result_matches(&heads, &queue, &result));
            result.generation++; assert(!rt_head_result_matches(&heads, &queue, &result)); result.generation--;
            result.frame++; assert(!rt_head_result_matches(&heads, &queue, &result)); result.frame--;
            assert(ai_head_slot_complete(&queue, 0) == 0);
            assert(rt_head_retire(&heads, &queue, lease, &id) == 0);
            assert(rt_head_retire(&heads, &queue, lease, &id) < 0);
            /* Two slots per worker; reused software generation rejects old handles even with repeated HW generation. */
            queue.next_slot[w] = 0;
            assert(ai_head_slot_acquire(&queue, w, arena.workers[w].head_pool_base, &r, &key) == 0);
            assert(rt_head_bind(&heads, &queue, key, 7) == 0);
            assert(heads.slots[key].generation == 2);
            assert(rt_head_retire(&heads, &queue, lease, &id) < 0);
            rt_head_fault(&heads, key);
            assert(heads.slots[key].state == AI_RT_FAULT_HELD);
            assert(rt_arena_claim(&arena, &id) == 0); rt_arena_fault(&arena, w);
            assert(rt_arena_compute_done(&arena, &id) < 0);
        }
    }
    AiRtJob job = {0}; id = rt_job_identity(7000, 0, 0, 42, 7);
    assert(rt_job_begin(&job, &id) == 0);
    AiRtJobIdentity bad = id; bad.job_id++;
    assert(rt_job_compute_done(&job, &bad) < 0); rt_job_fault(&job);
    assert(rt_job_begin(&job, &id) < 0 && rt_job_compute_done(&job, &id) < 0);
    puts("R2_RESOURCES=PASS Tensor=32 Head=6 workers=1,2,3 identity_generation_retry_fault_independent_retirement");
    return 0;
}
