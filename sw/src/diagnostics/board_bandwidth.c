#include "app/mode_manager.h"
#include "diagnostics/board_bandwidth.h"
#include "diagnostics/tensor_production.h"
#include "diagnostics/ai_postprocess_diag.h"
#include "platform/console.h"
#include "mmio.h"

static uint32_t bandwidth_mbps(uint64_t bytes, uint64_t cycles)
{
    return cycles == 0U ? 0U :
        (uint32_t)((bytes * (SOC_CLOCK_HZ / UINT64_C(1000000))) / cycles);
}

void board_bandwidth_begin(void)
{
    if (app_modes.bandwidth.active != 0U) {
        console_puts("BOARD BW already running\r\n");
        return;
    }
    if (rt_is_enabled() == 0U) {
        console_puts("BOARD BW requires active AI runtime; press i first\r\n");
        return;
    }

    int status = ai_postprocess_bandwidth_start(
        BOARD_BANDWIDTH_ITERATIONS, BOARD_BANDWIDTH_BURST_BYTES);
    if (status != 0) {
        console_puts("BOARD BW reader start failed status/id/cap=");
        if (status < 0)
            console_putc('-');
        console_put_u32((uint32_t)(status < 0 ? -status : status));
        console_putc('/');
        console_put_hex32(ai_postprocess_diag_read_id());
        console_putc('/');
        console_put_hex32(ai_postprocess_diag_read_capability());
        console_puts("\r\n");
        return;
    }

    app_modes.bandwidth = (BoardBandwidthState){0};
    app_modes.bandwidth.active = BOARD_BW_CONCURRENT;
    app_modes.bandwidth.start_cycle = read_cycle();
    app_modes.bandwidth.write_beats = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_W_TRANSFER);
    app_modes.bandwidth.write_bursts = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_BURSTS);
    app_modes.bandwidth.write_completed = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_COMPLETED);
    app_modes.bandwidth.write_aw_stall = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_AW_STALL);
    app_modes.bandwidth.write_w_stall = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_W_STALL);
    app_modes.bandwidth.write_b_wait = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_B_WAIT);
    app_modes.bandwidth.saved_admission_limit = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_ADMISSION_LIMIT);
    mmio_write32(FRAMEBUFFER_BASE +
                 FRAMEBUFFER_TENSOR_PROD_ADMISSION_LIMIT,
                 LOCAL_CAMERA_COUNT);
    mmio_fence();
    rt_get_status(&app_modes.bandwidth.runtime_start);
    console_puts("BOARD BW running read_bytes/iterations/burstB=");
    console_put_u32(AI_POSTPROCESS_BANDWIDTH_BYTES);
    console_putc('/');
    console_put_u32(BOARD_BANDWIDTH_ITERATIONS);
    console_putc('/');
    console_put_u32(BOARD_BANDWIDTH_BURST_BYTES);
    console_puts(" write_admission=");
    console_put_u32(LOCAL_CAMERA_COUNT);
    console_puts("\r\n");
}

void board_read_bandwidth_begin(void)
{
    if (app_modes.bandwidth.active != 0U || app_modes.write_only.active != 0U) {
        console_puts("BOARD BW already running\r\n");
        return;
    }
    if (rt_is_enabled() != 0U ||
        rt_is_idle() == 0U || app_modes.tensor.mode != 0U) {
        console_puts("BOARD READ-ONLY requires AI/tensor producer idle\r\n");
        return;
    }
    int status = ai_postprocess_bandwidth_start(
        BOARD_BANDWIDTH_ITERATIONS, BOARD_BANDWIDTH_BURST_BYTES);
    if (status != 0) {
        console_puts("BOARD READ-ONLY start failed\r\n");
        return;
    }
    app_modes.bandwidth = (BoardBandwidthState){0};
    app_modes.bandwidth.active = BOARD_BW_READ_ONLY;
    app_modes.bandwidth.start_cycle = read_cycle();
    console_puts("BOARD READ-ONLY running bytes/iterations/burstB=");
    console_put_u32(AI_POSTPROCESS_BANDWIDTH_BYTES);
    console_putc('/');
    console_put_u32(BOARD_BANDWIDTH_ITERATIONS);
    console_putc('/');
    console_put_u32(BOARD_BANDWIDTH_BURST_BYTES);
    console_puts("\r\n");
}

