#include <assert.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include "drivers/tensor/ai_tensor_device.h"
#include "ai/runtime/ai_tensor_slot_pool.h"
#include "platform/platform.h"
#include "mmio.h"

#define STREAM_MMIO_TIMEOUT (SOC_CLOCK_HZ / UINT64_C(10))
#define STREAM_META_SETTLE (SOC_CLOCK_HZ / UINT64_C(100000))
static struct { struct { uint32_t enabled; } status; } runtime;
#include "tensor-device-reference.c.inc"

enum Mode {
    STABLE, VERSION_CHANGES_ONCE, VERSION_NEVER_STABLE, VERSION_ZERO,
    BAD_STREAM, BAD_ADDRESS, BAD_BYTES, BAD_STATE, READY_GONE,
    RELEASE_DELAYED, RELEASE_BUSY_THEN_CLEAR, RELEASE_BUSY_TIMEOUT,
    RELEASE_ACK_TIMEOUT, ENABLE_REJECTED
};
static struct {
    enum Mode mode;
    uint32_t selected, ready, error, writing, control, release_mask;
    uint32_t version, frame, version_reads, control_reads;
    uint32_t admission_mask, admission_limit;
    uint64_t cycle, step, index_cycle, command_cycle;
    uint64_t hash, reads, writes, fences, clocks;
    uint64_t first_metadata_cycle;
    unsigned armed;
} device;

static void record(unsigned kind, uint64_t address, uint64_t value)
{
    uint64_t values[4] = {kind, address, value, device.cycle};
    for (unsigned i = 0; i < 4; ++i)
        for (unsigned byte = 0; byte < 8; ++byte) {
            device.hash ^= (values[i] >> (byte * 8)) & 255U;
            device.hash *= UINT64_C(1099511628211);
        }
}

uint64_t read_cycle(void)
{
    device.cycle += device.step;
    device.clocks++;
    record('C', 0, device.cycle);
    return device.cycle;
}

void mmio_fence(void)
{
    device.fences++;
    record('F', 0, 0);
}

uint32_t mmio_read32(uintptr_t address)
{
    assert(address >= FRAMEBUFFER_BASE);
    uint32_t offset = (uint32_t)(address - FRAMEBUFFER_BASE), value = 0;
    if (device.armed && device.mode != RELEASE_ACK_TIMEOUT &&
        device.cycle - device.command_cycle >= 3 * device.step) {
        device.ready &= ~device.release_mask;
        device.error &= ~device.release_mask;
        device.control &= ~FRAMEBUFFER_TENSOR_PROD_RELEASE_GO;
    }
    if (offset == FRAMEBUFFER_TENSOR_PROD_CONTROL) {
        device.control_reads++;
        if (device.mode == RELEASE_BUSY_THEN_CLEAR && !device.armed && device.control_reads == 3)
            device.control &= ~FRAMEBUFFER_TENSOR_PROD_RELEASE_GO;
        value = device.control;
    } else if (offset == FRAMEBUFFER_TENSOR_PROD_READY) {
        value = device.mode == READY_GONE ? 0 : device.ready;
    } else if (offset == FRAMEBUFFER_TENSOR_PROD_ERROR) value = device.error;
    else if (offset == FRAMEBUFFER_TENSOR_PROD_WRITING) value = device.writing;
    else if (offset == FRAMEBUFFER_TENSOR_PROD_VERSION) {
        if (!device.first_metadata_cycle) device.first_metadata_cycle = device.cycle;
        assert(device.cycle - device.index_cycle >= STREAM_META_SETTLE);
        device.version_reads++;
        if (device.mode == VERSION_CHANGES_ONCE && device.version_reads == 2) {
            device.version++; device.frame++;
        }
        value = device.mode == VERSION_ZERO ? 0 :
                device.mode == VERSION_NEVER_STABLE ? device.version_reads : device.version;
    } else if (offset == FRAMEBUFFER_TENSOR_PROD_TIME_LO) value = 0x89abcdef;
    else if (offset == FRAMEBUFFER_TENSOR_PROD_TIME_HI) value = 0x01234567;
    else if (offset == FRAMEBUFFER_TENSOR_PROD_FRAME) value = device.frame;
    else if (offset == FRAMEBUFFER_TENSOR_PROD_BYTES)
        value = device.mode == BAD_BYTES ? TENSOR_MEMBER_BYTES - 1 : TENSOR_MEMBER_BYTES;
    else if (offset == FRAMEBUFFER_TENSOR_PROD_STREAM)
        value = device.selected % VIDEO_CHANNEL_COUNT + (device.mode == BAD_STREAM);
    else if (offset == FRAMEBUFFER_TENSOR_PROD_ADDR)
        value = legacy_slot_address(device.selected) ^ (device.mode == BAD_ADDRESS ? 64 : 0);
    else if (offset == FRAMEBUFFER_TENSOR_PROD_STATE)
        value = device.mode == BAD_STATE ? AI_TENSOR_SLOT_ERROR : AI_TENSOR_SLOT_READY;
    else if (offset == FRAMEBUFFER_TENSOR_PROD_ERROR_CODE) value = 4;
    else if (offset == FRAMEBUFFER_TENSOR_PROD_OVERFLOW) value = 17;
    else if (offset >= FRAMEBUFFER_TENSOR_DMA_OUTSTANDING &&
             offset <= FRAMEBUFFER_TENSOR_DMA_RESP_ERRORS) value = offset;
    else assert(!"unrecognized CSR read");
    device.reads++;
    record('R', address, value);
    return value;
}

