#include "drivers/tensor/ai_tensor_device.h"

#include "mmio.h"
#include "platform/platform.h"

#define TENSOR_DEVICE_MMIO_TIMEOUT (SOC_CLOCK_HZ / UINT64_C(10))
#define TENSOR_DEVICE_META_SETTLE (SOC_CLOCK_HZ / UINT64_C(100000))

_Static_assert(AI_TENSOR_DEVICE_SLOT_COUNT == VIDEO_CHANNEL_COUNT * 2U,
               "Tensor device requires two fixed slots per stream");

static uint32_t slot_address(uint32_t slot)
{
    uint32_t arena_base = slot < VIDEO_CHANNEL_COUNT ?
                          TENSOR_ARENA0_PHYS_BASE : TENSOR_ARENA1_PHYS_BASE;
    return arena_base + (slot % VIDEO_CHANNEL_COUNT) * TENSOR_MEMBER_STRIDE;
}

uint32_t ai_tensor_device_ready(void)
{
    return mmio_read32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_READY);
}

uint32_t ai_tensor_device_error(void)
{
    return mmio_read32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_ERROR);
}

uint32_t ai_tensor_device_writing(void)
{
    return mmio_read32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_WRITING);
}

int ai_tensor_device_select_slot(uint32_t slot)
{
    if (slot >= AI_TENSOR_DEVICE_SLOT_COUNT)
        return -1;
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_INDEX, slot);
    mmio_fence();
    uint64_t settle_start = read_cycle();
    while (read_cycle() - settle_start < TENSOR_DEVICE_META_SETTLE)
        ;
    return 0;
}

int ai_tensor_device_read_slot(uint32_t slot, AiTensorDeviceDescriptor *descriptor)
{
    if (slot >= AI_TENSOR_DEVICE_SLOT_COUNT || descriptor == 0)
        return -1;
    (void)ai_tensor_device_select_slot(slot);
    uint64_t start = read_cycle();
    do {
        uint32_t version_before = mmio_read32(
            FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_VERSION);
        uint32_t time_lo = mmio_read32(
            FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_TIME_LO);
        uint32_t time_hi = mmio_read32(
            FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_TIME_HI);
        uint32_t frame = mmio_read32(
            FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_FRAME);
        uint32_t bytes = mmio_read32(
            FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_BYTES);
        uint32_t stream = mmio_read32(
            FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_STREAM);
        uint32_t address = mmio_read32(
            FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_ADDR);
        uint32_t state = mmio_read32(
            FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_STATE);
        uint32_t error_code = mmio_read32(
            FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_ERROR_CODE);
        uint32_t version_after = mmio_read32(
            FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_VERSION);
        if (version_before != 0U && version_before == version_after &&
            stream == slot % VIDEO_CHANNEL_COUNT &&
            address == slot_address(slot) && bytes == TENSOR_MEMBER_BYTES &&
            state == AI_TENSOR_DEVICE_READY &&
            (ai_tensor_device_ready() & (UINT32_C(1) << slot)) != 0U) {
            descriptor->tensor_addr = address;
            descriptor->stream_id = stream;
            descriptor->frame_id = frame;
            descriptor->timestamp = (uint64_t)time_lo | ((uint64_t)time_hi << 32);
            descriptor->version = version_after;
            descriptor->byte_count = bytes;
            descriptor->error_code = error_code;
            descriptor->state = AI_TENSOR_DEVICE_READY;
            return 0;
        }
    } while (read_cycle() - start < TENSOR_DEVICE_MMIO_TIMEOUT);
    return -1;
}

int ai_tensor_device_release_poll(uint32_t slot)
{
    if (slot >= AI_TENSOR_DEVICE_SLOT_COUNT)
        return -1;
    if (mmio_read32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_CONTROL) &
        FRAMEBUFFER_TENSOR_PROD_RELEASE_GO)
        return AI_TENSOR_RELEASE_WAIT;
    uint32_t bit = UINT32_C(1) << slot;
    return ((ai_tensor_device_ready() | ai_tensor_device_error()) & bit) == 0U ?
        AI_TENSOR_RELEASE_ACK : AI_TENSOR_RELEASE_SLOT_PRESENT;
}

int ai_tensor_device_release(uint32_t slot, uint32_t producer_enabled)
{
    if (slot >= AI_TENSOR_DEVICE_SLOT_COUNT)
        return -1;
    uint32_t bit = UINT32_C(1) << slot;
    uint64_t start = read_cycle();
    while ((mmio_read32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_CONTROL) &
            FRAMEBUFFER_TENSOR_PROD_RELEASE_GO) != 0U) {
        if (read_cycle() - start > TENSOR_DEVICE_MMIO_TIMEOUT)
            return -1;
    }
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_RELEASE, bit);
    mmio_fence();
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_CONTROL,
                 (producer_enabled != 0U ? FRAMEBUFFER_TENSOR_PROD_ENABLE : 0U) |
                 FRAMEBUFFER_TENSOR_PROD_RELEASE_GO);
    mmio_fence();
    start = read_cycle();
    while (((ai_tensor_device_ready() | ai_tensor_device_error()) & bit) != 0U ||
           (mmio_read32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_CONTROL) &
            FRAMEBUFFER_TENSOR_PROD_RELEASE_GO) != 0U) {
        if (read_cycle() - start > TENSOR_DEVICE_MMIO_TIMEOUT)
            return -1;
    }
    return 0;
}

int ai_tensor_device_enable(uint32_t admission_mask, uint32_t admission_limit)
{
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_ADMISSION_MASK, admission_mask);
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_ADMISSION_LIMIT, admission_limit);
    mmio_fence();
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_CONTROL,
                 FRAMEBUFFER_TENSOR_PROD_ENABLE);
    mmio_fence();
    return (mmio_read32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_CONTROL) &
            FRAMEBUFFER_TENSOR_PROD_ENABLE) != 0U ? 0 : -1;
}

void ai_tensor_device_disable(void)
{
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_CONTROL, 0U);
    mmio_fence();
}

uint32_t ai_tensor_device_read_counter(AiTensorDeviceCounter counter)
{
    static const uint32_t offsets[AI_TENSOR_COUNTER_COUNT] = {
        FRAMEBUFFER_TENSOR_DMA_OUTSTANDING, FRAMEBUFFER_TENSOR_DMA_OUTSTANDING_MAX,
        FRAMEBUFFER_TENSOR_DMA_STARVATION, FRAMEBUFFER_TENSOR_DMA_AW_STALL,
        FRAMEBUFFER_TENSOR_DMA_W_STALL, FRAMEBUFFER_TENSOR_DMA_W_TRANSFER,
        FRAMEBUFFER_TENSOR_DMA_B_WAIT, FRAMEBUFFER_TENSOR_DMA_BURSTS,
        FRAMEBUFFER_TENSOR_DMA_COMPLETED, FRAMEBUFFER_TENSOR_DMA_RESP_ERRORS,
        FRAMEBUFFER_TENSOR_PROD_ERROR_CODE, FRAMEBUFFER_TENSOR_PROD_FRAME,
        FRAMEBUFFER_TENSOR_PROD_VERSION, FRAMEBUFFER_TENSOR_PROD_OVERFLOW
    };
    if ((uint32_t)counter >= AI_TENSOR_COUNTER_COUNT)
        return 0U;
    return mmio_read32(FRAMEBUFFER_BASE + offsets[counter]);
}
