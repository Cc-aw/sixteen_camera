/* Run identical Fake CSR/backend workloads against frozen R0 and current
 * Runtime. Pointer values are omitted; frame identity and event order remain. */
#define main stream_fixture_main
#define mmio_read32 fixture_read32
#define mmio_write32 fixture_write32
#define mmio_fence fixture_fence
#define ai_model_backend_init fixture_backend_init
#define ai_model_backend_submit fixture_backend_submit
#define ai_model_backend_poll_compute fixture_poll_compute
#define ai_model_backend_poll_result fixture_poll_result
#define ai_model_backend_abort fixture_abort
#define ai_model_backend_is_idle fixture_idle
#define console_puts fixture_console_puts
#define console_putc fixture_console_putc
#define console_put_u32 fixture_console_put_u32
#define console_put_hex32 fixture_console_put_hex32
#define console_put_hex64 fixture_console_put_hex64
#include "test_ai_batch_runtime_stream.c"
#undef main
#undef mmio_read32
#undef mmio_write32
#undef mmio_fence
#undef ai_model_backend_init
#undef ai_model_backend_submit
#undef ai_model_backend_poll_compute
#undef ai_model_backend_poll_result
#undef ai_model_backend_abort
#undef ai_model_backend_is_idle
#undef console_puts
#undef console_putc
#undef console_put_u32
#undef console_put_hex32
#undef console_put_hex64

/* Compare UART call arguments without relying on a board or host formatting. */
void console_puts(const char *value)
{
    fputs("UART_S hex=", stdout);
    for (const unsigned char *p = (const unsigned char *)value; *p; ++p)
        printf("%02x", *p);
    putchar('\n');
}
void console_putc(char value)
{
    printf("UART_C value=%u\n", (unsigned char)value);
}
void console_put_u32(uint32_t value)
{
    printf("UART_U32 value=%u\n", value);
}
void console_put_hex32(uint32_t value)
{
    printf("UART_HEX32 value=%08x\n", value);
}
void console_put_hex64(uint64_t value)
{
    printf("UART_HEX64 value=%016llx\n", (unsigned long long)value);
}

static uint32_t diagnostic_errors;
uint32_t mmio_read32(uintptr_t address)
{
    uintptr_t offset = address - FRAMEBUFFER_BASE;
    uint32_t value;
    if (offset == FRAMEBUFFER_TENSOR_PROD_ERROR) value = diagnostic_errors;
    else if ((offset >= 0x300 && offset <= 0x324) || offset == FRAMEBUFFER_TENSOR_PROD_OVERFLOW)
        value = (uint32_t)offset;
    else value = fixture_read32(address);
    printf("MMIO_R offset=%lx value=%u cycle=%llu\n", (unsigned long)offset, value, (unsigned long long)test_cycle);
    return value;
}
void mmio_write32(uintptr_t address, uint32_t value)
{
    printf("MMIO_W offset=%lx value=%u cycle=%llu\n", (unsigned long)(address - FRAMEBUFFER_BASE), value, (unsigned long long)test_cycle);
    fixture_write32(address, value);
}
void mmio_fence(void)
{
    printf("MMIO_F cycle=%llu\n", (unsigned long long)test_cycle);
    fixture_fence();
}
void ai_model_backend_init(void)
{
    puts("BACKEND_INIT"); fixture_backend_init();
}
int ai_model_backend_submit(const AiModelFrameRequest *r)
{
    int result = fixture_backend_submit(r);
    printf("SUBMIT job=%llu worker=%u stream=%u frame=%llu version=%u input=%lx cycle=%llu\n",
           (unsigned long long)r->job_id, r->worker_id, r->stream_id,
           (unsigned long long)r->frame_id, r->version, (unsigned long)r->input_addr,
           (unsigned long long)test_cycle);
    return result;
}
int ai_model_backend_poll_compute(uint32_t worker, AiModelComputeCompletion *c)
{
    int result = fixture_poll_compute(worker, c);
    printf("COMPUTE_POLL worker=%u status=%d cycle=%llu", worker, result, (unsigned long long)test_cycle);
    if (result > 0) printf(" job=%llu frame=%llu version=%u", (unsigned long long)c->job_id,
                           (unsigned long long)c->frame_id, c->version);
    putchar('\n'); return result;
}
int ai_model_backend_poll_result(AiModelFrameCompletion *c)
{
    int result = fixture_poll_result(c);
    printf("RESULT_POLL status=%d cycle=%llu", result, (unsigned long long)test_cycle);
    if (result > 0) printf(" job=%llu worker=%u stream=%u frame=%llu version=%u", (unsigned long long)c->job_id,
                           c->worker_id, c->stream_id, (unsigned long long)c->frame_id, c->version);
    putchar('\n'); return result;
}
int ai_model_backend_abort(uint32_t worker)
{
    int result = fixture_abort(worker);
    printf("ABORT worker=%u status=%d cycle=%llu\n", worker, result, (unsigned long long)test_cycle);
    return result;
}
uint32_t ai_model_backend_is_idle(void)
{
    uint32_t result = fixture_idle();
    printf("BACKEND_IDLE value=%u cycle=%llu\n", result, (unsigned long long)test_cycle);
    return result;
}
int main(void)
{
    assert(stream_fixture_main() == 0);
    ai_batch_runtime_print_status();
    diagnostic_errors = 1U << 17;
    frame[17] = 123; version[17] = 29;
    ai_batch_runtime_print_status();
    ai_batch_runtime_print_frame_profiles();
    printf("FINAL cycle=%llu submits=%u releases=%u overlays=%u clears=%u\n",
           (unsigned long long)test_cycle, submit_count, release_count, overlay_count, overlay_clear_count);
    return 0;
}
