#include <stdint.h>

#include "ai_batch_runtime.h"
#include "ai_overlay.h"
#include "ai_postprocess_diag.h"
#include "ai_runtime_bridge.h"
#ifdef AI_MODEL_YOLOV5NU
#include "ai_yolov5nu_selftest.h"
#endif
#include "clock_chip.h"
#include "console.h"
#include "hdmi_tx.h"
#include "mmio.h"
#include "platform.h"
#include "video_service.h"

static uint32_t tensor_production_mode;
static uint32_t tensor_production_done[VIDEO_CHANNEL_COUNT];
static uint32_t tensor_production_last_frame[VIDEO_CHANNEL_COUNT];
static uint64_t tensor_production_report_cycle;

#define BOARD_BANDWIDTH_ITERATIONS UINT32_C(256)
#define BOARD_BANDWIDTH_BURST_BYTES UINT32_C(64)
#define BOARD_WRITE_ONLY_CYCLES (SOC_CLOCK_HZ * UINT64_C(10))
#define BOARD_BW_CONCURRENT UINT32_C(1)
#define BOARD_BW_READ_ONLY UINT32_C(2)
#define BOARD_BW_RAW_CONCURRENT UINT32_C(3)

typedef struct {
    uint32_t active;
    uint64_t start_cycle;
    uint32_t write_beats;
    uint32_t write_bursts;
    uint32_t write_completed;
    uint32_t write_aw_stall;
    uint32_t write_w_stall;
    uint32_t write_b_wait;
    uint32_t saved_admission_limit;
    AiBatchRuntimeStatus runtime_start;
} BoardBandwidthState;

static BoardBandwidthState board_bandwidth;

typedef struct {
    uint32_t active;
    uint32_t draining;
    uint64_t start_cycle;
    uint32_t write_beats;
    uint32_t write_bursts;
    uint32_t write_completed;
    uint32_t write_starvation;
    uint32_t write_aw_stall;
    uint32_t write_w_stall;
    uint32_t write_b_wait;
    uint32_t saved_admission_limit;
} BoardWriteOnlyState;

static BoardWriteOnlyState board_write_only;

static void print_help(void)
{
#ifdef AI_MODEL_YOLOV5NU
    console_puts("Commands: t=fixed image dual Gemmini test, u/U=fixed image sequential Gemmini test (0,1/1,0), T=fixed image Gemmini+PPU test, ");
#else
    console_puts("Commands: ");
#endif
    console_puts("R=FBus read-only BW, W=tensor write-only BW (10s), C=raw tensor/FBus concurrent BW, b=AI concurrent BW, s=status, o=overlay test, p=profile, m=tensor soak, i=AI runtime, r=restart, c=clock ID, h=help\r\n");
}

static uint32_t bandwidth_mbps(uint64_t bytes, uint64_t cycles)
{
    return cycles == 0U ? 0U :
        (uint32_t)((bytes * (SOC_CLOCK_HZ / UINT64_C(1000000))) / cycles);
}

static void board_bandwidth_begin(void)
{
    if (board_bandwidth.active != 0U) {
        console_puts("BOARD BW already running\r\n");
        return;
    }
    if (ai_batch_runtime_is_enabled() == 0U) {
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

    board_bandwidth = (BoardBandwidthState){0};
    board_bandwidth.active = BOARD_BW_CONCURRENT;
    board_bandwidth.start_cycle = read_cycle();
    board_bandwidth.write_beats = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_W_TRANSFER);
    board_bandwidth.write_bursts = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_BURSTS);
    board_bandwidth.write_completed = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_COMPLETED);
    board_bandwidth.write_aw_stall = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_AW_STALL);
    board_bandwidth.write_w_stall = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_W_STALL);
    board_bandwidth.write_b_wait = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_B_WAIT);
    board_bandwidth.saved_admission_limit = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_ADMISSION_LIMIT);
    mmio_write32(FRAMEBUFFER_BASE +
                 FRAMEBUFFER_TENSOR_PROD_ADMISSION_LIMIT,
                 LOCAL_CAMERA_COUNT);
    mmio_fence();
    ai_batch_runtime_get_status(&board_bandwidth.runtime_start);
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

