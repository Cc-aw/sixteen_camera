#include "app/command.h"
#include "app/mode_manager.h"
#include "diagnostics/board_bandwidth.h"
#include "diagnostics/tensor_production.h"
#include "diagnostics/runtime_diagnostics.h"
#include "diagnostics/ai_postprocess_diag.h"
#include "diagnostics/ai_yolov5nu_selftest.h"
#include "ai/postprocess/ai_overlay.h"
#include "video/hdmi_tx.h"
#include "video/video_service.h"
#include "clock_chip.h"
#include "platform/console.h"

void app_print_help(void)
{
#ifdef TENSOR_INGRESS_STATS
    console_puts("g=SoC Tensor ingress snapshot (repeat after >=10s for completed MB/s), ");
#endif
#if YOLO32_LIVE && YOLO32_CAPACITY_EXPERIMENT
    console_puts("v26: fixed-image correctness/timing tests use the separate triple32_v26_benchmark ELF. Commands: ");
#elif YOLO32_LIVE
    console_puts("V17A: fixed-image correctness/timing tests use the separate triple32_v17a_benchmark ELF. Commands: ");
#else
    console_puts("Commands: t=fixed image all-worker Gemmini test, u/U=fixed image sequential Gemmini test (forward/reverse), T=fixed image Gemmini+PPU test, ");
#endif
    console_puts("R=FBus read-only BW, W=tensor write-only BW (10s), C=raw tensor/FBus concurrent BW, b=AI concurrent BW, s=AI status, v=video status, o=overlay test, p=profile, P=PPU phases, m=tensor soak, i=AI runtime, r=restart, c=clock ID, h=help\r\n");
}

void app_dispatch_command(int command)
{
    int video_status;
    if (!app_mode_command_allowed(command)) {
        console_puts("TENSOR PROD active; press m and wait for drain\r\n");
        return;
    }
    switch (command) {
#ifdef TENSOR_INGRESS_STATS
    case 'g':
        tensor_ingress_print_stats();
        break;
#endif
    case 't':
    case 'u':
    case 'U':
    case 'T':
        if (!app_mode_selftest_allowed()) {
            console_puts("YOLOV5NU TEST: wait for AI and bandwidth tests to drain\r\n");
            break;
        }
#if YOLO32_LIVE && YOLO32_CAPACITY_EXPERIMENT
        console_puts("v26: use the triple32_v26_benchmark ELF for three-image correctness and timing tests\r\n");
#elif YOLO32_LIVE
        console_puts("V17A: use the triple32_v17a_benchmark ELF for three-image correctness and timing tests\r\n");
#else
        if (command == 't')
            (void)ai_yolov5nu_correctness_test();
        else if (command == 'u' || command == 'U')
            (void)ai_yolov5nu_sequential_correctness_test(command == 'U');
        else
            (void)ai_yolov5nu_graph_post_benchmark();
#endif
        break;
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
        rt_diagnostics_print_status();
        break;
    case 'v':
        hdmi_tx_print_status();
        break;
    case 'P':
        ai_postprocess_ppu_print_profile();
        break;
    case 'p':
        if (rt_is_enabled() != 0U ||
            rt_is_idle() == 0U)
            console_puts("AI FRAME PROFILE: disable AI and wait for drain first\r\n");
        else
            rt_diagnostics_print_frame_profiles();
        break;
    case 'm':
        tensor_production_toggle();
        break;
    case 'i':
        app_mode_toggle_runtime();
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
        app_print_help();
        break;
    default:
        break;
    }
}
