#include "drivers/ppu/ai_ppu_device.h"
#include "mmio.h"
#include "platform/platform.h"

static int enabled;
static void put(uint32_t offset, uint32_t value)
{
    mmio_write32(POSTPROCESS_DIAG_BASE + offset, value);
}
static uint32_t get(uint32_t offset)
{
    return mmio_read32(POSTPROCESS_DIAG_BASE + offset);
}

int ai_ppu_device_queue_init(void)
{
    enabled = 0;
    if (get(0x238) != UINT32_C(0x50505232)) return 0;
    put(0x200, 1);
    enabled = (get(0x200) & 1U) != 0;
    return enabled;
}

int ai_ppu_device_queue_active(void) { return enabled; }

static void metadata(uint32_t stream, uint64_t frame, uint32_t version)
{
    put(0x20c, stream);
    put(0x210, (uint32_t)frame);
    put(0x214, (uint32_t)(frame >> 32));
    put(0x218, version);
}

void ai_ppu_device_queue_expect(uint32_t stream, uint64_t frame, uint32_t version)
{
    if (enabled) {
        metadata(stream, frame, version);
        put(0x234, 1);
    }
}

int ai_ppu_device_queue_ready(void) { return enabled && (get(0x208) & 32U); }

int ai_ppu_device_queue_submit(const AiPpuDeviceDescriptor *d)
{
    if (!ai_ppu_device_queue_ready()) return 0;
    return ai_ppu_device_queue_submit_ready(d);
}

int ai_ppu_device_queue_submit_ready(const AiPpuDeviceDescriptor *d)
{
    if (ai_ppu_device_publication_select(d->base_addr) <= 0) return -1;
    for (uint32_t i = 0; i < 3; i++) {
        put(0x104 + 4 * i, (uint32_t)d->class_addr[i]);
        put(0x110 + 4 * i, (uint32_t)d->dfl_addr[i]);
    }
    metadata(d->stream, d->frame, d->version);
    put(0x21c, 0);
    mmio_fence();
    put(0x204, 1);
    return 1;
}

int ai_ppu_device_queue_peek(AiPpuDeviceResult *r)
{
    if (!enabled || !(get(0x240) & 1U)) return 0;
    uint32_t packed = get(0x254);
    r->bank = get(0x250);
    r->generation = get(0x268);
    r->count = packed & 63U;
    r->stream = (packed >> 10) & 15U;
    r->status = (packed >> 14) & 15U;
    r->frame = get(0x258);
    r->frame |= (uint64_t)get(0x25c) << 32;
    r->version = get(0x260);
    r->cycles = get(0x264);
    return 1;
}

void ai_ppu_device_queue_pop(void) { put(0x24c, 1); }

int ai_ppu_device_available(void) { return get(0x100) == UINT32_C(0x50505531); }
uint32_t ai_ppu_device_status(void) { return get(0x11c); }
uint32_t ai_ppu_device_reader_state(void) { return get(0x148); }

void ai_ppu_device_live_configure(void)
{
    put(0x148, 1);
    put(0x24c, 0);
}

void ai_ppu_device_start(const uintptr_t class_addr[3], const uintptr_t dfl_addr[3],
                         int publication_selected)
{
    /* Single-command order differs from queued submit: keep all class writes
     * before all DFL writes and let the caller supply its cache proof. */
    for (uint32_t i = 0; i < 3; ++i) put(0x104 + 4 * i, (uint32_t)class_addr[i]);
    for (uint32_t i = 0; i < 3; ++i) put(0x110 + 4 * i, (uint32_t)dfl_addr[i]);
    put(0x100, publication_selected > 0 ? 0x101U : 1U);
}

uint32_t ai_ppu_device_read_counter(AiPpuDeviceCounter counter)
{
    static const uint32_t offsets[AI_PPU_COUNTER_COUNT] = {
        0x124, 0x138, 0x13c, 0x140, 0x144, 0x0c, 0x28, 0x2c, 0x30
    };
    if ((uint32_t)counter >= AI_PPU_COUNTER_COUNT) return 0;
    return get(offsets[counter]);
}

void ai_ppu_device_read_detection(uint32_t index, AiPpuDeviceDetection *detection)
{
    put(0x120, index);
    detection->xy0 = get(0x128);
    detection->xy1 = get(0x12c);
    detection->score_class = get(0x130);
}