static void board_read_bandwidth_begin(void)
{
    if (board_bandwidth.active != 0U || board_write_only.active != 0U) {
        console_puts("BOARD BW already running\r\n");
        return;
    }
    if (ai_batch_runtime_is_enabled() != 0U ||
        ai_batch_runtime_is_idle() == 0U || tensor_production_mode != 0U) {
        console_puts("BOARD READ-ONLY requires AI/tensor producer idle\r\n");
        return;
    }
    int status = ai_postprocess_bandwidth_start(
        BOARD_BANDWIDTH_ITERATIONS, BOARD_BANDWIDTH_BURST_BYTES);
    if (status != 0) {
        console_puts("BOARD READ-ONLY start failed\r\n");
        return;
    }
    board_bandwidth = (BoardBandwidthState){0};
    board_bandwidth.active = BOARD_BW_READ_ONLY;
    board_bandwidth.start_cycle = read_cycle();
    console_puts("BOARD READ-ONLY running bytes/iterations/burstB=");
    console_put_u32(AI_POSTPROCESS_BANDWIDTH_BYTES);
    console_putc('/');
    console_put_u32(BOARD_BANDWIDTH_ITERATIONS);
    console_putc('/');
    console_put_u32(BOARD_BANDWIDTH_BURST_BYTES);
    console_puts("\r\n");
}

static void board_raw_concurrent_begin(void)
{
    if (board_bandwidth.active != 0U || board_write_only.active != 0U) {
        console_puts("BOARD BW already running\r\n");
        return;
    }
    if (ai_batch_runtime_is_enabled() != 0U ||
        ai_batch_runtime_is_idle() == 0U || tensor_production_mode != 0U) {
        console_puts("BOARD RAW CONCURRENT requires AI/tensor producer idle\r\n");
        return;
    }
    int status = ai_postprocess_bandwidth_start(
        BOARD_BANDWIDTH_ITERATIONS, BOARD_BANDWIDTH_BURST_BYTES);
    if (status != 0) {
        console_puts("BOARD RAW CONCURRENT reader start failed\r\n");
        return;
    }

    board_bandwidth = (BoardBandwidthState){0};
    board_bandwidth.active = BOARD_BW_RAW_CONCURRENT;
    board_bandwidth.start_cycle = read_cycle();
    board_bandwidth.write_beats = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_W_TRANSFER);
    board_bandwidth.write_bursts = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_BURSTS);
    board_bandwidth.write_completed = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_COMPLETED);
    board_bandwidth.write_aw_stall = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_AW_STALL);
    board_bandwidth.write_w_stall = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_W_STALL);
    board_bandwidth.write_b_wait = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_B_WAIT);
    board_bandwidth.saved_admission_limit = mmio_read32(
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
        board_bandwidth.active = BOARD_BW_READ_ONLY;
        console_puts("BOARD RAW CONCURRENT producer enable rejected\r\n");
        return;
    }
    tensor_production_mode = 1U;
    tensor_production_report_cycle = read_cycle();
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

static void board_bandwidth_service(void)
{
    AiPostprocessBandwidthResult read_result;
    AiBatchRuntimeStatus runtime_end;
    if (board_bandwidth.active == 0U)
        return;

    int status = ai_postprocess_bandwidth_poll(&read_result);
    if (status == 0)
        return;

    uint32_t mode = board_bandwidth.active;
    uint64_t elapsed = read_cycle() - board_bandwidth.start_cycle;
    uint32_t write_beats = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_W_TRANSFER) -
        board_bandwidth.write_beats;
    uint32_t write_bursts = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_BURSTS) -
        board_bandwidth.write_bursts;
    uint32_t write_completed = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_COMPLETED) -
        board_bandwidth.write_completed;
    uint32_t write_aw_stall = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_AW_STALL) -
        board_bandwidth.write_aw_stall;
    uint32_t write_w_stall = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_W_STALL) -
        board_bandwidth.write_w_stall;
    uint32_t write_b_wait = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_B_WAIT) -
        board_bandwidth.write_b_wait;
    uint64_t write_bytes = (uint64_t)write_beats * UINT64_C(32);
    uint32_t write_mbps = bandwidth_mbps(write_bytes, elapsed);
    uint32_t read_mbps = bandwidth_mbps(read_result.bytes_read,
                                        read_result.active_cycles);
    uint32_t read_efficiency = read_result.read_beats == 0U ? 0U :
        (uint32_t)((read_result.bytes_read * UINT64_C(1000)) /
                   (read_result.read_beats * UINT64_C(32)));
    ai_batch_runtime_get_status(&runtime_end);
    if (mode == BOARD_BW_CONCURRENT ||
        mode == BOARD_BW_RAW_CONCURRENT) {
        mmio_write32(FRAMEBUFFER_BASE +
                     FRAMEBUFFER_TENSOR_PROD_ADMISSION_LIMIT,
                     board_bandwidth.saved_admission_limit);
        mmio_fence();
    }
    board_bandwidth.active = 0U;

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
        tensor_production_mode = 2U;
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
                    board_bandwidth.runtime_start.completed_job_count);
    console_puts("\r\n");
}

