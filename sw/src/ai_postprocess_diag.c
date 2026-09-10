#include "ai_postprocess_diag.h"

#include "mmio.h"
#include "platform.h"

#define DIAG_CONTROL          0x08U
#define DIAG_STATUS           0x0CU
#define DIAG_TENSOR_ADDR_LO   0x10U
#define DIAG_TENSOR_ADDR_HI   0x14U
#define DIAG_TENSOR_BYTES     0x18U
#define DIAG_CRC32            0x1CU
#define DIAG_BYTE_SUM         0x20U
#define DIAG_NONZERO          0x24U
#define DIAG_BYTES_READ       0x28U
#define DIAG_AR_REQUESTS      0x2CU
#define DIAG_READ_BEATS       0x30U
#define DIAG_COMPLETIONS      0x34U
#define DIAG_ERRORS           0x38U
#define DIAG_ERROR_FLAGS      0x3CU

#define DIAG_CONTROL_START    UINT32_C(1)
#define DIAG_CONTROL_CLEAR    UINT32_C(2)
#define DIAG_STATUS_BUSY      UINT32_C(1)
#define DIAG_STATUS_DONE      UINT32_C(2)
#define DIAG_STATUS_ERROR     UINT32_C(4)
#define DIAG_TIMEOUT_CYCLES   (SOC_CLOCK_HZ * UINT64_C(5))

typedef struct {
    uint32_t active;
    uint32_t completion_before;
    uint32_t error_before;
    uint64_t start_cycle;
} AiPostprocessDiagCommand;

static AiPostprocessDiagCommand command;

int ai_postprocess_diag_probe(void)
{
    return mmio_read32(POSTPROCESS_DIAG_BASE) == AI_POSTPROCESS_DIAG_ID ?
           0 : -1;
}

int ai_postprocess_diag_start(uint64_t tensor_addr, uint32_t tensor_bytes)
{
    uint32_t status;
    if (tensor_bytes == 0U || (tensor_addr >> 33) != 0U)
        return -1;
    status = mmio_read32(POSTPROCESS_DIAG_BASE + DIAG_STATUS);
    if (command.active != 0U || (status & DIAG_STATUS_BUSY) != 0U)
        return -2;

    command.completion_before =
        mmio_read32(POSTPROCESS_DIAG_BASE + DIAG_COMPLETIONS);
    command.error_before = mmio_read32(POSTPROCESS_DIAG_BASE + DIAG_ERRORS);
    command.start_cycle = read_cycle();
    command.active = 1U;

    mmio_write32(POSTPROCESS_DIAG_BASE + DIAG_CONTROL, DIAG_CONTROL_CLEAR);
    mmio_write32(POSTPROCESS_DIAG_BASE + DIAG_TENSOR_ADDR_LO,
                 (uint32_t)tensor_addr);
    mmio_write32(POSTPROCESS_DIAG_BASE + DIAG_TENSOR_ADDR_HI,
                 (uint32_t)(tensor_addr >> 32));
    mmio_write32(POSTPROCESS_DIAG_BASE + DIAG_TENSOR_BYTES, tensor_bytes);
    mmio_fence();
    mmio_write32(POSTPROCESS_DIAG_BASE + DIAG_CONTROL, DIAG_CONTROL_START);
    mmio_fence();
    return 0;
}

int ai_postprocess_diag_poll(AiPostprocessDiagResult *result)
{
    uint32_t completion_now;
    uint32_t status;
    if (result == 0)
        return -1;
    if (command.active == 0U)
        return -3;

    completion_now = mmio_read32(POSTPROCESS_DIAG_BASE + DIAG_COMPLETIONS);
    if (completion_now == command.completion_before) {
        if (read_cycle() - command.start_cycle > DIAG_TIMEOUT_CYCLES) {
            command.active = 0U;
            return -4;
        }
        return 0;
    }

    status = mmio_read32(POSTPROCESS_DIAG_BASE + DIAG_STATUS);
    result->crc32 = mmio_read32(POSTPROCESS_DIAG_BASE + DIAG_CRC32);
    result->byte_sum = mmio_read32(POSTPROCESS_DIAG_BASE + DIAG_BYTE_SUM);
    result->nonzero_count =
        mmio_read32(POSTPROCESS_DIAG_BASE + DIAG_NONZERO);
    result->bytes_read = mmio_read32(POSTPROCESS_DIAG_BASE + DIAG_BYTES_READ);
    result->ar_requests =
        mmio_read32(POSTPROCESS_DIAG_BASE + DIAG_AR_REQUESTS);
    result->read_beats =
        mmio_read32(POSTPROCESS_DIAG_BASE + DIAG_READ_BEATS);
    result->completion_count = completion_now;
    result->error_count = mmio_read32(POSTPROCESS_DIAG_BASE + DIAG_ERRORS);
    result->error_flags =
        mmio_read32(POSTPROCESS_DIAG_BASE + DIAG_ERROR_FLAGS);
    command.active = 0U;
    if ((status & DIAG_STATUS_ERROR) != 0U ||
        result->error_count != command.error_before)
        return -5;
    return 1;
}

int ai_postprocess_diag_run(uint64_t tensor_addr, uint32_t tensor_bytes,
                            AiPostprocessDiagResult *result)
{
    int status = ai_postprocess_diag_start(tensor_addr, tensor_bytes);
    if (status != 0)
        return status;
    do {
        status = ai_postprocess_diag_poll(result);
    } while (status == 0);
    return status == 1 ? 0 : status;
}

uint32_t ai_postprocess_crc32(const void *data, size_t bytes)
{
    const uint8_t *values = (const uint8_t *)data;
    uint32_t crc = UINT32_C(0xffffffff);
    if (data == 0 && bytes != 0U)
        return 0U;
    for (size_t index = 0U; index < bytes; ++index) {
        crc ^= values[index];
        for (uint32_t bit = 0U; bit < 8U; ++bit)
            crc = (crc >> 1) ^ ((crc & 1U) != 0U ?
                  UINT32_C(0xedb88320) : 0U);
    }
    return crc ^ UINT32_C(0xffffffff);
}
