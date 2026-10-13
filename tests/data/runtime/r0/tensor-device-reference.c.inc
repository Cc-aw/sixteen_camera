/* Frozen R0 Tensor helpers from 0975b01. Only static names and the enable
 * wrapper are adapted for this test; no new device implementation is the oracle.
 * Source file SHA256: af48fa8b847482e102f4102a5abf99637ad7c82876c67357b0756d1f7341d836
 */
static uint32_t legacy_slot_address(uint32_t slot)
{
    uint32_t arena_base = slot < VIDEO_CHANNEL_COUNT ?
                          TENSOR_ARENA0_PHYS_BASE : TENSOR_ARENA1_PHYS_BASE;
    return arena_base + (slot % VIDEO_CHANNEL_COUNT) *
           TENSOR_MEMBER_STRIDE;
}

static uint32_t legacy_ready(void)
{
    return mmio_read32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_READY);
}

static uint32_t legacy_error(void)
{
    return mmio_read32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_ERROR);
}

static int legacy_read_slot(uint32_t slot, AiTensorSlot *metadata)
{
    if (slot >= AI_TENSOR_SLOT_COUNT || metadata == 0)
        return -1;
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_INDEX, slot);
    mmio_fence();
    uint64_t settle_start = read_cycle();
    while (read_cycle() - settle_start < STREAM_META_SETTLE)
        ;
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
            address == legacy_slot_address(slot) &&
            bytes == TENSOR_MEMBER_BYTES &&
            state == AI_TENSOR_SLOT_READY &&
            (legacy_ready() & (UINT32_C(1) << slot)) != 0U) {
            metadata->tensor_addr = address;
            metadata->stream_id = stream;
            metadata->frame_id = frame;
            metadata->timestamp = (uint64_t)time_lo |
                                  ((uint64_t)time_hi << 32);
            metadata->version = version_after;
            metadata->byte_count = bytes;
            metadata->error_code = error_code;
            metadata->owner_worker = AI_TENSOR_SLOT_INVALID;
            metadata->generation = version_after;
            metadata->state = AI_TENSOR_SLOT_READY;
            return 0;
        }
    } while (read_cycle() - start < STREAM_MMIO_TIMEOUT);
    return -1;
}

static int legacy_release(uint32_t slot)
{
    uint32_t bit = UINT32_C(1) << slot;
    uint64_t start = read_cycle();
    while ((mmio_read32(FRAMEBUFFER_BASE +
                        FRAMEBUFFER_TENSOR_PROD_CONTROL) &
            FRAMEBUFFER_TENSOR_PROD_RELEASE_GO) != 0U) {
        if (read_cycle() - start > STREAM_MMIO_TIMEOUT)
            return -1;
    }
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_RELEASE, bit);
    mmio_fence();
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_CONTROL,
                 (runtime.status.enabled != 0U ?
                  FRAMEBUFFER_TENSOR_PROD_ENABLE : 0U) |
                 FRAMEBUFFER_TENSOR_PROD_RELEASE_GO);
    mmio_fence();
    start = read_cycle();
    while (((legacy_ready() | legacy_error()) & bit) != 0U ||
           (mmio_read32(FRAMEBUFFER_BASE +
                        FRAMEBUFFER_TENSOR_PROD_CONTROL) &
            FRAMEBUFFER_TENSOR_PROD_RELEASE_GO) != 0U) {
        if (read_cycle() - start > STREAM_MMIO_TIMEOUT)
            return -1;
    }
    return 0;
}


static int legacy_enable(void)
{
    mmio_write32(FRAMEBUFFER_BASE +
                 FRAMEBUFFER_TENSOR_PROD_ADMISSION_MASK,
                 CAMERA_PRESENT_MASK);
    mmio_write32(FRAMEBUFFER_BASE +
                 FRAMEBUFFER_TENSOR_PROD_ADMISSION_LIMIT,
                 TENSOR_PRODUCTION_ADMISSION_LIMIT);
    mmio_fence();
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_CONTROL,
                 FRAMEBUFFER_TENSOR_PROD_ENABLE);
    mmio_fence();
    if ((mmio_read32(FRAMEBUFFER_BASE +
                     FRAMEBUFFER_TENSOR_PROD_CONTROL) &
         FRAMEBUFFER_TENSOR_PROD_ENABLE) == 0U) {
        return -1;
    }
    return 0;
}

static void legacy_disable(void)
{
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_CONTROL, 0U);
    mmio_fence();
}