static void tensor_production_service(void)
{
    if (tensor_production_mode == 0U)
        return;
    uint32_t ready = mmio_read32(FRAMEBUFFER_BASE +
                                 FRAMEBUFFER_TENSOR_PROD_READY);
    for (uint32_t slot = 0U; slot < 32U; ++slot) {
        if ((ready & (UINT32_C(1) << slot)) == 0U)
            continue;
        uint32_t stream = slot % VIDEO_CHANNEL_COUNT;
        mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_INDEX, slot);
        mmio_fence();
        uint32_t frame = mmio_read32(FRAMEBUFFER_BASE +
                                     FRAMEBUFFER_TENSOR_PROD_FRAME);
        uint32_t bytes = mmio_read32(FRAMEBUFFER_BASE +
                                     FRAMEBUFFER_TENSOR_PROD_BYTES);
        uint64_t metadata_start = read_cycle();
        while ((bytes != TENSOR_MEMBER_BYTES ||
                (tensor_production_done[stream] != 0U &&
                 frame <= tensor_production_last_frame[stream])) &&
               read_cycle() - metadata_start < SOC_CLOCK_HZ / 100U) {
            frame = mmio_read32(FRAMEBUFFER_BASE +
                                FRAMEBUFFER_TENSOR_PROD_FRAME);
            bytes = mmio_read32(FRAMEBUFFER_BASE +
                                FRAMEBUFFER_TENSOR_PROD_BYTES);
        }
        if (bytes != TENSOR_MEMBER_BYTES ||
            (tensor_production_done[stream] != 0U &&
             frame <= tensor_production_last_frame[stream])) {
            console_puts("TENSOR PROD FAIL slot/frame/bytes=");
            console_put_u32(slot);
            console_putc('/');
            console_put_u32(frame);
            console_putc('/');
            console_put_u32(bytes);
            console_puts("\r\n");
        } else {
            tensor_production_done[stream]++;
            tensor_production_last_frame[stream] = frame;
        }
        mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_RELEASE,
                     UINT32_C(1) << slot);
        mmio_fence();
        mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_CONTROL,
                     (tensor_production_mode == 1U ?
                      FRAMEBUFFER_TENSOR_PROD_ENABLE : 0U) |
                     FRAMEBUFFER_TENSOR_PROD_RELEASE_GO);
        mmio_fence();
        uint64_t start = read_cycle();
        while (((mmio_read32(FRAMEBUFFER_BASE +
                             FRAMEBUFFER_TENSOR_PROD_READY) &
                 (UINT32_C(1) << slot)) != 0U) ||
               (mmio_read32(FRAMEBUFFER_BASE +
                            FRAMEBUFFER_TENSOR_PROD_CONTROL) &
                FRAMEBUFFER_TENSOR_PROD_RELEASE_GO) != 0U) {
            if (read_cycle() - start > SOC_CLOCK_HZ / 10U) {
                console_puts("TENSOR PROD release timeout\r\n");
                tensor_production_mode = 2U;
                mmio_write32(FRAMEBUFFER_BASE +
                             FRAMEBUFFER_TENSOR_PROD_CONTROL, 0U);
                return;
            }
        }
        break;
    }
    if (tensor_production_mode == 2U &&
        mmio_read32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_READY) == 0U &&
        mmio_read32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_WRITING) == 0U) {
        tensor_production_mode = 0U;
        console_puts("TENSOR PROD drained\r\n");
    }
    if (read_cycle() - tensor_production_report_cycle >= SOC_CLOCK_HZ) {
        uint32_t no_slot = 0U, missed = 0U, admission_skip = 0U;
        uint32_t overflow = 0U;
        for (uint32_t channel = 0U; channel < VIDEO_CHANNEL_COUNT; ++channel) {
            mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_INDEX,
                         channel);
            mmio_fence();
            no_slot += mmio_read32(FRAMEBUFFER_BASE +
                                   FRAMEBUFFER_TENSOR_PROD_NO_SLOT);
            missed += mmio_read32(FRAMEBUFFER_BASE +
                                  FRAMEBUFFER_TENSOR_PROD_MISSED);
            admission_skip += mmio_read32(
                FRAMEBUFFER_BASE +
                FRAMEBUFFER_TENSOR_PROD_ADMISSION_SKIP);
            overflow += mmio_read32(FRAMEBUFFER_BASE +
                                    FRAMEBUFFER_TENSOR_PROD_OVERFLOW);
        }
        console_puts("TENSOR PROD done CH1..16=");
        for (uint32_t channel = 0U; channel < VIDEO_CHANNEL_COUNT; ++channel) {
            if (channel != 0U)
                console_putc(',');
            console_put_u32(tensor_production_done[channel]);
        }
        console_puts(" missed/admit_skip/no_slot/overflow/error=");
        console_put_u32(missed);
        console_putc('/');
        console_put_u32(admission_skip);
        console_putc('/');
        console_put_u32(no_slot);
        console_putc('/');
        console_put_u32(overflow);
        console_putc('/');
        console_put_hex32(mmio_read32(FRAMEBUFFER_BASE +
                                      FRAMEBUFFER_TENSOR_PROD_ERROR));
        console_puts("\r\n");
        tensor_production_report_cycle = read_cycle();
    }
}

