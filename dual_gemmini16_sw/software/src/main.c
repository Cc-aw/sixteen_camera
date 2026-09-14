#include <stdint.h>

#include "ai_batch_runtime.h"
#include "ai_frame_snapshot.h"
#include "ai_model_backend.h"
#include "ai_overlay.h"
#include "ai_postprocess_diag.h"
#include "ai_preprocess.h"
#include "ai_runtime_bridge.h"
#ifdef AI_MODEL_YOLOV5NU
#include "ai_yolov5nu_selftest.h"
#endif
#include "camera_config.h"
#include "camera_video.h"
#include "clock_chip.h"
#include "console.h"
#include "hdmi_tx.h"
#include "platform.h"
#include "tinyyolov2_runtime.h"
#include "video_service.h"

#define AI_POST_BANDWIDTH_ITERATIONS UINT32_C(256)
#define AI_POST_PLATFORM_GATE_MBPS   UINT32_C(600)

typedef struct {
    uint32_t active;
    AiBatchRuntimeStatus runtime_start;
    AiModelPeStats pe_start;
} AiPostprocessBandwidthUiState;

static AiPostprocessBandwidthUiState bandwidth_test;

static void print_help(void)
{
    console_puts("Commands: s=status, o=fixed overlay box, d=builtin dog inference, t=YOLOv5nu dual correctness, a=snapshot, p=preprocess+RGB stats, v=PP coherence stress, w=PP concurrent bandwidth, f=preprocess format, i=AI input runtime, b=BIST, r=restart, c=clock ID, h=help\r\n");
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

static void ai_print_ch1_tensor_stats(const AiPreprocessResult *result)
{
    if ((result->valid_mask & UINT32_C(1)) == 0U) {
        console_puts("AI PRE CH1 tensor unavailable\r\n");
        return;
    }

    const uint8_t *tensor = (const uint8_t *)AI_DDR_CPU_ALIAS(
        result->tensor_base);
    uint32_t minimum[3] = {255U, 255U, 255U};
    uint32_t maximum[3] = {0U, 0U, 0U};
    uint32_t sum[3] = {0U, 0U, 0U};
    uint32_t nonzero = 0U;
    uint32_t hash = UINT32_C(2166136261);
    const uint32_t pixels = UINT32_C(416) * UINT32_C(416);

    for (uint32_t pixel = 0U; pixel < pixels; ++pixel) {
        for (uint32_t channel = 0U; channel < 3U; ++channel) {
            uint32_t value = tensor[pixel * 3U + channel];
            if (value < minimum[channel])
                minimum[channel] = value;
            if (value > maximum[channel])
                maximum[channel] = value;
            sum[channel] += value;
            nonzero += value != 0U;
            hash ^= value;
            hash *= UINT32_C(16777619);
        }
    }

    console_puts("AI PRE CH1 RGB min/max/avg=");
    for (uint32_t channel = 0U; channel < 3U; ++channel) {
        if (channel != 0U)
            console_putc(' ');
        console_put_u32(minimum[channel]);
        console_putc('/');
        console_put_u32(maximum[channel]);
        console_putc('/');
        console_put_u32(sum[channel] / pixels);
    }
    console_puts(" nonzero/hash=");
    console_put_u32(nonzero);
    console_putc('/');
    console_put_hex32(hash);
    console_puts("\r\n");
}

static void ai_validate_ch1_postprocess_reader(const AiPreprocessResult *input)
{
    AiPostprocessDiagResult result;
    const uint8_t *tensor;
    uint32_t byte_sum = 0U;
    uint32_t nonzero = 0U;

    if ((input->valid_mask & UINT32_C(1)) == 0U)
        return;
    if (ai_postprocess_diag_probe() != 0) {
        console_puts("AI POST reader unavailable\r\n");
        return;
    }

    tensor = (const uint8_t *)AI_DDR_CPU_ALIAS(input->tensor_base);
    for (uint32_t index = 0U; index < TENSOR_MEMBER_BYTES; ++index) {
        byte_sum += tensor[index];
        nonzero += tensor[index] != 0U;
    }
    uint32_t expected_crc = ai_postprocess_crc32(tensor,
                                                  TENSOR_MEMBER_BYTES);
    int status = ai_postprocess_diag_run(input->tensor_base,
                                         TENSOR_MEMBER_BYTES, &result);
    if (status != 0) {
        console_puts("AI POST reader failed=");
        console_put_u32((uint32_t)(-status));
        console_puts(" flags=");
        console_put_hex32(result.error_flags);
        console_puts("\r\n");
        return;
    }

    int passed = result.crc32 == expected_crc &&
                 result.byte_sum == byte_sum &&
                 result.nonzero_count == nonzero &&
                 result.bytes_read == TENSOR_MEMBER_BYTES;
    console_puts(passed != 0 ? "AI POST reader PASS crc/readB/ar/beats=" :
                               "AI POST reader MISMATCH crc/readB/ar/beats=");
    console_put_hex32(result.crc32);
    console_putc('/');
    console_put_u32(result.bytes_read);
    console_putc('/');
    console_put_u32(result.ar_requests);
    console_putc('/');
    console_put_u32(result.read_beats);
    console_puts("\r\n");
}

static void ai_preprocess_smoke_test(void)
{
    static AiFrameSnapshot snapshot;
    AiPreprocessResult result;
    int status = ai_frame_snapshot_acquire(&snapshot);
    if (status != 0) {
        console_puts("AI PRE snapshot failed\r\n");
        return;
    }

    status = ai_preprocess_run(&result);
    int release_status = ai_frame_snapshot_release(snapshot.valid_mask);
    if (status != 0) {
        console_puts("AI PRE failed=");
        console_put_u32((uint32_t)(-status));
        console_puts(release_status == 0 ? " refs released\r\n" :
                                           " ref release failed\r\n");
        return;
    }

    console_puts("AI PRE arena/base batch valid/fresh=");
    console_put_u32(result.arena);
    console_putc('/');
    console_put_hex32(result.tensor_base);
    console_putc(' ');
    console_put_hex64(result.batch_id);
    console_putc(' ');
    console_put_hex32(result.valid_mask);
    console_putc('/');
    console_put_hex32(result.fresh_mask);
    console_puts(" cycles/readB/writeB=");
    console_put_u32(result.cycles);
    console_putc('/');
    console_put_u32(result.read_beats * 32U);
    console_putc('/');
    console_put_u32(result.write_beats * 32U);
    console_puts("\r\n");

    ai_print_ch1_tensor_stats(&result);
    ai_validate_ch1_postprocess_reader(&result);

    status = ai_preprocess_recycle(UINT32_C(1) << result.arena);
    console_puts(status == 0 ? "AI PRE arena recycled\r\n" :
                              "AI PRE recycle failed\r\n");
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

static void ai_postprocess_bandwidth_begin(void)
{
    if (bandwidth_test.active != 0U) {
        console_puts("AI POST bandwidth test already running\r\n");
        return;
    }
    if (ai_batch_runtime_is_enabled() == 0U) {
        console_puts("AI POST bandwidth requires active AI runtime; press i first\r\n");
        return;
    }

    console_puts("AI POST bandwidth prepare bytes/iterations=");
    console_put_u32(AI_MODEL_OUTPUT_TENSOR_BYTES);
    console_putc('/');
    console_put_u32(AI_POST_BANDWIDTH_ITERATIONS);
    console_puts("\r\n");
    int status = ai_postprocess_bandwidth_start(
        AI_POST_BANDWIDTH_ITERATIONS);
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
    passed = status > 0 && mbps >= AI_POST_PLATFORM_GATE_MBPS &&
             result.crc_mismatches == 0U && result.timeout_count == 0U &&
             result.axi_error_count == 0U &&
             result.r_backpressure_cycles == 0U &&
             result.max_outstanding_observed > 1U &&
             result.max_reorder_occupancy > 1U &&
             (result.active_id_mask_observed & UINT32_C(0xff)) ==
                 UINT32_C(0xff) &&
             preprocess_delta != 0U && job_delta != 0U &&
             busy_skip_delta != 0U;

    console_puts(passed != 0U ?
        "AI POST bandwidth PLATFORM PASS MBps/bytes/cycles=" :
        "AI POST bandwidth PLATFORM NO-GO MBps/bytes/cycles=");
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
    ai_batch_runtime_init();
    if (ai_runtime_bridge_init() != 0)
        console_puts("AI runtime initialization failed\r\n");
    print_help();

    for (;;) {
        video_service_poll();
        ai_batch_runtime_poll();
        ai_postprocess_bandwidth_service();
        int command = console_getc_nonblock();
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
        case 'a':
            if (ai_batch_runtime_is_idle() != 0U)
                ai_snapshot_smoke_test();
            else
                console_puts("AI runtime busy; disable and wait for drain\r\n");
            break;
        case 'p':
            if (ai_batch_runtime_is_idle() != 0U)
                ai_preprocess_smoke_test();
            else
                console_puts("AI runtime busy; disable and wait for drain\r\n");
            break;
        case 'v':
            if (ai_batch_runtime_is_idle() != 0U)
                ai_postprocess_coherence_test();
            else
                console_puts("AI runtime busy; disable and wait for drain\r\n");
            break;
        case 'w':
            ai_postprocess_bandwidth_begin();
            break;
        case 'i':
#ifdef AI_MODEL_YOLOV5NU
            if (ai_batch_runtime_is_enabled() == 0U &&
                ai_preprocess_get_format() != AI_PREPROCESS_FORMAT_640X480) {
                console_puts("AI runtime currently requires 640x480; select format 1 first\r\n");
                break;
            }
#else
            if (ai_batch_runtime_is_enabled() == 0U &&
                ai_preprocess_get_format() != AI_PREPROCESS_FORMAT_416X416) {
                console_puts("AI runtime currently requires 416x416; select format 0 first\r\n");
                break;
            }
#endif
            ai_batch_runtime_set_enabled(!ai_batch_runtime_is_enabled());
            console_puts(ai_batch_runtime_is_enabled() != 0U ?
                         "AI input runtime enabled\r\n" :
                         "AI input runtime draining\r\n");
            break;
        case 'f': {
            if (ai_batch_runtime_is_enabled() != 0U ||
                ai_batch_runtime_is_idle() == 0U) {
                console_puts("AI runtime busy; disable and wait for drain\r\n");
                break;
            }
            AiPreprocessFormat next = ai_preprocess_get_format() ==
                                      AI_PREPROCESS_FORMAT_416X416 ?
                                      AI_PREPROCESS_FORMAT_640X480 :
                                      AI_PREPROCESS_FORMAT_416X416;
            int format_status = ai_preprocess_set_format(next);
            if (format_status == 0) {
                console_puts(next == AI_PREPROCESS_FORMAT_416X416 ?
                             "AI preprocess format 416x416\r\n" :
                             "AI preprocess format 640x480\r\n");
            } else {
                console_puts("AI preprocess format change failed=");
                console_put_u32((uint32_t)(-format_status));
                console_puts("\r\n");
            }
            break;
        }
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
