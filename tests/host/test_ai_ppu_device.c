/* Compare complete CSR/barrier transcripts against frozen R1a drivers. */
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include "platform/platform.h"
#include "ai/postprocess/ai_ppu_publication.h"
#include "ai/postprocess/ai_ppu_queue.h"
#include "drivers/ppu/ai_ppu_device.h"

static uint32_t regs[256], selected, allocated[6], hw_generation[6], masks[6];
static unsigned ignore_allocation, wrong_generation, reject_enable;
static const uintptr_t bases[6] = {0x32000000, 0x32100000, 0x32400000,
                                   0x32500000, 0x32800000, 0x32900000};

uint32_t mmio_read32(uintptr_t address)
{
    assert(address >= POSTPROCESS_DIAG_BASE && address < POSTPROCESS_DIAG_BASE + sizeof(regs));
    unsigned offset = (unsigned)(address - POSTPROCESS_DIAG_BASE);
    uint32_t value;
    if (offset == 0x1b4) value = allocated[selected];
    else if (offset == 0x1bc) value = hw_generation[selected];
    else if (offset == 0x1b8) value = masks[selected] << 8;
    else value = regs[offset / 4];
    printf("R %03x %08x\n", offset, value);
    return value;
}
void mmio_write32(uintptr_t address, uint32_t value)
{
    assert(address >= POSTPROCESS_DIAG_BASE && address < POSTPROCESS_DIAG_BASE + sizeof(regs));
    unsigned offset = (unsigned)(address - POSTPROCESS_DIAG_BASE);
    printf("W %03x %08x\n", offset, value);
    regs[offset / 4] = value;
    if (offset == 0x200 && reject_enable) regs[offset / 4] = 0;
    if (offset == 0x1a8) { assert(value < 6); selected = value; }
    if (offset == 0x1b0) {
        if (value == 1 && !ignore_allocation) {
            allocated[selected] = 1;
            hw_generation[selected] = regs[0x1ac / 4] + wrong_generation;
            masks[selected] = 0;
        }
        if (value & 0x3f00) masks[selected] |= (value >> 8) & 63;
        if (value == 4) allocated[selected] |= 4;
        if (value == 2) allocated[selected] = 0;
    }
}
void mmio_fence(void) { puts("F"); }
void yolo32_ppu_io_barrier(void)
{
    puts("B");
    assert(ai_ppu_publication_available());
}
static void reset(void)
{
    memset(regs, 0, sizeof(regs));
    memset(allocated, 0, sizeof(allocated));
    memset(hw_generation, 0, sizeof(hw_generation));
    memset(masks, 0, sizeof(masks));
    selected = ignore_allocation = wrong_generation = reject_enable = 0;
    regs[0x100 / 4] = 0x50505531;
    regs[0x1a0 / 4] = 0x50505532;
    regs[0x238 / 4] = 0x50505232;
}
static void check(const char *event, int actual, int expected)
{
    printf("CHECK %s %d\n", event, actual);
    assert(actual == expected);
}
static AiHeadSlotDescriptor descriptor(uintptr_t base)
{
    AiHeadSlotDescriptor d = {0};
    d.base_addr = base; d.stream_id = 15;
    d.frame_id = UINT64_C(0x1234567889abcdef); d.version = UINT32_MAX;
    for (unsigned i = 0; i < 3; ++i) {
        d.class_addr[i] = base + 0x1000 * i;
        d.dfl_addr[i] = base + 0x10000 + 0x2000 * i;
    }
    return d;
}
static void receipt_case(uintptr_t base)
{
    AiPpuDeviceReceipt r;
#ifdef R1B_CURRENT
    ai_ppu_device_publication_receipt(&r);
    int valid = ai_ppu_device_receipt_matches(base, &r);
#else
    r.status = mmio_read32(POSTPROCESS_DIAG_BASE + 0x1b4);
    r.generation = mmio_read32(POSTPROCESS_DIAG_BASE + 0x1bc);
    r.masks = mmio_read32(POSTPROCESS_DIAG_BASE + 0x1b8);
    int valid = (r.status & 5U) == 1U && ai_ppu_publication_generation(base) == r.generation;
#endif
    printf("RECEIPT status=%x generation=%x masks=%x valid=%d\n", r.status, r.generation, r.masks, valid);
}
static void primitives(void)
{
    static const unsigned offsets[9] = {0x124, 0x138, 0x13c, 0x140, 0x144, 0x0c, 0x28, 0x2c, 0x30};
    for (unsigned i = 0; i < 9; ++i) regs[offsets[i] / 4] = 100 + i;
    regs[0x11c / 4] = 15; regs[0x148 / 4] = 13;
#ifdef R1B_CURRENT
    assert(ai_ppu_device_available());
    assert(ai_ppu_device_status() == 15);
    assert(ai_ppu_device_reader_state() == 13);
    ai_ppu_device_live_configure();
#else
    assert(mmio_read32(POSTPROCESS_DIAG_BASE + 0x100) == 0x50505531);
    assert(mmio_read32(POSTPROCESS_DIAG_BASE + 0x11c) == 15);
    assert(mmio_read32(POSTPROCESS_DIAG_BASE + 0x148) == 13);
    mmio_write32(POSTPROCESS_DIAG_BASE + 0x148, 1);
    mmio_write32(POSTPROCESS_DIAG_BASE + 0x24c, 0);
#endif
    for (unsigned i = 0; i < 9; ++i) {
#ifdef R1B_CURRENT
        assert(ai_ppu_device_read_counter((AiPpuDeviceCounter)i) == 100 + i);
#else
        assert(mmio_read32(POSTPROCESS_DIAG_BASE + offsets[i]) == 100 + i);
#endif
    }
    regs[0x128 / 4] = 0x00200010;
    regs[0x12c / 4] = 0x00400030;
    regs[0x130 / 4] = 0x00051234;
    AiPpuDeviceDetection d;
#ifdef R1B_CURRENT
    ai_ppu_device_read_detection(3, &d);
#else
    mmio_write32(POSTPROCESS_DIAG_BASE + 0x120, 3);
    d.xy0 = mmio_read32(POSTPROCESS_DIAG_BASE + 0x128);
    d.xy1 = mmio_read32(POSTPROCESS_DIAG_BASE + 0x12c);
    d.score_class = mmio_read32(POSTPROCESS_DIAG_BASE + 0x130);
#endif
    assert(d.xy0 == 0x00200010 && d.xy1 == 0x00400030 && d.score_class == 0x00051234);
    AiHeadSlotDescriptor head = descriptor(bases[4]);
    for (int published = -1; published <= 1; ++published) {
#ifdef R1B_CURRENT
        ai_ppu_device_start(head.class_addr, head.dfl_addr, published);
#else
        for (unsigned i = 0; i < 3; ++i) mmio_write32(POSTPROCESS_DIAG_BASE + 0x104 + 4 * i, (uint32_t)head.class_addr[i]);
        for (unsigned i = 0; i < 3; ++i) mmio_write32(POSTPROCESS_DIAG_BASE + 0x110 + 4 * i, (uint32_t)head.dfl_addr[i]);
        mmio_write32(POSTPROCESS_DIAG_BASE + 0x100, published > 0 ? 0x101 : 1);
#endif
    }
}
int main(void)
{
    reset(); regs[0x1a0 / 4] = 0;
    check("absent_begin", ai_ppu_publication_begin(bases[0]), 0);
    check("absent_invalid_select", ai_ppu_publication_select(0x32a00000), 0);
    ai_ppu_publication_publish(bases[0], 63); ai_ppu_publication_abort(bases[0]);
    reset();
    check("invalid_begin", ai_ppu_publication_begin(0x32a00000), -1);
    check("invalid_select", ai_ppu_publication_select(0x32a00000), -1);
    assert(ai_ppu_publication_generation(0x32a00000) == 0);
    for (unsigned bank = 0; bank < 6; ++bank) {
        hw_generation[bank] = 7 + bank;
        check("begin", ai_ppu_publication_begin(bases[bank]), 1);
        check("busy_begin", ai_ppu_publication_begin(bases[bank]), -1);
        assert(ai_ppu_publication_generation(bases[bank]) == 8 + bank);
        check("alias_select", ai_ppu_publication_select(bases[bank] | UINT32_C(0x80000000)), 1);
        ai_ppu_publication_publish(bases[bank], 0);
        ai_ppu_publication_publish(bases[bank], 1);
        ai_ppu_publication_publish(bases[bank], UINT32_MAX);
        assert(masks[bank] == 63); receipt_case(bases[bank]);
        hw_generation[bank]++; receipt_case(bases[bank]); hw_generation[bank]--;
        allocated[bank] |= 4; receipt_case(bases[bank]);
        allocated[bank] |= 8; ai_ppu_publication_abort(bases[bank]);
        assert(allocated[bank] & 1); /* Busy clean retains allocation. */
        allocated[bank] &= ~8U; ai_ppu_publication_abort(bases[bank]);
        assert(allocated[bank] == 0);
        ai_ppu_publication_abort(bases[bank]);
    }
    reset(); ignore_allocation = 1;
    check("missing_allocation_ack", ai_ppu_publication_begin(bases[0]), -1);
    reset(); wrong_generation = 1;
    check("wrong_generation_ack", ai_ppu_publication_begin(bases[1]), -1);
    reset(); hw_generation[2] = UINT32_MAX;
    check("generation_wrap", ai_ppu_publication_begin(bases[2]), 1);
    assert(ai_ppu_publication_generation(bases[2]) == 0); receipt_case(bases[2]);
    reset(); regs[0x238 / 4] = 0;
    check("queue_absent", ai_ppu_queue_init(), 0);
    check("inactive_null_submit", ai_ppu_queue_submit(NULL), 0);
    check("inactive_null_peek", ai_ppu_queue_peek(NULL), 0);
    ai_ppu_queue_expect(5, UINT64_C(0x123456789), 9);
    reset(); reject_enable = 1; check("enable_rejected", ai_ppu_queue_init(), 0);
    reset(); check("queue_init", ai_ppu_queue_init(), 1); assert(ai_ppu_queue_active());
    check("not_ready_null_submit", ai_ppu_queue_submit(NULL), 0);
    AiPpuQueueResult r, before; memset(&r, 0xa5, sizeof(r)); before = r;
    check("empty_peek", ai_ppu_queue_peek(&r), 0); assert(!memcmp(&r, &before, sizeof(r)));
    regs[0x208 / 4] = 32;
    for (unsigned bank = 0; bank < 6; ++bank) {
        AiHeadSlotDescriptor d = descriptor(bases[bank] | UINT32_C(0x80000000));
        check("submit", ai_ppu_queue_submit(&d), 1);
        assert(regs[0x210 / 4] == 0x89abcdef && regs[0x214 / 4] == 0x12345678);
    }
    AiHeadSlotDescriptor d = descriptor(0x32a00000);
    check("invalid_submit", ai_ppu_queue_submit(&d), -1);
    ai_ppu_queue_expect(6, UINT64_C(0xabcdef0156789abc), UINT32_MAX);
    regs[0x240 / 4] = 1; regs[0x250 / 4] = 5; regs[0x268 / 4] = 42;
    regs[0x254 / 4] = 63 | (15 << 10) | (15 << 14);
    regs[0x258 / 4] = 0x89abcdef; regs[0x25c / 4] = 0x12345678;
    regs[0x260 / 4] = UINT32_MAX; regs[0x264 / 4] = 1000;
    for (unsigned repeat = 0; repeat < 2; ++repeat) {
        check("peek", ai_ppu_queue_peek(&r), 1);
        assert(r.bank == 5 && r.generation == 42 && r.stream == 15 && r.count == 63 && r.status == 15);
        assert(r.frame == UINT64_C(0x1234567889abcdef) && r.version == UINT32_MAX && r.cycles == 1000);
    }
    ai_ppu_queue_pop(); ai_ppu_queue_pop();
    reset(); primitives();
    reset(); check("direct_device_init", ai_ppu_queue_init(), 1);
#ifdef R1B_CURRENT
    check("direct_device_not_ready", ai_ppu_device_queue_submit(NULL), 0);
#else
    check("direct_device_not_ready", ai_ppu_queue_submit(NULL), 0);
#endif
    regs[0x208 / 4] = 32;
    d = descriptor(bases[2]);
#ifdef R1B_CURRENT
    AiPpuDeviceDescriptor direct = {.base_addr = d.base_addr, .stream = d.stream_id,
        .frame = d.frame_id, .version = d.version};
    for (unsigned i = 0; i < 3; ++i) {
        direct.class_addr[i] = d.class_addr[i]; direct.dfl_addr[i] = d.dfl_addr[i];
    }
    check("direct_device_submit", ai_ppu_device_queue_submit(&direct), 1);
#else
    check("direct_device_submit", ai_ppu_queue_submit(&d), 1);
#endif
    puts("PPU_DEVICE_WORKLOAD=PASS banks=6 aliases=6 generation_wrap busy_clean_retention queue_metadata receipt result primitives");
    return 0;
}