static void tensor_production_toggle(void)
{
    if (tensor_production_mode == 1U) {
        tensor_production_mode = 2U;
        mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_CONTROL, 0U);
        console_puts("TENSOR PROD draining\r\n");
        return;
    }
    if (tensor_production_mode != 0U)
        return;
    if (ai_batch_runtime_is_enabled() != 0U ||
        ai_batch_runtime_is_idle() == 0U) {
        console_puts("TENSOR PROD: disable AI and drain all arenas first\r\n");
        return;
    }
    for (uint32_t channel = 0U; channel < VIDEO_CHANNEL_COUNT; ++channel) {
        tensor_production_done[channel] = 0U;
        tensor_production_last_frame[channel] = 0U;
    }
    mmio_write32(FRAMEBUFFER_BASE +
                 FRAMEBUFFER_TENSOR_PROD_ADMISSION_MASK,
                 CAMERA_PRESENT_MASK);
    mmio_write32(FRAMEBUFFER_BASE +
                 FRAMEBUFFER_TENSOR_PROD_ADMISSION_LIMIT,
                 TENSOR_PRODUCTION_ADMISSION_LIMIT);
    mmio_fence();
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_CONTROL,
                 FRAMEBUFFER_TENSOR_PROD_ENABLE);
    mmio_fence();
    if ((mmio_read32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_CONTROL) &
         FRAMEBUFFER_TENSOR_PROD_ENABLE) == 0U) {
        console_puts("TENSOR PROD enable rejected by hardware\r\n");
        return;
    }
    tensor_production_mode = 1U;
    tensor_production_report_cycle = read_cycle();
    console_puts("TENSOR PROD enabled, multi-channel capture, press m to drain\r\n");
}