void board_raw_concurrent_begin(void)
{
    if (app_modes.bandwidth.active != 0U || app_modes.write_only.active != 0U) {
        console_puts("BOARD BW already running\r\n");
        return;
    }
    if (rt_is_enabled() != 0U ||
        rt_is_idle() == 0U || app_modes.tensor.mode != 0U) {
        console_puts("BOARD RAW CONCURRENT requires AI/tensor producer idle\r\n");
        return;
    }
    int status = ai_postprocess_bandwidth_start(
        BOARD_BANDWIDTH_ITERATIONS, BOARD_BANDWIDTH_BURST_BYTES);
    if (status != 0) {
        console_puts("BOARD RAW CONCURRENT reader start failed\r\n");
        return;
    }

    app_modes.bandwidth = (BoardBandwidthState){0};
    app_modes.bandwidth.active = BOARD_BW_RAW_CONCURRENT;
    app_modes.bandwidth.start_cycle = read_cycle();
    app_modes.bandwidth.write_beats = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_W_TRANSFER);
    app_modes.bandwidth.write_bursts = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_BURSTS);
    app_modes.bandwidth.write_completed = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_COMPLETED);
    app_modes.bandwidth.write_aw_stall = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_AW_STALL);
    app_modes.bandwidth.write_w_stall = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_W_STALL);
    app_modes.bandwidth.write_b_wait = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_B_WAIT);
    app_modes.bandwidth.saved_admission_limit = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_ADMISSION_LIMIT);
    mmio_write32(FRAMEBUFFER_BASE +
                 FRAMEBUFFER_TENSOR_PROD_ADMISSION_MASK,
                 CAMERA_PRESENT_MASK);
    mmio_write32(FRAMEBUFFER_BASE +
                 FRAMEBUFFER_TENSOR_PROD_ADMISSION_LIMIT,
                 LOCAL_CAMERA_COUNT);
    mmio_fence();
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_CONTROL,
                 FRAMEBUFFER_TENSOR_PROD_ENABLE);
    mmio_fence();
    if ((mmio_read32(FRAMEBUFFER_BASE +
                     FRAMEBUFFER_TENSOR_PROD_CONTROL) &
         FRAMEBUFFER_TENSOR_PROD_ENABLE) == 0U) {
        app_modes.bandwidth.active = BOARD_BW_READ_ONLY;
        console_puts("BOARD RAW CONCURRENT producer enable rejected\r\n");
        return;
    }
    app_modes.tensor.mode = 1U;
    app_modes.tensor.report_cycle = read_cycle();
    console_puts("BOARD RAW CONCURRENT running read_bytes/iterations/burstB/write_admission=");
    console_put_u32(AI_POSTPROCESS_BANDWIDTH_BYTES);
    console_putc('/');
    console_put_u32(BOARD_BANDWIDTH_ITERATIONS);
    console_putc('/');
    console_put_u32(BOARD_BANDWIDTH_BURST_BYTES);
    console_putc('/');
    console_put_u32(LOCAL_CAMERA_COUNT);
    console_puts("\r\n");
}

