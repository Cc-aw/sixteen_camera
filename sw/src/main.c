#include <stdint.h>

#include "ai_batch_runtime.h"
#include "ai_frame_snapshot.h"
#include "ai_model_backend.h"
#include "ai_overlay.h"
#include "ai_postprocess_diag.h"
#include "ai_runtime_bridge.h"
#ifdef AI_MODEL_YOLOV5NU
#include "ai_yolov5nu_selftest.h"
#endif
#include "camera_config.h"
#include "camera_video.h"
#include "clock_chip.h"
#include "console.h"
#include "hdmi_tx.h"
#include "mmio.h"
#include "platform.h"
#include "tinyyolov2_runtime.h"
#include "video_service.h"

#define AI_POST_BANDWIDTH_ITERATIONS UINT32_C(256)
#define AI_POST_SWEEP_ITERATIONS     UINT32_C(16)
#define AI_POST_PLATFORM_GATE_MBPS   UINT32_C(600)

typedef struct {
    uint32_t active;
    AiBatchRuntimeStatus runtime_start;
    AiModelPeStats pe_start;
    uint32_t sweep;
    uint32_t sweep_index;
} AiPostprocessBandwidthUiState;

static const uint16_t ai_post_burst_sweep_bytes[] = {
    64U, 128U, 256U, 512U, 1024U, 2048U, 4096U
};

static AiPostprocessBandwidthUiState bandwidth_test;
static uint32_t tensor_sidecar_channel;
static uint32_t tensor_sidecar_test_active;
static uint32_t tensor_sidecar_seen_clear;
static uint32_t tensor_production_mode;
static uint32_t tensor_production_done[VIDEO_CHANNEL_COUNT];
static uint32_t tensor_production_last_frame[VIDEO_CHANNEL_COUNT];
static uint64_t tensor_production_report_cycle;

static void print_help(void)
{
    console_puts("Commands: s=status, o=overlay, d=dog inference, t=YOLOv5nu dual test, T=postprocess speed, a=snapshot, n=stream tensor capture, N=next tensor channel, m=16-stream tensor soak, v=PP coherence, w=PP bandwidth, W=PP burst sweep, i=stream AI runtime, b=BIST, r=restart, c=clock ID, h=help\r\n");
}

static void ai_overlay_fixed_box_test(void)
{
    static const AiDetectionResult test_result = {
        .stream_id = 0U,
        .count = 1U,
        .detections = {{
            .x_min = 64,
            .y_min = 64,
            .x_max = 352,
            .y_max = 352,
            .score_q15 = 32767U,
            .class_id = 11U
        }}
    };

    if (ai_batch_runtime_is_enabled() != 0U ||
        ai_batch_runtime_is_idle() == 0U) {
        console_puts("OVERLAY TEST: press i to disable AI and wait for drain first\r\n");
        return;
    }

    int status = ai_overlay_try_submit(&test_result);
    if (status > 0)
        console_puts("OVERLAY TEST committed: CH1 dog label model_xyxy=64,64,352,352\r\n");
    else if (status == 0)
        console_puts("OVERLAY TEST busy; press o again\r\n");
    else
        console_puts("OVERLAY TEST submit failed\r\n");
}

static void ai_builtin_dog_test(void)
{
#ifdef AI_MODEL_YOLOV5NU
    console_puts("DOG TEST belongs to the TinyYOLOv2 build; use make AI_MODEL=yolov2\r\n");
#else
    if (ai_batch_runtime_is_enabled() != 0U ||
        ai_batch_runtime_is_idle() == 0U) {
        console_puts("DOG TEST: press i to disable AI and wait for drain first\r\n");
        return;
    }

    console_puts("DOG TEST begin (embedded validated dog.jpg tensor)\r\n");
    int passed = tinyyolov2_run_builtin_dog();
    tinyyolov2_set_diagnostics(0);
    console_puts(passed != 0 ?
                 "DOG TEST PASS: dog detected\r\n" :
                 "DOG TEST FAIL: dog not detected\r\n");
#endif
}