static void tensor_production_init(void)
{
    /* A Rocket debugger reset may leave the video clock domain running. */
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_CONTROL, 0U);
    mmio_fence();
    mmio_write32(FRAMEBUFFER_BASE +
                 FRAMEBUFFER_TENSOR_PROD_ADMISSION_MASK,
                 CAMERA_PRESENT_MASK);
    mmio_write32(FRAMEBUFFER_BASE +
                 FRAMEBUFFER_TENSOR_PROD_ADMISSION_LIMIT,
                 TENSOR_PRODUCTION_ADMISSION_LIMIT);
    mmio_fence();
    uint64_t start = read_cycle();
    while (mmio_read32(FRAMEBUFFER_BASE +
                       FRAMEBUFFER_TENSOR_PROD_WRITING) != 0U) {
        if (read_cycle() - start > SOC_CLOCK_HZ * 2U) {
            console_puts("TENSOR PROD stale write did not drain\r\n");
            return;
        }
    }
    uint32_t ready = mmio_read32(FRAMEBUFFER_BASE +
                                 FRAMEBUFFER_TENSOR_PROD_READY);
    if (ready != 0U) {
        mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_RELEASE,
                     ready);
        mmio_fence();
        mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_CONTROL,
                     FRAMEBUFFER_TENSOR_PROD_RELEASE_GO);
        mmio_fence();
        start = read_cycle();
        while (mmio_read32(FRAMEBUFFER_BASE +
                           FRAMEBUFFER_TENSOR_PROD_READY) != 0U ||
               (mmio_read32(FRAMEBUFFER_BASE +
                            FRAMEBUFFER_TENSOR_PROD_CONTROL) &
                FRAMEBUFFER_TENSOR_PROD_RELEASE_GO) != 0U) {
            if (read_cycle() - start > SOC_CLOCK_HZ / 10U) {
                console_puts("TENSOR PROD stale slots did not release\r\n");
                return;
            }
        }
    }
}

static void board_write_only_begin(void)
{
    if (board_write_only.active != 0U || board_bandwidth.active != 0U) {
        console_puts("BOARD BW already running\r\n");
        return;
    }
    if (ai_batch_runtime_is_enabled() != 0U ||
        ai_batch_runtime_is_idle() == 0U || tensor_production_mode != 0U) {
        console_puts("BOARD WRITE-ONLY requires AI/tensor producer idle\r\n");
        return;
    }

    board_write_only = (BoardWriteOnlyState){0};
    board_write_only.start_cycle = read_cycle();
    board_write_only.write_beats = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_W_TRANSFER);
    board_write_only.write_bursts = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_BURSTS);
    board_write_only.write_completed = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_COMPLETED);
    board_write_only.write_starvation = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_STARVATION);
    board_write_only.write_aw_stall = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_AW_STALL);
    board_write_only.write_w_stall = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_W_STALL);
    board_write_only.write_b_wait = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_B_WAIT);
    board_write_only.saved_admission_limit = mmio_read32(
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
    tensor_production_mode = 1U;
    tensor_production_report_cycle = read_cycle();
    board_write_only.active = 1U;
    console_puts("BOARD WRITE-ONLY running seconds/admission/burstB=10/");
    console_put_u32(LOCAL_CAMERA_COUNT);
    console_puts("/64\r\n");
}

static void board_write_only_service(void)
{
    if (board_write_only.active == 0U)
        return;
    if (board_write_only.draining == 0U &&
        read_cycle() - board_write_only.start_cycle >=
        BOARD_WRITE_ONLY_CYCLES) {
        board_write_only.draining = 1U;
        tensor_production_mode = 2U;
        mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_CONTROL, 0U);
        mmio_fence();
    }
    if (board_write_only.draining == 0U || tensor_production_mode != 0U)
        return;

    uint64_t elapsed = read_cycle() - board_write_only.start_cycle;
    uint32_t beats = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_W_TRANSFER) -
        board_write_only.write_beats;
    uint32_t bursts = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_BURSTS) -
        board_write_only.write_bursts;
    uint32_t completed = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_COMPLETED) -
        board_write_only.write_completed;
    uint32_t starvation = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_STARVATION) -
        board_write_only.write_starvation;
    uint32_t aw_stall = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_AW_STALL) -
        board_write_only.write_aw_stall;
    uint32_t w_stall = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_W_STALL) -
        board_write_only.write_w_stall;
    uint32_t b_wait = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_DMA_B_WAIT) -
        board_write_only.write_b_wait;
    uint64_t bytes = (uint64_t)beats * UINT64_C(32);

    mmio_write32(FRAMEBUFFER_BASE +
                 FRAMEBUFFER_TENSOR_PROD_ADMISSION_LIMIT,
                 board_write_only.saved_admission_limit);
    mmio_fence();
    board_write_only.active = 0U;
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

