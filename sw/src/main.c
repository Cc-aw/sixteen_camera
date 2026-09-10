#include <stdint.h>

#include "ai_batch_runtime.h"
#include "ai_frame_snapshot.h"
#include "ai_overlay.h"
#include "ai_postprocess_diag.h"
#include "ai_preprocess.h"
#include "ai_runtime_bridge.h"
#include "camera_config.h"
#include "camera_video.h"
#include "clock_chip.h"
#include "console.h"
#include "hdmi_tx.h"
#include "tinyyolov2_runtime.h"
#include "video_service.h"

static void print_help(void)
{
    console_puts("Commands: s=status, o=fixed overlay box, d=builtin dog inference, a=snapshot, p=preprocess+RGB stats, f=preprocess format, i=AI input runtime, b=BIST, r=restart, c=clock ID, h=help\r\n");
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
        case 'i':
            if (ai_batch_runtime_is_enabled() == 0U &&
                ai_preprocess_get_format() != AI_PREPROCESS_FORMAT_416X416) {
                console_puts("AI runtime currently requires 416x416; select format 0 first\r\n");
                break;
            }
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