static void ai_snapshot_smoke_test(void)
{
    static AiFrameSnapshot snapshot;
    int result = ai_frame_snapshot_acquire(&snapshot);
    if (result != 0) {
        console_puts("AI SNAP acquire failed=");
        console_put_u32((uint32_t)(-result));
        console_puts("\r\n");
        return;
    }

    console_puts("AI SNAP batch=");
    console_put_hex64(snapshot.batch_id);
    console_puts(" valid/fresh=");
    console_put_hex32(snapshot.valid_mask);
    console_putc('/');
    console_put_hex32(snapshot.fresh_mask);
    console_puts("\r\n");

    for (uint32_t channel = 0U; channel < VIDEO_CHANNEL_COUNT; ++channel) {
        if ((snapshot.valid_mask & (UINT32_C(1) << channel)) == 0U)
            continue;
        const AiFrameMetadata *member = &snapshot.members[channel];
        console_puts("  AI CH");
        console_put_u32(channel + 1U);
        console_puts(" addr/frame/ver=");
        console_put_hex32(member->frame_addr);
        console_putc('/');
        console_put_hex64(member->frame_id);
        console_putc('/');
        console_put_hex32(member->version);
        console_puts("\r\n");
    }

    result = ai_frame_snapshot_release(snapshot.valid_mask);
    console_puts(result == 0 ? "AI SNAP release OK\r\n" :
                            "AI SNAP release FAILED\r\n");
}

static void ai_postprocess_coherence_test(void)
{
    AiPostprocessDiagStressResult result;
    const uint32_t iterations = 1000U;

    console_puts("AI POST coherence stress begin iterations=");
    console_put_u32(iterations);
    console_puts("\r\n");
    int status = ai_postprocess_diag_coherence_stress(iterations, &result);
    if (status != 0) {
        console_puts("AI POST coherence FAIL completed/iteration/status=");
        console_put_u32(result.iterations_completed);
        console_putc('/');
        console_put_u32(result.failed_iteration);
        console_putc('/');
        console_put_u32((uint32_t)(-result.status));
        console_puts(" expected/observed/flags=");
        console_put_hex32(result.expected_crc32);
        console_putc('/');
        console_put_hex32(result.observed_crc32);
        console_putc('/');
        console_put_hex32(result.error_flags);
        console_puts("\r\n");
        return;
    }

    console_puts("AI POST coherence PASS iterations/avg/max cycles=");
    console_put_u32(result.iterations_completed);
    console_putc('/');
    console_put_u32((uint32_t)(result.total_cycles / iterations));
    console_putc('/');
    console_put_u32((uint32_t)result.maximum_cycles);
    console_puts("\r\n");
}

static void ai_postprocess_bandwidth_begin(uint32_t sweep)
{
    uint32_t iterations = sweep != 0U ? AI_POST_SWEEP_ITERATIONS :
                                       AI_POST_BANDWIDTH_ITERATIONS;
    uint32_t burst_bytes = sweep != 0U ? ai_post_burst_sweep_bytes[0] :
                                        UINT32_C(64);
    if (bandwidth_test.active != 0U) {
        console_puts("AI POST bandwidth test already running\r\n");
        return;
    }
    if (ai_batch_runtime_is_enabled() == 0U) {
        console_puts("AI POST bandwidth requires active AI runtime; press i first\r\n");
        return;
    }

    console_puts(sweep != 0U ?
        "AI POST burst sweep prepare bytes/iterations/burstB=" :
        "AI POST bandwidth prepare bytes/iterations/burstB=");
    console_put_u32(AI_MODEL_OUTPUT_TENSOR_BYTES);
    console_putc('/');
    console_put_u32(iterations);
    console_putc('/');
    console_put_u32(burst_bytes);
    console_puts("\r\n");
    int status = ai_postprocess_bandwidth_start(iterations, burst_bytes);
    if (status != 0) {
        if (status == -2 || status == -3) {
            console_puts("AI POST identity id/cap/expected=");
            console_put_hex32(ai_postprocess_diag_read_id());
            console_putc('/');
            console_put_hex32(ai_postprocess_diag_read_capability());
            console_putc('/');
            console_put_hex32(AI_POSTPROCESS_DIAG_ID);
            console_putc('/');
            console_put_hex32(AI_POSTPROCESS_DIAG_P1C_CAPABILITY);
            console_puts("\r\n");
        }
        if (status == -3)
            console_puts("AI POST bandwidth requires P1C bitstream capability\r\n");
        console_puts("AI POST bandwidth start failed=");
        console_put_u32((uint32_t)(-status));
        console_puts("\r\n");
        return;
    }
    ai_batch_runtime_get_status(&bandwidth_test.runtime_start);
    ai_model_backend_get_pe_stats(&bandwidth_test.pe_start);
    bandwidth_test.active = 1U;
    bandwidth_test.sweep = sweep;
    bandwidth_test.sweep_index = 0U;
    console_puts("AI POST bandwidth running with preprocess + Gemmini DMA\r\n");
}

