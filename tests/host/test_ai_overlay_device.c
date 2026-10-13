#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include "ai/postprocess/ai_overlay.h"
#include "ai/postprocess/ai_display_map.h"
#include "platform/platform.h"

static uint64_t cycle, cycle_step;
static uint32_t busy_reads, busy_after_commit, sticky_busy, commits, writes;
static uint32_t stream, count, selected, label_words[8][4];
static uint64_t boxes[8];
uint64_t read_cycle(void)
{
    cycle += cycle_step;
    printf("CLOCK %llu\n", (unsigned long long)cycle);
    return cycle;
}
uint32_t mmio_read32(uintptr_t address)
{
    assert(address == FRAMEBUFFER_BASE + FRAMEBUFFER_OVERLAY_CONTROL);
    uint32_t value = sticky_busy || busy_reads ? FRAMEBUFFER_OVERLAY_CONTROL_BUSY : 0;
    if (busy_reads) --busy_reads;
    printf("R %03lx %x\n", (unsigned long)(address - FRAMEBUFFER_BASE), value);
    return value;
}
void mmio_write32(uintptr_t address, uint32_t value)
{
    uint32_t offset = (uint32_t)(address - FRAMEBUFFER_BASE);
    printf("W %03x %08x\n", offset, value); ++writes;
    switch (offset) {
    case FRAMEBUFFER_OVERLAY_STREAM: stream = value; break;
    case FRAMEBUFFER_OVERLAY_COUNT: assert(value <= 8); count = value; break;
    case FRAMEBUFFER_OVERLAY_BOX_INDEX: assert(value < 8); selected = value; break;
    case FRAMEBUFFER_OVERLAY_BOX_XY0: boxes[selected] = value; break;
    case FRAMEBUFFER_OVERLAY_BOX_XY1: boxes[selected] |= (uint64_t)value << 32; break;
    case FRAMEBUFFER_OVERLAY_LABEL0: case FRAMEBUFFER_OVERLAY_LABEL1:
    case FRAMEBUFFER_OVERLAY_LABEL2: case FRAMEBUFFER_OVERLAY_LABEL3:
        label_words[selected][(offset - FRAMEBUFFER_OVERLAY_LABEL0) / 4] = value; break;
    case FRAMEBUFFER_OVERLAY_CONTROL:
        assert(value == FRAMEBUFFER_OVERLAY_CONTROL_COMMIT);
        ++commits; busy_reads = busy_after_commit; break;
    default: assert(!"unexpected overlay CSR");
    }
}
void mmio_fence(void) { assert(!"overlay must not add a fence"); }
static void reset(void)
{
    cycle = 0; cycle_step = 1;
    busy_reads = busy_after_commit = sticky_busy = commits = writes = stream = count = selected = 0;
    memset(boxes, 0, sizeof(boxes)); memset(label_words, 0, sizeof(label_words));
}
static AiDetectionResult result(uint32_t channel, uint32_t detections)
{
    AiDetectionResult r = {0};
    r.stream_id = channel; r.count = detections; r.frame_id = UINT64_C(0x100000065);
    for (unsigned i = 0; i < AI_MAX_DETECTIONS; ++i) {
        r.detections[i] = (AiDetection){.x_min = -1, .y_min = -100,
            .x_max = 32767, .y_max = 32767, .score_q15 = 32767, .class_id = 9};
    }
    return r;
}
static void check(const char *name, int actual, int expected)
{
    printf("CHECK %s %d\n", name, actual); assert(actual == expected);
}
int main(void)
{
    reset();
    check("null", ai_overlay_try_submit(NULL), -1); assert(writes == 0);
    AiDetectionResult r = result(16, 1);
    check("bad_stream", ai_overlay_try_submit(&r), -1); assert(writes == 0);
    r = result(0, AI_MAX_DETECTIONS + 1);
    check("bad_count", ai_overlay_try_submit(&r), -1); assert(writes == 0);
    r.flags = AI_RESULT_HARDWARE_OVERLAY | AI_RESULT_METADATA_ONLY;
    r.stream_id = UINT32_MAX;
    check("hardware_metadata_bypass", ai_overlay_try_submit(&r), 1); assert(writes == 0);
    for (unsigned ch = 0; ch < 16; ++ch) {
        reset(); r = result(ch, AI_MAX_DETECTIONS);
        sticky_busy = 1;
        check("busy", ai_overlay_try_submit(&r), 0); assert(writes == 0);
        sticky_busy = 0;
        check("retry", ai_overlay_try_submit(&r), 1);
        assert(commits == 1 && stream == ch && count == 8);
        uint32_t x = (ch & 3U) * 480 + 60, y = (ch >> 2) * 270;
        assert((boxes[0] & 2047) == x && ((boxes[0] >> 11) & 2047) == y);
        assert(((boxes[0] >> 22) & 2047) == x + 360 && ((boxes[0] >> 33) & 2047) == y + 270);
        /* Original 16-byte truncation: the trailing percent sign is omitted. */
        assert(!memcmp(label_words[0], "traffic light 10", 16));
        r.count = 0;
        check("clear", ai_overlay_try_submit(&r), 1);
        assert(commits == 2 && count == 0);
    }
    for (unsigned score = 0; score < 6; ++score) {
        static const uint16_t values[] = {0, 3000, 3277, 16384, 32767, UINT16_MAX};
        reset(); r = result(5, 1);
        r.detections[0].score_q15 = values[score];
        r.detections[0].class_id = score & 1 ? 255 : 0;
        r.detections[0].x_min = 123; r.detections[0].x_max = 124;
        r.detections[0].y_min = 200; r.detections[0].y_max = 201;
        check("label_rounding_unknown_class", ai_overlay_try_submit(&r), 1);
        assert(commits == 1 && count == 1);
    }
    reset(); busy_reads = 3; busy_after_commit = 2;
    check("pattern_retry", ai_overlay_draw_test_pattern(), 0); assert(commits == 16);
    reset(); sticky_busy = 1; cycle_step = SOC_CLOCK_HZ / 10 + 1;
    check("pattern_busy_timeout", ai_overlay_draw_test_pattern(), -2); assert(commits == 0);
    reset(); cycle_step = SOC_CLOCK_HZ / 10 + 1;
    check("pattern_late_success_timeout", ai_overlay_draw_test_pattern(), -2); assert(commits == 1);
    puts("OVERLAY_WORKLOAD=PASS streams=16 max_boxes busy_retry clear labels hardware_bypass pattern_timeout");
    return 0;
}