void board_bandwidth_service(void)
{
    AiPostprocessBandwidthResult read_result;
    AiRtStatus runtime_end;
    if (app_modes.bandwidth.active == 0U)
        return;

    int status = ai_postprocess_bandwidth_poll(&read_result);
    if (status == 0)
        return;

    uint32_t mode = app_modes.bandwidth.active;
    uint64_t elapsed = read_cycle() - app_modes.bandwidth.start_cycle;
    uint32_t write_beats = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_W_TRANSFER) -
        app_modes.bandwidth.write_beats;
    uint32_t write_bursts = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_BURSTS) -
        app_modes.bandwidth.write_bursts;
    uint32_t write_completed = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_COMPLETED) -
        app_modes.bandwidth.write_completed;
    uint32_t write_aw_stall = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_AW_STALL) -
        app_modes.bandwidth.write_aw_stall;
    uint32_t write_w_stall = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_W_STALL) -
        app_modes.bandwidth.write_w_stall;
    uint32_t write_b_wait = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_B_WAIT) -
        app_modes.bandwidth.write_b_wait;
    uint64_t write_bytes = (uint64_t)write_beats * UINT64_C(32);
    uint32_t write_mbps = bandwidth_mbps(write_bytes, elapsed);
    uint32_t read_mbps = bandwidth_mbps(read_result.bytes_read,
                                        read_result.active_cycles);
    uint32_t read_efficiency = read_result.read_beats == 0U ? 0U :
        (uint32_t)((read_result.bytes_read * UINT64_C(1000)) /
                   (read_result.read_beats * UINT64_C(32)));
    rt_get_status(&runtime_end);
    if (mode == BOARD_BW_CONCURRENT ||
        mode == BOARD_BW_RAW_CONCURRENT) {
        mmio_write32(FRAMEBUFFER_BASE +
                     FRAMEBUFFER_TENSOR_PROD_ADMISSION_LIMIT,
                     app_modes.bandwidth.saved_admission_limit);
        mmio_fence();
    }
    app_modes.bandwidth.active = 0U;

    if (mode == BOARD_BW_CONCURRENT ||
        mode == BOARD_BW_RAW_CONCURRENT) {
        console_puts(mode == BOARD_BW_RAW_CONCURRENT ?
                     "BOARD RAW CONCURRENT WRITE MBps/bytes/cycles/beats=" :
                     "BOARD BW WRITE MBps/bytes/cycles/beats=");
        console_put_u32(write_mbps);
        console_putc('/');
        console_put_hex64(write_bytes);
        console_putc('/');
        console_put_hex64(elapsed);
        console_putc('/');
        console_put_u32(write_beats);
        console_puts(" bursts(i/c)=");
        console_put_u32(write_bursts);
        console_putc('/');
        console_put_u32(write_completed);
        console_puts(" stall(aw/w/bwait)=");
        console_put_u32(write_aw_stall);
        console_putc('/');
        console_put_u32(write_w_stall);
        console_putc('/');
        console_put_u32(write_b_wait);
        console_puts("\r\n");
    }

    if (mode == BOARD_BW_RAW_CONCURRENT) {
        app_modes.tensor.mode = 2U;
        mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_CONTROL, 0U);
        mmio_fence();
    }

    console_puts(mode == BOARD_BW_READ_ONLY ?
                 "BOARD READ-ONLY status/MBps/bytes/cycles=" :
                 mode == BOARD_BW_RAW_CONCURRENT ?
                 "BOARD RAW CONCURRENT READ status/MBps/bytes/cycles=" :
                 "BOARD BW READ status/MBps/bytes/cycles=");
    if (status < 0)
        console_putc('-');
    console_put_u32((uint32_t)(status < 0 ? -status : status));
    console_putc('/');
    console_put_u32(read_mbps);
    console_putc('/');
    console_put_hex64(read_result.bytes_read);
    console_putc('/');
    console_put_hex64(read_result.active_cycles);
    console_puts(" stall(ar/rwait/rbp)=");
    console_put_hex64(read_result.ar_stall_cycles);
    console_putc('/');
    console_put_hex64(read_result.r_wait_cycles);
    console_putc('/');
    console_put_hex64(read_result.r_backpressure_cycles);
    console_puts(" max(out/reorder)/id/eff=");
    console_put_u32(read_result.max_outstanding_observed);
    console_putc('/');
    console_put_u32(read_result.max_reorder_occupancy);
    console_putc('/');
    console_put_hex32(read_result.active_id_mask_observed);
    console_putc('/');
    console_put_u32(read_efficiency);
    console_puts("\r\nBOARD BW VERIFY iter/crc/timeout/axi/flags jobs=");
    console_put_u32(read_result.iterations_completed);
    console_putc('/');
    console_put_u32(read_result.crc_mismatches);
    console_putc('/');
    console_put_u32(read_result.timeout_count);
    console_putc('/');
    console_put_u32(read_result.axi_error_count);
    console_putc('/');
    console_put_hex32(read_result.error_flags);
    console_putc(' ');
    console_put_u32(runtime_end.completed_job_count -
                    app_modes.bandwidth.runtime_start.completed_job_count);
    console_puts("\r\n");
}