static void ai_postprocess_bandwidth_service(void)
{
    AiPostprocessBandwidthResult result;
    AiBatchRuntimeStatus runtime_end;
    AiModelPeStats pe_end;
    uint32_t mbps;
    uint32_t efficiency_permille;
    uint32_t preprocess_delta;
    uint32_t job_delta;
    uint32_t busy_skip_delta;
    uint32_t passed;

    if (bandwidth_test.active == 0U)
        return;
    int status = ai_postprocess_bandwidth_poll(&result);
    if (status == 0)
        return;

    bandwidth_test.active = 0U;
    ai_batch_runtime_get_status(&runtime_end);
    ai_model_backend_get_pe_stats(&pe_end);
    preprocess_delta = runtime_end.preprocess_count -
                       bandwidth_test.runtime_start.preprocess_count;
    job_delta = runtime_end.completed_job_count -
                bandwidth_test.runtime_start.completed_job_count;
    busy_skip_delta = pe_end.coherence_busy_skips -
                      bandwidth_test.pe_start.coherence_busy_skips;
    mbps = result.active_cycles == 0U ? 0U :
        (uint32_t)((result.bytes_read * (SOC_CLOCK_HZ / UINT64_C(1000000))) /
                   result.active_cycles);
    efficiency_permille = result.read_beats == 0U ? 0U :
        (uint32_t)((result.bytes_read * UINT64_C(1000)) /
                   (result.read_beats * UINT64_C(32)));
    passed = status > 0 &&
             result.iterations_completed == result.iterations_requested && mbps >= AI_POST_PLATFORM_GATE_MBPS &&
             result.crc_mismatches == 0U && result.timeout_count == 0U &&
             result.axi_error_count == 0U &&
             result.r_backpressure_cycles == 0U &&
             result.max_outstanding_observed > 1U &&
             result.max_reorder_occupancy > 1U &&
             (result.active_id_mask_observed & UINT32_C(0xff)) ==
                 UINT32_C(0xff) &&
             preprocess_delta != 0U && job_delta != 0U;

    if (bandwidth_test.sweep != 0U)
        console_puts("AI POST burst POINT burstB/MBps/bytes/cycles=");
    else
        console_puts(passed != 0U ?
            "AI POST bandwidth PLATFORM PASS burstB/MBps/bytes/cycles=" :
            "AI POST bandwidth PLATFORM NO-GO burstB/MBps/bytes/cycles=");
    console_put_u32(result.burst_bytes);
    console_putc('/');
    console_put_u32(mbps);
    console_putc('/');
    console_put_hex64(result.bytes_read);
    console_putc('/');
    console_put_hex64(result.active_cycles);
    console_puts("\r\nAI POST bandwidth stall(ar/rwait/rbp)=" );
    console_put_hex64(result.ar_stall_cycles);
    console_putc('/');
    console_put_hex64(result.r_wait_cycles);
    console_putc('/');
    console_put_hex64(result.r_backpressure_cycles);
    console_puts(" bursts/beats/eff_permille=");
    console_put_hex64(result.ar_requests);
    console_putc('/');
    console_put_hex64(result.read_beats);
    console_putc('/');
    console_put_u32(efficiency_permille);
    console_puts(" max_outstanding=");
    console_put_u32(result.max_outstanding_observed);
    console_puts(" reorder/id_mask=");
    console_put_u32(result.max_reorder_occupancy);
    console_putc('/');
    console_put_hex32(result.active_id_mask_observed);
    console_puts("\r\nAI POST bandwidth verify(iter/crc/timeout/axi/flags)=");
    console_put_u32(result.iterations_completed);
    console_putc('/');
    console_put_u32(result.crc_mismatches);
    console_putc('/');
    console_put_u32(result.timeout_count);
    console_putc('/');
    console_put_u32(result.axi_error_count);
    console_putc('/');
    console_put_hex32(result.error_flags);
    console_puts(" crc(expected/observed)=");
    console_put_hex32(result.expected_crc32);
    console_putc('/');
    console_put_hex32(result.observed_crc32);
    console_puts(" overlap(pre/job/busy_skip/valid_mask)=");
    console_put_u32(preprocess_delta);
    console_putc('/');
    console_put_u32(job_delta);
    console_putc('/');
    console_put_u32(busy_skip_delta);
    console_putc('/');
    console_put_hex32(runtime_end.last_valid_mask);
    console_puts("\r\n");

    console_puts("AI POST bandwidth exit(code/completed/requested/busy_retries)=");
    if (status < 0) console_putc('-');
    console_put_u32((uint32_t)(status < 0 ? -status : status));
    console_putc('/');
    console_put_u32(result.iterations_completed);
    console_putc('/');
    console_put_u32(result.iterations_requested);
    console_putc('/');
    console_put_u32(result.busy_retries);
    console_puts("\r\n");

    if (bandwidth_test.sweep != 0U && status > 0 &&
        result.crc_mismatches == 0U && result.timeout_count == 0U &&
        result.axi_error_count == 0U &&
        bandwidth_test.sweep_index + 1U <
            sizeof(ai_post_burst_sweep_bytes) /
            sizeof(ai_post_burst_sweep_bytes[0])) {
        bandwidth_test.sweep_index++;
        uint32_t next_burst =
            ai_post_burst_sweep_bytes[bandwidth_test.sweep_index];
        status = ai_postprocess_bandwidth_start(
            AI_POST_SWEEP_ITERATIONS, next_burst);
        if (status == 0) {
            bandwidth_test.active = 1U;
            console_puts("AI POST burst sweep running burstB=");
            console_put_u32(next_burst);
            console_puts("\r\n");
            return;
        }
        console_puts("AI POST burst sweep restart failed=");
        console_put_u32((uint32_t)(-status));
        console_puts("\r\n");
    } else if (bandwidth_test.sweep != 0U) {
        console_puts(status > 0 ? "AI POST burst sweep DONE\r\n" :
                                  "AI POST burst sweep ABORTED\r\n");
    }
}