void mmio_write32(uintptr_t address, uint32_t value)
{
    device.writes++;
    record('W', address, value);
    switch (address - FRAMEBUFFER_BASE) {
    case FRAMEBUFFER_TENSOR_PROD_INDEX:
        assert(value < 32); device.selected = value; device.index_cycle = device.cycle; break;
    case FRAMEBUFFER_TENSOR_PROD_RELEASE: device.release_mask = value; break;
    case FRAMEBUFFER_TENSOR_PROD_CONTROL:
        device.control = device.mode == ENABLE_REJECTED ? 0 : value;
        if (value & FRAMEBUFFER_TENSOR_PROD_RELEASE_GO) {
            device.armed = 1; device.command_cycle = device.cycle;
        }
        break;
    case FRAMEBUFFER_TENSOR_PROD_ADMISSION_MASK: device.admission_mask = value; break;
    case FRAMEBUFFER_TENSOR_PROD_ADMISSION_LIMIT: device.admission_limit = value; break;
    default: assert(!"unrecognized CSR write");
    }
}

static void reset(enum Mode mode, uint32_t slot)
{
    memset(&device, 0, sizeof(device));
    device.mode = mode;
    device.selected = slot;
    device.ready = device.error = UINT32_C(1) << slot;
    device.writing = UINT32_C(0x40000000);
    device.version = 19;
    device.frame = UINT32_C(0xf0000100);
    device.step = mode == STABLE || mode == VERSION_CHANGES_ONCE ? 1 : 1000000;
    device.hash = UINT64_C(14695981039346656037);
    if (mode == RELEASE_BUSY_THEN_CLEAR || mode == RELEASE_BUSY_TIMEOUT)
        device.control = FRAMEBUFFER_TENSOR_PROD_RELEASE_GO;
}

typedef struct { uint64_t hash, reads, writes, fences, clocks, cycles; } Trace;
static Trace snapshot(void)
{
    return (Trace){device.hash, device.reads, device.writes, device.fences, device.clocks, device.cycle};
}
static void compare(Trace old)
{
    Trace current = snapshot();
    assert(current.hash == old.hash && current.reads == old.reads &&
           current.writes == old.writes && current.fences == old.fences &&
           current.clocks == old.clocks && current.cycles == old.cycles);
}

static void read_case(enum Mode mode, uint32_t slot)
{
    AiTensorSlot old;
    AiTensorDeviceDescriptor descriptor, before;
    memset(&old, 0xa5, sizeof(old));
    memset(&descriptor, 0xa5, sizeof(descriptor)); before = descriptor;
    reset(mode, slot);
    int old_status = legacy_read_slot(slot, &old);
    Trace expected = snapshot();
    reset(mode, slot);
    int status = ai_tensor_device_read_slot(slot, &descriptor);
    assert(status == old_status);
    compare(expected);
    if (status == 0) {
        assert(descriptor.tensor_addr == old.tensor_addr && descriptor.stream_id == old.stream_id);
        assert(descriptor.frame_id == old.frame_id && descriptor.timestamp == old.timestamp);
        assert(descriptor.version == old.version && descriptor.byte_count == old.byte_count);
        assert(descriptor.error_code == old.error_code && descriptor.state == old.state);
        assert(descriptor.timestamp == UINT64_C(0x0123456789abcdef));
        assert(device.first_metadata_cycle - device.index_cycle >= STREAM_META_SETTLE);
        assert(device.fences == 1 && device.writes == 1);
    } else {
        assert(!memcmp(&descriptor, &before, sizeof(descriptor)));
        assert(device.cycle > STREAM_MMIO_TIMEOUT);
    }
}