void board_write_only_begin(void)
{
    if (app_modes.write_only.active != 0U || app_modes.bandwidth.active != 0U) {
        console_puts("BOARD BW already running\r\n");
        return;
    }
    if (rt_is_enabled() != 0U ||
        rt_is_idle() == 0U || app_modes.tensor.mode != 0U) {
        console_puts("BOARD WRITE-ONLY requires AI/tensor producer idle\r\n");
        return;
    }

    app_modes.write_only = (BoardWriteOnlyState){0};
    app_modes.write_only.start_cycle = read_cycle();
    app_modes.write_only.write_beats = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_W_TRANSFER);
    app_modes.write_only.write_bursts = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_BURSTS);
    app_modes.write_only.write_completed = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_COMPLETED);
    app_modes.write_only.write_starvation = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_STARVATION);
    app_modes.write_only.write_aw_stall = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_AW_STALL);
    app_modes.write_only.write_w_stall = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_W_STALL);
    app_modes.write_only.write_b_wait = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_B_WAIT);
    app_modes.write_only.saved_admission_limit = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_ADMISSION_LIMIT);

    mmio_write32(FRAMEBUFFER_BASE +
                 FRAMEBUFFER_TENSOR_PROD_ADMISSION_MASK,
                 CAMERA_PRESENT_MASK);
    mmio_write32(FRAMEBUFFER_BASE +
                 FRAMEBUFFER_TENSOR_PROD_ADMISSION_LIMIT,
                 LOCAL_CAMERA_COUNT);
    mmio_fence();
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_CONTROL,
                 FRAMEBUFFER_TENSOR_PROD_ENABLE);
    mmio_fence();
    if ((mmio_read32(FRAMEBUFFER_BASE +
                     FRAMEBUFFER_TENSOR_PROD_CONTROL) &
         FRAMEBUFFER_TENSOR_PROD_ENABLE) == 0U) {
        console_puts("BOARD WRITE-ONLY enable rejected\r\n");
        return;
    }
    app_modes.tensor.mode = 1U;
    app_modes.tensor.report_cycle = read_cycle();
    app_modes.write_only.active = 1U;
    console_puts("BOARD WRITE-ONLY running seconds/admission/burstB=10/");
    console_put_u32(LOCAL_CAMERA_COUNT);
    console_puts("/64\r\n");
}

void board_write_only_service(void)
{
    if (app_modes.write_only.active == 0U)
        return;
    if (app_modes.write_only.draining == 0U &&
        read_cycle() - app_modes.write_only.start_cycle >=
        BOARD_WRITE_ONLY_CYCLES) {
        app_modes.write_only.draining = 1U;
        app_modes.tensor.mode = 2U;
        mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_CONTROL, 0U);
        mmio_fence();
    }
    if (app_modes.write_only.draining == 0U || app_modes.tensor.mode != 0U)
        return;

    uint64_t elapsed = read_cycle() - app_modes.write_only.start_cycle;
    uint32_t beats = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_W_TRANSFER) -
        app_modes.write_only.write_beats;
    uint32_t bursts = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_BURSTS) -
        app_modes.write_only.write_bursts;
    uint32_t completed = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_COMPLETED) -
        app_modes.write_only.write_completed;
    uint32_t starvation = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_STARVATION) -
        app_modes.write_only.write_starvation;
    uint32_t aw_stall = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_AW_STALL) -
        app_modes.write_only.write_aw_stall;
    uint32_t w_stall = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_W_STALL) -
        app_modes.write_only.write_w_stall;
    uint32_t b_wait = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_B_WAIT) -
        app_modes.write_only.write_b_wait;
    uint64_t bytes = (uint64_t)beats * UINT64_C(32);

    mmio_write32(FRAMEBUFFER_BASE +
                 FRAMEBUFFER_TENSOR_PROD_ADMISSION_LIMIT,
                 app_modes.write_only.saved_admission_limit);
    mmio_fence();
    app_modes.write_only.active = 0U;
    console_puts("BOARD WRITE-ONLY MBps/bytes/cycles/beats=");
    console_put_u32(bandwidth_mbps(bytes, elapsed));
    console_putc('/');
    console_put_hex64(bytes);
    console_putc('/');
    console_put_hex64(elapsed);
    console_putc('/');
    console_put_u32(beats);
    console_puts(" bursts(i/c)=");
    console_put_u32(bursts);
    console_putc('/');
    console_put_u32(completed);
    console_puts(" out/max/starve=");
    console_put_u32(mmio_read32(FRAMEBUFFER_BASE +
                                FRAMEBUFFER_TENSOR_DMA_OUTSTANDING));
    console_putc('/');
    console_put_u32(mmio_read32(FRAMEBUFFER_BASE +
                                FRAMEBUFFER_TENSOR_DMA_OUTSTANDING_MAX));
    console_putc('/');
    console_put_u32(starvation);
    console_puts(" stall(aw/w/bwait)=");
    console_put_u32(aw_stall);
    console_putc('/');
    console_put_u32(w_stall);
    console_putc('/');
    console_put_u32(b_wait);
    console_puts("\r\n");
}
