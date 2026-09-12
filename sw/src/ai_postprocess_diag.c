#include "ai_postprocess_diag.h"

#include "mmio.h"
#include "platform.h"

#define DIAG_CAPABILITY       0x04U
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
#define DIAG_ACTIVE_CYCLES    0x40U
#define DIAG_AR_STALL_CYCLES  0x44U
#define DIAG_R_WAIT_CYCLES    0x48U
#define DIAG_R_BACKPRESSURE   0x4CU
#define DIAG_MAX_OUTSTANDING  0x50U
#define DIAG_MAX_REORDER       0x54U
#define DIAG_ACTIVE_ID_MASK    0x58U
#define DIAG_BURST_BEATS       0x5CU

#define DIAG_CONTROL_START    UINT32_C(1)
#define DIAG_CONTROL_CLEAR    UINT32_C(2)
#define DIAG_CONTROL_FAST     UINT32_C(4)
#define DIAG_STATUS_BUSY      UINT32_C(1)
#define DIAG_STATUS_DONE      UINT32_C(2)
#define DIAG_STATUS_ERROR     UINT32_C(4)
#define DIAG_TIMEOUT_CYCLES   (SOC_CLOCK_HZ * UINT64_C(5))
#define DIAG_STRESS_BYTES     UINT32_C(4099)
#define DIAG_STRESS_STRIDE    UINT32_C(0x10000)
#define DIAG_STRESS_OFFSET    UINT32_C(3)
#define DIAG_BANDWIDTH_BYTES  AI_MODEL_OUTPUT_TENSOR_BYTES
#define TAIHANG_L2_FLUSH64    ((uintptr_t)UINT64_C(0x02010200))

typedef struct {
    uint32_t active;
    uint32_t completion_before;
    uint32_t error_before;
    uint64_t start_cycle;
} AiPostprocessDiagCommand;

static AiPostprocessDiagCommand command;

typedef struct {
    uint32_t running;
    AiPostprocessBandwidthResult result;
} AiPostprocessBandwidthState;

static AiPostprocessBandwidthState bandwidth;

static void cache_line_flush(uintptr_t address)
{
    mmio_fence();
    *(volatile uint64_t *)TAIHANG_L2_FLUSH64 =
        (uint64_t)(address & ~(uintptr_t)63U);
    mmio_fence();
}

static void cache_range_flush(const void *base, size_t bytes)
{
    uintptr_t first = (uintptr_t)base & ~(uintptr_t)63U;
    uintptr_t end = ((uintptr_t)base + bytes + 63U) & ~(uintptr_t)63U;
    for (uintptr_t address = first; address < end; address += 64U)
        cache_line_flush(address);
}

void ai_postprocess_diag_flush_range(const void *base, size_t bytes)
{
    cache_range_flush(base, bytes);
}

int ai_postprocess_diag_probe(void)
{
    return ai_postprocess_diag_read_id() == AI_POSTPROCESS_DIAG_ID ?
           0 : -1;
}

uint32_t ai_postprocess_diag_read_id(void)
{
    return mmio_read32(POSTPROCESS_DIAG_BASE);
}

uint32_t ai_postprocess_diag_read_capability(void)
{
    return mmio_read32(POSTPROCESS_DIAG_BASE + DIAG_CAPABILITY);
}

static int ai_postprocess_diag_start_mode(uint64_t tensor_addr,
                                          uint32_t tensor_bytes,
                                          uint32_t fast)
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
    mmio_write32(POSTPROCESS_DIAG_BASE + DIAG_CONTROL,
                 DIAG_CONTROL_START |
                 (fast != 0U ? DIAG_CONTROL_FAST : 0U));
    mmio_fence();
    return 0;
}

int ai_postprocess_diag_start(uint64_t tensor_addr, uint32_t tensor_bytes)
{
    return ai_postprocess_diag_start_mode(tensor_addr, tensor_bytes, 0U);
}