static void tensor_sidecar_begin_test(void)
{
    uint32_t status = mmio_read32(FRAMEBUFFER_BASE +
                                  FRAMEBUFFER_TENSOR_STATUS);
    uint32_t ai_enabled = ai_batch_runtime_is_enabled();
    uint32_t ai_idle = ai_batch_runtime_is_idle();
    if (tensor_sidecar_test_active != 0U || tensor_production_mode != 0U ||
        ai_enabled != 0U ||
        ai_idle == 0U ||
        (status & FRAMEBUFFER_TENSOR_STATUS_BUSY) != 0U) {
        console_puts("TENSOR SIDECAR blocked active/ai_enable/ai_idle/tensor=");
        console_put_u32(tensor_sidecar_test_active);
        console_putc('/');
        console_put_u32(ai_enabled);
        console_putc('/');
        console_put_u32(ai_idle);
        console_putc('/');
        console_put_hex32(status);
        console_puts("\r\n");
        return;
    }
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_CHANNEL,
                 tensor_sidecar_channel);
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_ADDR,
                 TENSOR_SIDECAR_DIAG_PHYS_BASE);
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_CONTROL, 1U);
    tensor_sidecar_test_active = 1U;
    tensor_sidecar_seen_clear = 0U;
    console_puts("TENSOR SIDECAR armed channel/address=");
    console_put_u32(tensor_sidecar_channel + 1U);
    console_putc('/');
    console_put_hex32(TENSOR_SIDECAR_DIAG_PHYS_BASE);
    console_puts("\r\n");
}


static void tensor_sidecar_service(void)
{
    if (tensor_sidecar_test_active == 0U)
        return;
    uint32_t status = mmio_read32(FRAMEBUFFER_BASE +
                                  FRAMEBUFFER_TENSOR_STATUS);
    if ((status & FRAMEBUFFER_TENSOR_STATUS_DONE) == 0U)
        tensor_sidecar_seen_clear = 1U;
    if (tensor_sidecar_seen_clear == 0U ||
        (status & FRAMEBUFFER_TENSOR_STATUS_DONE) == 0U ||
        (status & FRAMEBUFFER_TENSOR_STATUS_BUSY) != 0U)
        return;
    tensor_sidecar_test_active = 0U;
    uint32_t bytes = mmio_read32(FRAMEBUFFER_BASE +
                                 FRAMEBUFFER_TENSOR_BYTES);
    uint32_t frame_id = mmio_read32(FRAMEBUFFER_BASE +
                                    FRAMEBUFFER_TENSOR_FRAME_ID);
    uint32_t overflows = mmio_read32(FRAMEBUFFER_BASE +
                                     FRAMEBUFFER_TENSOR_OVERFLOWS);
    uint32_t hash = UINT32_C(2166136261);
    uint32_t nonzero = 0U;
    if ((status & FRAMEBUFFER_TENSOR_STATUS_ERROR) == 0U &&
        bytes == TENSOR_MEMBER_BYTES) {
        volatile const uint8_t *tensor =
            (volatile const uint8_t *)AI_DDR_CPU_ALIAS(
                TENSOR_SIDECAR_DIAG_PHYS_BASE);
        for (uint32_t index = 0U; index < bytes; ++index) {
            uint8_t value = tensor[index];
            hash = (hash ^ value) * UINT32_C(16777619);
            nonzero += value != 0U;
        }
    }
    console_puts((status & FRAMEBUFFER_TENSOR_STATUS_ERROR) == 0U &&
                 bytes == TENSOR_MEMBER_BYTES && nonzero != 0U ?
                 "TENSOR SIDECAR PASS ch/frame/bytes/hash/nonzero/overflows=" :
                 "TENSOR SIDECAR FAIL ch/frame/bytes/hash/nonzero/overflows=");
    console_put_u32(((status >> 4) & 15U) + 1U);
    console_putc('/');
    console_put_u32(frame_id);
    console_putc('/');
    console_put_u32(bytes);
    console_putc('/');
    console_put_hex32(hash);
    console_putc('/');
    console_put_u32(nonzero);
    console_putc('/');
    console_put_u32(overflows);
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
            if (channel != 0U) console_putc(',');
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
    if (tensor_sidecar_test_active != 0U ||
        ai_batch_runtime_is_enabled() != 0U ||
        ai_batch_runtime_is_idle() == 0U ||
        mmio_read32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_STATUS) &
            FRAMEBUFFER_TENSOR_STATUS_BUSY) {
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
                 FRAMEBUFFER_TENSOR_PROD_ADMISSION_LIMIT, 1U);
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
    console_puts("TENSOR PROD enabled, one capture at a time, press m to drain\r\n");
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
                 FRAMEBUFFER_TENSOR_PROD_ADMISSION_LIMIT, 1U);
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