static void release_case(enum Mode mode, uint32_t enabled)
{
    reset(mode, 31); runtime.status.enabled = enabled;
    int old_status = legacy_release(31);
    Trace expected = snapshot();
    reset(mode, 31);
    int status = ai_tensor_device_release(31, enabled);
    assert(status == old_status);
    compare(expected);
    if (mode == RELEASE_BUSY_TIMEOUT) assert(status == -1 && device.writes == 0);
    else {
        assert(device.release_mask == UINT32_C(0x80000000) && device.writes == 2 && device.fences == 2);
        if (mode == RELEASE_ACK_TIMEOUT) assert(status == -1 && device.ready && device.error);
        else assert(status == 0 && !device.ready && !device.error &&
                    device.control == (enabled ? FRAMEBUFFER_TENSOR_PROD_ENABLE : 0));
    }
}

static void enable_case(enum Mode mode)
{
    reset(mode, 0);
    int old_status = legacy_enable(); Trace expected = snapshot();
    reset(mode, 0);
    int status = ai_tensor_device_enable(CAMERA_PRESENT_MASK, TENSOR_PRODUCTION_ADMISSION_LIMIT);
    assert(status == old_status); compare(expected);
    assert(device.admission_mask == CAMERA_PRESENT_MASK && device.admission_limit == TENSOR_PRODUCTION_ADMISSION_LIMIT);
    assert(device.writes == 3 && device.fences == 2);
}

static void repeated_release_case(uint32_t enabled)
{
    reset(RELEASE_DELAYED, 31); runtime.status.enabled = enabled;
    assert(legacy_release(31) == 0);
    assert(legacy_release(31) == 0);
    Trace expected = snapshot();
    reset(RELEASE_DELAYED, 31);
    assert(ai_tensor_device_release(31, enabled) == 0);
    assert(ai_tensor_device_release(31, enabled) == 0);
    compare(expected);
    assert(device.writes == 4 && device.fences == 4);
    assert(!device.ready && !device.error);
}

int main(void)
{
    for (uint32_t slot = 0; slot < 32; ++slot) read_case(STABLE, slot);
    for (enum Mode mode = VERSION_CHANGES_ONCE; mode <= READY_GONE; ++mode) read_case(mode, 17);
    for (enum Mode mode = RELEASE_DELAYED; mode <= RELEASE_ACK_TIMEOUT; ++mode) {
        release_case(mode, 0); release_case(mode, 1);
    }
    repeated_release_case(0); repeated_release_case(1);
    enable_case(STABLE); enable_case(ENABLE_REJECTED);
    reset(STABLE, 0); legacy_disable(); Trace disabled = snapshot();
    reset(STABLE, 0); ai_tensor_device_disable(); compare(disabled);
    assert(device.writes == 1 && device.fences == 1 && !device.control);
    reset(STABLE, 0);
    assert(ai_tensor_device_read_slot(32, NULL) == -1);
    AiTensorDeviceDescriptor invalid;
    assert(ai_tensor_device_read_slot(32, &invalid) == -1);
    assert(ai_tensor_device_read_slot(0, NULL) == -1);
    assert(ai_tensor_device_release(32, 1) == -1);
    assert(ai_tensor_device_select_slot(32) == -1);
    assert(device.reads == 0 && device.writes == 0 && device.clocks == 0);
    static const uint32_t offsets[AI_TENSOR_COUNTER_COUNT] = {
        0x300, 0x304, 0x308, 0x30c, 0x310, 0x314, 0x318, 0x31c, 0x320, 0x324,
        0x340, 0x2e8, 0x330, 0x2f4
    };
    for (unsigned i = 0; i < AI_TENSOR_COUNTER_COUNT; ++i) {
        reset(STABLE, 0); (void)ai_tensor_device_select_slot(0);
        uint32_t actual = ai_tensor_device_read_counter((AiTensorDeviceCounter)i);
        reset(STABLE, 0); (void)ai_tensor_device_select_slot(0);
        assert(actual == mmio_read32(FRAMEBUFFER_BASE + offsets[i]));
    }
    reset(STABLE, 5);
    assert(ai_tensor_device_ready() == (1U << 5));
    assert(ai_tensor_device_error() == (1U << 5));
    assert(ai_tensor_device_writing() == UINT32_C(0x40000000));
    uint64_t reads = device.reads;
    assert(ai_tensor_device_read_counter((AiTensorDeviceCounter)-1) == 0 && device.reads == reads);
    puts("AI_TENSOR_DEVICE=PASS fixed_slots=32 read_scenarios=40 release_scenarios=8 repeated_release_scenarios=2 enable_scenarios=2 R0_MMIO_AND_CLOCK_TRACE=identical");
    return 0;
}