int ai_postprocess_diag_start_fast(uint64_t tensor_addr,
                                   uint32_t tensor_bytes)
{
    return ai_postprocess_diag_start_mode(tensor_addr, tensor_bytes, 1U);
}

uint32_t ai_postprocess_diag_is_active(void)
{
    return command.active;
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
    result->active_cycles =
        mmio_read32(POSTPROCESS_DIAG_BASE + DIAG_ACTIVE_CYCLES);
    result->ar_stall_cycles =
        mmio_read32(POSTPROCESS_DIAG_BASE + DIAG_AR_STALL_CYCLES);
    result->r_wait_cycles =
        mmio_read32(POSTPROCESS_DIAG_BASE + DIAG_R_WAIT_CYCLES);
    result->r_backpressure_cycles =
        mmio_read32(POSTPROCESS_DIAG_BASE + DIAG_R_BACKPRESSURE);
    result->max_outstanding_observed =
        mmio_read32(POSTPROCESS_DIAG_BASE + DIAG_MAX_OUTSTANDING);
    result->max_reorder_occupancy =
        mmio_read32(POSTPROCESS_DIAG_BASE + DIAG_MAX_REORDER);
    result->active_id_mask_observed =
        mmio_read32(POSTPROCESS_DIAG_BASE + DIAG_ACTIVE_ID_MASK);
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

int ai_postprocess_diag_coherence_stress(
    uint32_t iterations, AiPostprocessDiagStressResult *result)
{
    AiPostprocessDiagResult observed;

    if (result == 0 || iterations == 0U)
        return -1;
    *result = (AiPostprocessDiagStressResult){0};
    if (ai_postprocess_diag_probe() != 0) {
        result->status = -2;
        return -2;
    }

    for (uint32_t iteration = 0U; iteration < iterations; ++iteration) {
        uint32_t device_addr = AI_MODEL_OUTPUT0_PHYS_BASE +
            (iteration & 1U) * DIAG_STRESS_STRIDE + DIAG_STRESS_OFFSET;
        uint8_t *buffer = (uint8_t *)AI_DDR_CPU_ALIAS(device_addr);
        uint32_t expected_sum = 0U;
        uint32_t expected_nonzero = 0U;
        observed = (AiPostprocessDiagResult){0};

        // Alternate two buffers and change every byte on every reuse. The
        // fence is the producer release before descriptor writes/doorbell.
        for (uint32_t index = 0U; index < DIAG_STRESS_BYTES; ++index) {
            uint8_t value = (uint8_t)(index * UINT32_C(29) +
                                      iteration * UINT32_C(71) +
                                      (index >> 5));
            buffer[index] = value;
            expected_sum += value;
            expected_nonzero += value != 0U;
        }
        mmio_fence();
        result->expected_crc32 =
            ai_postprocess_crc32(buffer, DIAG_STRESS_BYTES);

        uint64_t start_cycle = read_cycle();
        int status = ai_postprocess_diag_run(device_addr,
                                             DIAG_STRESS_BYTES, &observed);
        uint64_t elapsed = read_cycle() - start_cycle;
        result->total_cycles += elapsed;
        if (elapsed > result->maximum_cycles)
            result->maximum_cycles = elapsed;
        result->observed_crc32 = observed.crc32;
        result->error_flags = observed.error_flags;

        if (status != 0 || observed.crc32 != result->expected_crc32 ||
            observed.byte_sum != expected_sum ||
            observed.nonzero_count != expected_nonzero ||
            observed.bytes_read != DIAG_STRESS_BYTES) {
            result->failed_iteration = iteration;
            result->status = status != 0 ? status : -3;
            return result->status;
        }
        result->iterations_completed = iteration + 1U;
    }
    return 0;
}

int ai_postprocess_bandwidth_start(uint32_t iterations,
                                   uint32_t burst_bytes)
{
    uint8_t *buffer;

    if (iterations == 0U || burst_bytes < 32U || burst_bytes > 4096U ||
        (burst_bytes & 31U) != 0U ||
        bandwidth.running != 0U ||
        ai_postprocess_diag_is_active() != 0U)
        return -1;
    if (ai_postprocess_diag_probe() != 0)
        return -2;
    if (ai_postprocess_diag_read_capability() !=
        AI_POSTPROCESS_DIAG_P1C_CAPABILITY)
        return -3;

    bandwidth = (AiPostprocessBandwidthState){0};
    bandwidth.result.iterations_requested = iterations;
    bandwidth.result.burst_bytes = burst_bytes;
    mmio_write32(POSTPROCESS_DIAG_BASE + DIAG_BURST_BEATS,
                 burst_bytes / 32U);
    buffer = (uint8_t *)AI_DDR_CPU_ALIAS(AI_MODEL_OUTPUT0_PHYS_BASE);
    for (uint32_t index = 0U; index < DIAG_BANDWIDTH_BYTES; ++index)
        buffer[index] = (uint8_t)(index * UINT32_C(29) +
                                  (index >> 7) + UINT32_C(0x5a));
    mmio_fence();
    bandwidth.result.expected_crc32 =
        ai_postprocess_crc32(buffer, DIAG_BANDWIDTH_BYTES);
    cache_range_flush(buffer, DIAG_BANDWIDTH_BYTES);

    int status = ai_postprocess_diag_start_fast(
        AI_MODEL_OUTPUT0_PHYS_BASE, DIAG_BANDWIDTH_BYTES);
    if (status != 0)
        return status;
    bandwidth.running = 1U;
    return 0;
}

int ai_postprocess_bandwidth_poll(AiPostprocessBandwidthResult *result)
{
    AiPostprocessDiagResult observed = {0};
    int status;

    if (result == 0 || bandwidth.running == 0U)
        return -1;
    status = ai_postprocess_diag_poll(&observed);
    if (status == 0)
        return 0;

    bandwidth.result.observed_crc32 = observed.crc32;
    bandwidth.result.error_flags |= observed.error_flags;
    bandwidth.result.bytes_read += observed.bytes_read;
    bandwidth.result.active_cycles += observed.active_cycles;
    bandwidth.result.ar_requests += observed.ar_requests;
    bandwidth.result.read_beats += observed.read_beats;
    bandwidth.result.ar_stall_cycles += observed.ar_stall_cycles;
    bandwidth.result.r_wait_cycles += observed.r_wait_cycles;
    bandwidth.result.r_backpressure_cycles +=
        observed.r_backpressure_cycles;
    if (observed.max_outstanding_observed >
        bandwidth.result.max_outstanding_observed)
        bandwidth.result.max_outstanding_observed =
            observed.max_outstanding_observed;
    if (observed.max_reorder_occupancy >
        bandwidth.result.max_reorder_occupancy)
        bandwidth.result.max_reorder_occupancy =
            observed.max_reorder_occupancy;
    bandwidth.result.active_id_mask_observed |=
        observed.active_id_mask_observed;
    if (status == -4)
        bandwidth.result.timeout_count++;
    if (status == -5)
        bandwidth.result.axi_error_count++;
    if (observed.bytes_read != DIAG_BANDWIDTH_BYTES ||
        observed.crc32 != bandwidth.result.expected_crc32)
        bandwidth.result.crc_mismatches++;
    if (status < 0 || bandwidth.result.crc_mismatches != 0U) {
        bandwidth.running = 0U;
        *result = bandwidth.result;
        return status < 0 ? status : -3;
    }

    bandwidth.result.iterations_completed++;
    if (bandwidth.result.iterations_completed ==
        bandwidth.result.iterations_requested) {
        bandwidth.running = 0U;
        *result = bandwidth.result;
        return 1;
    }

    status = ai_postprocess_diag_start_fast(
        AI_MODEL_OUTPUT0_PHYS_BASE, DIAG_BANDWIDTH_BYTES);
    if (status != 0) {
        bandwidth.running = 0U;
        *result = bandwidth.result;
        return status;
    }
    return 0;
}
