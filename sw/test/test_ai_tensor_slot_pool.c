#include <assert.h>
#include <stdint.h>
#include <stdio.h>

#include "ai_tensor_slot_pool.h"

int main(void)
{
    AiTensorSlotPool pool;
    AiTensorSlotHandle handles[AI_TENSOR_SLOT_COUNT];
    AiTensorSlotHandle old;
    ai_tensor_slot_pool_init(&pool);
    assert(pool.slots[0].tensor_addr == TENSOR_ARENA0_PHYS_BASE);
    assert(pool.slots[16].tensor_addr == TENSOR_ARENA1_PHYS_BASE);
    assert(pool.slots[31].tensor_addr == TENSOR_ARENA1_PHYS_BASE +
                                          15U*TENSOR_MEMBER_STRIDE);

    for (uint32_t i = 0; i < AI_TENSOR_SLOT_COUNT; ++i)
        assert(ai_tensor_slot_begin_write(&pool, i % VIDEO_CHANNEL_COUNT,
                                          i + 1, 100 + i, i, &handles[i]) == 1);
    old = handles[0];
    assert(ai_tensor_slot_begin_write(&pool, 0, 40, 140, 40, &old) == 0);
    assert(ai_tensor_slot_finish_write(&pool, handles[0],
                                       TENSOR_MEMBER_BYTES, 0) == 1);
    assert(ai_tensor_slot_begin_write(&pool, 0, 40, 140, 40, &handles[0]) == 1);
    assert(ai_tensor_slot_get(&pool, old) == NULL);
    assert(ai_tensor_slot_finish_write(&pool, handles[16],
                                       TENSOR_MEMBER_BYTES, 0) == 1);
    assert(ai_tensor_slot_finish_write(&pool, handles[0],
                                       TENSOR_MEMBER_BYTES, 0) == 1);
    assert(pool.latest_ready[0] == handles[0].index);
    assert(pool.slots[handles[16].index].state == AI_TENSOR_SLOT_FREE);
    assert(ai_tensor_slot_acquire_latest(&pool, 0, 1, &old) == 1);
    assert(old.index == handles[0].index);
    assert(ai_tensor_slot_release(&pool, old) == 0);
    assert(ai_tensor_slot_release(&pool, old) == -1);

    /* An older DMA completion cannot replace a newer ready frame. */
    assert(ai_tensor_slot_begin_write(&pool, 0, 50, 150, 50,
                                      &handles[0]) == 1);
    assert(ai_tensor_slot_begin_write(&pool, 0, 49, 149, 49,
                                      &handles[16]) == 1);
    assert(ai_tensor_slot_finish_write(&pool, handles[0],
                                       TENSOR_MEMBER_BYTES, 0) == 1);
    assert(ai_tensor_slot_finish_write(&pool, handles[16],
                                       TENSOR_MEMBER_BYTES, 0) == 0);
    assert(pool.latest_ready[0] == handles[0].index);
    assert(ai_tensor_slot_acquire_latest(&pool, 0, 0, &old) == 1);
    assert(ai_tensor_slot_release(&pool, old) == 0);

    assert(ai_tensor_slot_begin_write(&pool, 0, 41, 141, 41, &old) == 1);
    assert(ai_tensor_slot_finish_write(&pool, old,
                                       TENSOR_MEMBER_BYTES - 32U, 0) == -1);
    assert(pool.slots[old.index].state == AI_TENSOR_SLOT_ERROR);
    assert(ai_tensor_slot_release(&pool, old) == 0);

    assert(ai_tensor_slot_finish_write(&pool, handles[1],
                                       TENSOR_MEMBER_BYTES, 0) == 1);
    assert(ai_tensor_slot_finish_write(&pool, handles[17],
                                       TENSOR_MEMBER_BYTES, 0) == 1);
    assert(pool.slots[handles[1].index].state == AI_TENSOR_SLOT_FREE);
    assert(ai_tensor_slot_acquire_latest(&pool, 1, 0, &old) == 1);
    assert(old.index == handles[17].index);
    assert(ai_tensor_slot_release(&pool, old) == 0);

    puts("AI_TENSOR_SLOT_POOL=PASS");
    return 0;
}
