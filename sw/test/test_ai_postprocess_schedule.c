/* Exercise the actual scheduler with MMIO completion/busy transitions. */
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include "platform.h"
#include "yolov5nu_head_layout.h"
uint64_t test_cycle;
static uint32_t regs[128];
static unsigned launches;
static uint32_t mmio_read32(uintptr_t address)
{
    return regs[(address - POSTPROCESS_DIAG_BASE) / 4];
}
static void mmio_write32(uintptr_t address, uint32_t value)
{
    regs[(address - POSTPROCESS_DIAG_BASE) / 4] = value;
    if (address == POSTPROCESS_DIAG_BASE + 8 && (value & 1)) launches++;
}
static void mmio_fence(void) {}
#include "../src/ai_postprocess_diag.c"
static void reset_test(void)
{
    memset(regs, 0, sizeof(regs));
    command = (AiPostprocessDiagCommand){0};
    bandwidth = (AiPostprocessBandwidthState){0};
    bandwidth.running = bandwidth.waiting = 1;
    bandwidth.result.iterations_requested = 2;
    bandwidth.result.burst_bytes = 64;
    bandwidth.result.expected_crc32 = 123;
    test_cycle = 0;
    launches = 0;
}
static void complete_read(void)
{
    regs[DIAG_COMPLETIONS / 4]++;
    regs[DIAG_CRC32 / 4] = 123;
    regs[DIAG_BYTES_READ / 4] = DIAG_BANDWIDTH_BYTES;
    regs[DIAG_ACTIVE_CYCLES / 4] = 500;
}
int main(void)
{
    AiPostprocessBandwidthResult result = {0};
    assert(YOLOV5NU_HEAD_PAYLOAD_BYTES <= YOLOV5NU_HEAD_SLOT_STRIDE);
    assert(YOLOV5NU_HEAD_POOL_BYTES <= AI_MODEL_OUTPUT_ARENA_BYTES);
    assert(AI_POSTPROCESS_BANDWIDTH_PHYS_BASE >=
           AI_MODEL_OUTPUT0_PHYS_BASE + YOLOV5NU_HEAD_POOL_BYTES);
    assert(AI_POSTPROCESS_BANDWIDTH_PHYS_BASE +
           AI_POSTPROCESS_BANDWIDTH_BYTES <=
           AI_MODEL_OUTPUT0_PHYS_BASE + AI_MODEL_OUTPUT_ARENA_BYTES);
    reset_test();
    assert(ai_postprocess_bandwidth_poll(&result) == 0 && launches == 0);
    test_cycle = SOC_CLOCK_HZ / 1000;
    regs[PPU_STATUS / 4] = PPU_STATUS_BUSY; /* Reader idle, PPU between reads. */
    assert(ai_postprocess_bandwidth_poll(&result) == 0 && launches == 0);
    regs[PPU_STATUS / 4] = 0;
    regs[DIAG_STATUS / 4] = DIAG_STATUS_BUSY;
    assert(ai_postprocess_bandwidth_poll(&result) == 0 && launches == 0);
    regs[DIAG_STATUS / 4] = 0;
    assert(ai_postprocess_bandwidth_poll(&result) == 0 && launches == 1);
    assert(regs[DIAG_BURST_BEATS / 4] == 2);
    complete_read();
    assert(ai_postprocess_bandwidth_poll(&result) == 0);
    assert(ai_postprocess_bandwidth_poll(&result) == 0 && launches == 1);
    test_cycle += SOC_CLOCK_HZ / 1000;
    assert(ai_postprocess_bandwidth_poll(&result) == 0 && launches == 2);
    complete_read();
    assert(ai_postprocess_bandwidth_poll(&result) == 1);
    assert(result.iterations_completed == 2 && result.busy_retries == 2);
    assert(result.active_cycles == 1000 && result.crc_mismatches == 0);
    reset_test();
    regs[PPU_STATUS / 4] = PPU_STATUS_BUSY;
    test_cycle = DIAG_TIMEOUT_CYCLES + 1;
    assert(ai_postprocess_bandwidth_poll(&result) == -6);
    assert(result.timeout_count == 1 && result.iterations_completed == 0);
    assert(result.crc_mismatches == 0 && launches == 0);
    reset_test();
    test_cycle = SOC_CLOCK_HZ / 1000;
    assert(ai_postprocess_bandwidth_poll(&result) == 0 && launches == 1);
    test_cycle += DIAG_TIMEOUT_CYCLES + 1;
    assert(ai_postprocess_bandwidth_poll(&result) == -4);
    assert(result.timeout_count == 1 && result.crc_mismatches == 0);
    assert(result.iterations_completed == 0 && result.bytes_read == 0);
    puts("AI postprocess scheduling PASS");
}
