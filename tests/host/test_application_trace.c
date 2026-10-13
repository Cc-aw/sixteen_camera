#include <assert.h>
#include <inttypes.h>
#include <setjmp.h>
#include <stdio.h>
#include <string.h>
#include "ai/runtime/ai_batch_runtime.h"
#include "ai/runtime/rt.h"
#include "diagnostics/runtime_diagnostics.h"
#include "diagnostics/ai_postprocess_diag.h"
#include "platform/platform.h"
#include "platform/tensor_ingress.h"
#include "clock_chip.h"

int test_application_entry(void);
static jmp_buf end_loop;
static const char *scenario, *commands;
static unsigned iteration, read_polls, read_active;
static uint32_t enabled, ready, writing, control, release_mask, index_slot;
static uint32_t admission = 3, jobs;
static uint64_t cycle, cycle_step = 1;

static int is(const char *name) { return strcmp(scenario, name) == 0; }
uint64_t test_app_cycle(void)
{
    cycle += cycle_step;
    printf("CYCLE %" PRIu64 "\n", cycle);
    return cycle;
}
void console_init(void) { puts("CALL console_init"); }
void console_puts(const char *s)
{
    fputs("UART_S ", stdout);
    for (; *s; ++s) printf("%02x", (unsigned char)*s);
    putchar('\n');
}
void console_putc(char c) { printf("UART_C %02x\n", (unsigned char)c); }
void console_put_u32(uint32_t v) { printf("UART_U %" PRIu32 "\n", v); }
void console_put_hex32(uint32_t v) { printf("UART_H32 %08" PRIx32 "\n", v); }
void console_put_hex64(uint64_t v) { printf("UART_H64 %016" PRIx64 "\n", v); }
int console_getc_nonblock(void)
{
    if (!commands[iteration]) longjmp(end_loop, 1);
    unsigned char c = (unsigned char)commands[iteration++];
    printf("INPUT %02x\n", c);
    if (is("write-only")) {
        cycle += SOC_CLOCK_HZ * UINT64_C(11);
        writing = iteration < 3;
    }
    if ((is("tensor-soak") || is("release-timeout") || is("metadata-timeout")) && iteration == 1)
        ready = 1U << 17;
    return c == '.' ? -1 : c;
}
uint32_t mmio_read32(uintptr_t address)
{
    assert(address >= FRAMEBUFFER_BASE);
    uint32_t offset = (uint32_t)(address - FRAMEBUFFER_BASE), value;
    switch (offset) {
    case FRAMEBUFFER_TENSOR_PROD_CONTROL: value = control; break;
    case FRAMEBUFFER_TENSOR_PROD_READY: value = ready; break;
    case FRAMEBUFFER_TENSOR_PROD_WRITING:
        value = writing;
        if (is("startup-stale")) writing = 0;
        break;
    case FRAMEBUFFER_TENSOR_PROD_FRAME: value = 100 + index_slot; break;
    case FRAMEBUFFER_TENSOR_PROD_BYTES: value = is("metadata-timeout") ? 64 : TENSOR_MEMBER_BYTES; break;
    case FRAMEBUFFER_TENSOR_PROD_ADMISSION_LIMIT: value = admission; break;
    default: value = iteration * 100U + offset; break;
    }
    printf("READ %08" PRIxPTR " %08" PRIx32 "\n", address, value);
    return value;
}
void mmio_write32(uintptr_t address, uint32_t value)
{
    printf("WRITE %08" PRIxPTR " %08" PRIx32 "\n", address, value);
    switch (address - FRAMEBUFFER_BASE) {
    case FRAMEBUFFER_TENSOR_PROD_CONTROL:
        control = value;
        if (is("enable-rejected")) control &= ~FRAMEBUFFER_TENSOR_PROD_ENABLE;
        if ((value & FRAMEBUFFER_TENSOR_PROD_RELEASE_GO) && !is("release-timeout")) {
            ready &= ~release_mask;
            control &= ~FRAMEBUFFER_TENSOR_PROD_RELEASE_GO;
        }
        break;
    case FRAMEBUFFER_TENSOR_PROD_RELEASE: release_mask = value; break;
    case FRAMEBUFFER_TENSOR_PROD_INDEX: index_slot = value; break;
    case FRAMEBUFFER_TENSOR_PROD_ADMISSION_LIMIT: admission = value; break;
    default: break;
    }
}
void mmio_fence(void) { puts("FENCE"); }
int video_service_init(void)
{
    puts("CALL video_init");
    return is("startup-stale") || is("reader-errors") ? -1 : 0;
}
void video_service_poll(void) { puts("CALL video_poll"); }
void hdmi_tx_restart(void) { puts("CALL video_restart"); }
void hdmi_tx_print_status(void) { puts("CALL video_status"); }
int ai_overlay_draw_test_pattern(void) { puts("CALL overlay_test"); return is("reader-errors") ? -1 : 0; }
int clock_chip_read_id(uint16_t *id)
{
    puts("CALL clock_id"); *id = 0x0241;
    return is("reader-errors") ? CLOCK_CHIP_BAD_ID : CLOCK_CHIP_OK;
}
int ai_yolov5nu_correctness_test(void) { puts("CALL correctness"); return 0; }
int ai_yolov5nu_sequential_correctness_test(int reverse)
{
    printf("CALL sequential %d\n", reverse); return 0;
}
int ai_yolov5nu_graph_post_benchmark(void) { puts("CALL graph_post"); return 0; }
void ai_postprocess_ppu_print_profile(void) { puts("CALL ppu_profile"); }
int ai_postprocess_bandwidth_start(uint32_t iterations, uint32_t burst)
{
    printf("CALL reader_start %u %u\n", iterations, burst);
    if (is("reader-errors")) return -5;
    read_polls = 0; read_active = 1;
    return 0;
}
int ai_postprocess_bandwidth_poll(AiPostprocessBandwidthResult *r)
{
    assert(read_active);
    printf("CALL reader_poll %u\n", read_polls);
    if (++read_polls < 3) return 0;
    read_active = 0;
    memset(r, 0, sizeof(*r));
    r->bytes_read = UINT64_C(0x100000123);
    r->active_cycles = SOC_CLOCK_HZ;
    r->read_beats = 40000;
    r->iterations_completed = 256;
    r->ar_stall_cycles = 21; r->r_wait_cycles = 22;
    r->r_backpressure_cycles = 23;
    r->max_outstanding_observed = 32; r->max_reorder_occupancy = 9;
    r->active_id_mask_observed = 0xff;
    if (is("read-only")) { r->crc_mismatches = 1; r->axi_error_count = 2; r->error_flags = 4; return -6; }
    return 1;
}
uint32_t ai_postprocess_diag_read_id(void) { puts("CALL reader_id"); return 0x1234; }
uint32_t ai_postprocess_diag_read_capability(void) { puts("CALL reader_cap"); return 0x5678; }