int main(void)
{
    int video_status;
    console_init();
    console_puts("\r\n8x OV7670 -> shared DMA -> DDR -> HDMI TX\r\n");
    console_puts("CH1-CH8 local + CH9-CH16 HDMI in 4x4 1080p60 mosaic\r\n");
    console_puts("All OV7670 initialization is hardware controlled\r\n");

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
        ai_postprocess_bandwidth_service();
        tensor_sidecar_service();
        tensor_production_service();
        int command = console_getc_nonblock();
        if (tensor_production_mode != 0U && command >= 0 &&
            command != 'm' && command != 's' &&
            command != 'N' && command != 'h') {
            console_puts("TENSOR PROD active; press m and wait for drain\r\n");
            continue;
        }
        switch (command) {
        case 's':
            ai_batch_runtime_print_status();
            break;
        case 'o':
            ai_overlay_fixed_box_test();
            break;
        case 'd':
            ai_builtin_dog_test();
            break;
        case 't':
#ifdef AI_MODEL_YOLOV5NU
            if (ai_batch_runtime_is_enabled() != 0U ||
                ai_batch_runtime_is_idle() == 0U)
                console_puts("YOLOV5NU TEST: disable AI and wait for drain first\r\n");
            else
                (void)ai_yolov5nu_correctness_test();
#else
            console_puts("YOLOV5NU TEST requires the default yolov5nu build\r\n");
#endif
            break;
        case 'T':
#ifdef AI_MODEL_YOLOV5NU
            if (ai_batch_runtime_is_enabled() != 0U ||
                ai_batch_runtime_is_idle() == 0U ||
                ai_postprocess_diag_is_active() != 0U)
                console_puts("YOLOV5NU POST BENCH: disable AI and wait for drain first\r\n");
            else
                (void)ai_yolov5nu_postprocess_benchmark();
#else
            console_puts("YOLOV5NU POST BENCH requires the default yolov5nu build\r\n");
#endif
            break;
        case 'a':
            if (ai_batch_runtime_is_idle() != 0U)
                ai_snapshot_smoke_test();
            else
                console_puts("AI runtime busy; disable and wait for drain\r\n");
            break;
        case 'n':
            tensor_sidecar_begin_test();
            break;
        case 'm':
            tensor_production_toggle();
            break;
        case 'N':
            tensor_sidecar_channel =
                (tensor_sidecar_channel + 1U) % VIDEO_CHANNEL_COUNT;
            console_puts("TENSOR SIDECAR selected channel=");
            console_put_u32(tensor_sidecar_channel + 1U);
            console_puts("\r\n");
            break;
        case 'v':
            if (ai_batch_runtime_is_idle() != 0U)
                ai_postprocess_coherence_test();
            else
                console_puts("AI runtime busy; disable and wait for drain\r\n");
            break;
        case 'w':
            ai_postprocess_bandwidth_begin(0U);
            break;
        case 'W':
            ai_postprocess_bandwidth_begin(1U);
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
        case 'b': {
            const CameraConfig *ov7670 = camera_config_by_channel(1U);
            (void)camera_ov7670_run_bist(ov7670);
            break;
        }
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
