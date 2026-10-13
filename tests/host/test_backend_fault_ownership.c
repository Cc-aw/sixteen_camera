#define main unused_live_fixture_main
#define yolov5nu_dim16_worker_start fixture_worker_start
#define mmio_write32 fixture_write32
#define mmio_read32 fixture_read32
#define mmio_fence fixture_fence
#define console_puts fixture_console_puts
#define console_putc fixture_console_putc
#define console_put_u32 fixture_console_put_u32
#define console_put_hex32 fixture_console_put_hex32
#define console_put_hex64 fixture_console_put_hex64
#include "test_v17a_backend.c"
#undef main
#undef yolov5nu_dim16_worker_start
#undef mmio_write32
#undef mmio_read32
#undef mmio_fence
#undef console_puts
#undef console_putc
#undef console_put_u32
#undef console_put_hex32
#undef console_put_hex64
#include "drivers/ppu/ai_ppu_device.h"
#ifdef AI_BACKEND_FAULT_TRACE
#define FAULT_TRACE(...) printf(__VA_ARGS__)
#else
#define FAULT_TRACE(...) ((void)0)
#endif
void console_puts(const char *s) {
#ifdef AI_BACKEND_FAULT_TRACE
    printf("UART_S text=%s\n", s);
#else
    fixture_console_puts(s);
#endif
}
void console_putc(char c) { FAULT_TRACE("UART_C value=%u\n", (unsigned char)c); fixture_console_putc(c); }
void console_put_u32(uint32_t n) { FAULT_TRACE("UART_U value=%u\n", n); fixture_console_put_u32(n); }
void console_put_hex32(uint32_t n) { FAULT_TRACE("UART_H32 value=%x\n", n); fixture_console_put_hex32(n); }
void console_put_hex64(uint64_t n) { FAULT_TRACE("UART_H64 value=%llx\n", (unsigned long long)n); fixture_console_put_hex64(n); }
static unsigned partial_start_error, missing_begin_ack, ppu_busy_fault;
uint32_t mmio_read32(uintptr_t address)
{
    if (ppu_busy_fault && address == POSTPROCESS_DIAG_BASE + 0x238)
        return 0; /* Exercise the legacy single-reader path. */
#ifdef AI_BACKEND_FAULT_TRACE
    if (missing_begin_ack && address == POSTPROCESS_DIAG_BASE + 0x1b4)
        test_cycle += SOC_CLOCK_HZ / 20;
#endif
    uint32_t value = fixture_read32(address);
    FAULT_TRACE("MMIO_R offset=%lx value=%u cycle=%llu\n", (unsigned long)(address - POSTPROCESS_DIAG_BASE), value, (unsigned long long)test_cycle);
    return value;
}
int yolov5nu_dim16_worker_start(uint32_t worker, const int8_t *input)
{
    FAULT_TRACE("MODEL_START worker=%u partial_error=%u cycle=%llu\n", worker, partial_start_error, (unsigned long long)test_cycle);
    int status = fixture_worker_start(worker, input);
    return partial_start_error ? -1 : status;
}
void mmio_write32(uintptr_t address, uint32_t value)
{
    FAULT_TRACE("MMIO_W offset=%lx value=%u cycle=%llu\n", (unsigned long)(address - POSTPROCESS_DIAG_BASE), value, (unsigned long long)test_cycle);
    if (missing_begin_ack && address == POSTPROCESS_DIAG_BASE + 0x1b0 && value == 1) return;
    fixture_write32(address, value);
}
void mmio_fence(void) { FAULT_TRACE("MMIO_F cycle=%llu\n", (unsigned long long)test_cycle); }
#if !YOLO32_LIVE
int yolov5nu_dim16_worker_poll(uint32_t worker, struct yolov5nu_dim16_result *result)
{
    (void)worker; (void)result;
    return ppu_busy_fault ? YOLOV5NU_DIM16_HEAD_READY : YOLOV5NU_DIM16_ERROR;
}
#endif
#ifdef AI_BACKEND_FAULT_TRACE
static void final_ownership(void)
{
    AiModelResourceSnapshot view; ai_model_backend_get_resources(&view);
    printf("FINAL arena=%x Head=%x fault=%u job=%llu gen=%llu hw_gen=%u producer_complete=%u cycle=%llu\n", view.activation_held, view.owned_head, view.unsafe_fault, (unsigned long long)view.heads[0].identity.job_id, (unsigned long long)view.heads[0].generation, view.heads[0].hardware_generation, view.heads[0].producer_complete, (unsigned long long)test_cycle);
}
#endif
int main(int argc, char **argv)
{
    assert(argc == 2); drive_worker = 3;
#ifdef AI_BACKEND_FAULT_TRACE
    assert(atexit(final_ownership) == 0);
#endif
    partial_start_error = !strcmp(argv[1], "start-error");
    missing_begin_ack = !strcmp(argv[1], "begin-error");
    ppu_busy_fault = !strcmp(argv[1], "ppu-busy-done");
    ai_model_backend_init();
    AiModelFrameRequest r = request(0, 1);
    int status = ai_model_backend_submit(&r);
    if (ppu_busy_fault) {
        assert(status == 0);
        AiModelComputeCompletion compute;
        assert(ai_model_backend_poll_compute(0, &compute) == 1);
        regs[0x11c / 4] = AI_PPU_DEVICE_STATUS_DONE | AI_PPU_DEVICE_STATUS_READ_BUSY;
        AiModelFrameCompletion result;
        assert(ai_model_backend_poll_result(&result) == -2);
        AiModelResourceSnapshot before, after;
        ai_model_backend_get_resources(&before);
        assert(!before.activation_held && before.owned_head == 1);
        assert(before.heads[0].state == AI_RT_FAULT_HELD && before.heads[0].producer_complete);
        assert(ai_model_backend_abort(0) == 0); /* Compute stopped; reader has not. */
        ai_model_backend_init();
        ai_model_backend_get_resources(&after);
        assert(after.owned_head == before.owned_head && !ai_model_backend_is_idle());
        assert(ai_model_backend_submit(&r) == -2);
        puts("R2_PPU_BUSY_DONE=PASS activation_released_Head_retained");
        return 0;
    }
    if (partial_start_error || missing_begin_ack) assert(status == AI_MODEL_SUBMIT_FAULT_HELD);
    else {
        assert(status == 0);
#if YOLO32_LIVE
        assert(ai_model_backend_abort(0) == -2);
#endif
        AiModelComputeCompletion completion;
        assert(ai_model_backend_poll_compute(0, &completion) == -2);
    }
    AiModelResourceSnapshot first, after;
    ai_model_backend_get_resources(&first);
    assert(first.activation_held == 1 && first.owned_head == 1);
    assert(first.arenas[0].state == AI_RT_FAULT_HELD && first.heads[0].state == AI_RT_FAULT_HELD);
    assert(first.heads[0].identity.job_id == r.job_id && !first.heads[0].producer_complete);
    for (unsigned repeat = 0; repeat < 4; ++repeat) assert(ai_model_backend_abort(0) == -2);
    ai_model_backend_init(); ai_model_backend_get_resources(&after);
    assert(after.activation_held == first.activation_held && after.owned_head == first.owned_head);
    assert(after.heads[0].generation == first.heads[0].generation && !ai_model_backend_is_idle());
    assert(ai_model_backend_submit(&r) == -2);
    puts("R2_BACKEND_FAULT=PASS begin_start_model_error_retain_activation_Head init_abort_cannot_erase_ownership");
    return 0;
}