int rt_init(void) { puts("CALL runtime_init"); enabled = 0; return 0; }
void rt_poll(void) { puts("CALL runtime_poll"); jobs += enabled; }
uint32_t rt_is_idle(void) { puts("CALL runtime_idle"); return !enabled && !is("idle-gates"); }
uint32_t rt_is_enabled(void) { puts("CALL runtime_enabled"); return enabled; }
void rt_set_enabled(uint32_t value) { printf("CALL runtime_enable %u\n", value); enabled = value; }
void rt_get_status(AiRtStatus *s) { puts("CALL runtime_status_copy"); memset(s, 0, sizeof(*s)); s->completed_job_count = jobs; }
void rt_diagnostics_print_status(void) { puts("CALL runtime_status_print"); }
void rt_diagnostics_print_frame_profiles(void) { puts("CALL runtime_profile"); }
/* Frozen main's API/stub maps to the same deterministic double, never to
 * current application code. Canonical Runtime itself has a separate oracle. */
void ai_batch_runtime_init(void) { (void)rt_init(); }
void ai_batch_runtime_poll(void) { rt_poll(); }
uint32_t ai_batch_runtime_is_idle(void) { return rt_is_idle(); }
uint32_t ai_batch_runtime_is_enabled(void) { return rt_is_enabled(); }
void ai_batch_runtime_set_enabled(uint32_t value) { rt_set_enabled(value); }
void ai_batch_runtime_get_status(AiBatchRuntimeStatus *s) { rt_get_status(s); }
void ai_batch_runtime_print_status(void) { rt_diagnostics_print_status(); }
void ai_batch_runtime_print_frame_profiles(void) { rt_diagnostics_print_frame_profiles(); }
int ai_runtime_bridge_init(void) { console_puts("AI_STAGE runtime_init\r\n"); return 0; }
int ai_runtime_bridge_step(void) { assert(!"obsolete bridge step invoked"); return 0; }
TensorIngressSnapshot test_ingress_snapshot(void)
{
    puts("CALL ingress_snapshot");
    TensorIngressSnapshot s = {0};
    s.cycles = cycle;
    s.accepted_bytes = iteration * UINT64_C(0x10000000);
    s.completed_bytes = iteration * UINT64_C(0x08000000);
    s.errors = iteration; s.aw_stall = 2 * iteration; s.w_stall = 3 * iteration;
    s.tl_a_stall = 4 * iteration; s.source_stall = 5 * iteration; s.b_stall = 6 * iteration;
    s.inflight = 7; s.max_inflight = 32; s.ack_latency_max = 200;
    return s;
}
int main(int argc, char **argv)
{
    assert(argc == 2); scenario = argv[1];
    if (is("commands")) commands = "htuUTovspPcr?ziitpih";
    else if (is("runtime-bw")) commands = "ibbt.psbi...";
    else if (is("read-only")) commands = "RRWt.p..";
    else if (is("raw-concurrent")) commands = "Cg?i.t..h";
    else if (is("write-only")) commands = "Wht....Wp";
    else if (is("tensor-soak")) commands = "mg?Rshmm.hgg";
    else if (is("enable-rejected")) commands = "mCW...iib";
    else if (is("release-timeout")) { commands = "mhms.."; cycle_step = SOC_CLOCK_HZ / 5; }
    else if (is("metadata-timeout")) { commands = "m.ms.."; cycle_step = SOC_CLOCK_HZ / 5; }
    else if (is("startup-stale")) { commands = "rcrm..."; ready = 3; writing = 1; }
    else if (is("startup-timeout")) { commands = "hs"; writing = 1; cycle_step = SOC_CLOCK_HZ; }
    else if (is("reader-errors")) commands = "RCiboctr";
    else if (is("idle-gates")) commands = "tuUTRWCppbh";
    else assert(!"unknown application scenario");
    if (setjmp(end_loop) == 0) (void)test_application_entry();
    printf("FINAL iterations=%u enabled=%u ready=%08x writing=%08x control=%08x admission=%u jobs=%u reader_active=%u\n",
           iteration, enabled, ready, writing, control, admission, jobs, read_active);
    return 0;
}