int main(void)
{
    int video_status;
    console_init();
    console_puts("\r\n8x OV7670 -> shared DMA -> DDR -> HDMI TX\r\n");
    console_puts("CH1-CH8 local + CH9-CH16 HDMI in 4x4 1080p60 mosaic\r\n");
    console_puts("All OV7670 initialization is hardware controlled\r\n");
#ifdef FBUS_BANDWIDTH_DIAGNOSTIC
    console_puts("Dedicated FBus bandwidth diagnostic firmware\r\n");
#endif

    video_status = video_service_init();
    if (video_status != 0)
        console_puts("Video pipeline initialization failed; press r to retry\r\n");
    tensor_production_init();
    ai_batch_runtime_init();
    if (ai_runtime_bridge_init() != 0)
        console_puts("AI runtime initialization failed\r\n");
    print_help();

    for (;;) {
        video_service_poll();
        ai_batch_runtime_poll();
        board_bandwidth_service();
        tensor_production_service();
        board_write_only_service();
        int command = console_getc_nonblock();
        if (tensor_production_mode != 0U && command >= 0 &&
            command != 'm' && command != 's' && command != 'h') {
            console_puts("TENSOR PROD active; press m and wait for drain\r\n");
            continue;
        }
        switch (command) {
#ifdef AI_MODEL_YOLOV5NU
        case 't':
        case 'u':
        case 'U':
        case 'T':
            if (ai_batch_runtime_is_idle() == 0U ||
                tensor_production_mode != 0U ||
                board_bandwidth.active != 0U ||
                board_write_only.active != 0U) {
                console_puts("YOLOV5NU TEST: wait for AI and bandwidth tests to drain\r\n");
                break;
            }
            if (command == 't')
                (void)ai_yolov5nu_correctness_test();
            else if (command == 'u' || command == 'U')
                (void)ai_yolov5nu_sequential_correctness_test(command == 'U');
            else
                (void)ai_yolov5nu_graph_post_benchmark();
            break;
#endif
        case 'C':
            board_raw_concurrent_begin();
            break;
        case 'R':
            board_read_bandwidth_begin();
            break;
        case 'W':
            board_write_only_begin();
            break;
        case 'o': {
            int result = ai_overlay_draw_test_pattern();
            console_puts(result == 0 ?
                         "OVERLAY TEST: CH1-CH16 boxes submitted\r\n" :
                         "OVERLAY TEST: submit failed\r\n");
            break;
        }
        case 'b':
            board_bandwidth_begin();
            break;
        case 's':
            ai_batch_runtime_print_status();
            break;
        case 'p':
            if (ai_batch_runtime_is_enabled() != 0U ||
                ai_batch_runtime_is_idle() == 0U)
                console_puts("AI FRAME PROFILE: disable AI and wait for drain first\r\n");
            else
                ai_batch_runtime_print_frame_profiles();
            break;
        case 'm':
            tensor_production_toggle();
            break;
        case 'i':
            if (tensor_production_mode != 0U &&
                ai_batch_runtime_is_enabled() == 0U) {
                console_puts("TENSOR PROD active; press m and wait for drain\r\n");
                break;
            }
            ai_batch_runtime_set_enabled(!ai_batch_runtime_is_enabled());
            console_puts(ai_batch_runtime_is_enabled() != 0U ?
                         "AI stream runtime enabled\r\n" :
                         "AI stream runtime draining\r\n");
            break;
        case 'r':
            hdmi_tx_restart();
            video_status = video_service_init();
            if (video_status != 0)
                console_puts("Video pipeline initialization failed; press r to retry\r\n");
            else
                console_puts("Video pipeline ready\r\n");
            break;
        case 'c': {
            uint16_t device_id = 0U;
            int result = clock_chip_read_id(&device_id);
            console_puts("8T49N241 ID=");
            console_put_hex32(device_id);
            console_puts(result == CLOCK_CHIP_OK ? " OK\r\n" : " ERROR\r\n");
            break;
        }
        case 'h':
        case '?':
            print_help();
            break;
        default:
            break;
        }
    }
}
