#include <stdint.h>

#include "axi_iic.h"
#include "ai_batch_runtime.h"
#include "ai_frame_snapshot.h"
#include "ai_preprocess.h"
#include "board_gpio.h"
#include "camera_config.h"
#include "camera_video.h"
#include "clock_chip.h"
#include "console.h"
#include "hdmi_tx.h"
#include "mmio.h"
#include "platform.h"
#include "sleep.h"
#define OV7670_CTRL_DONE UINT32_C(0x00080000)
#define OV7670_CTRL_FAILED UINT32_C(0x00001000)

static int camera_start(const CameraConfig *camera)
{
    if (camera == 0 || !camera->present)
        return -1;

    uint32_t ctrl_status = 0U;
    for (unsigned int timeout = 0U; timeout < 2000U; ++timeout) {
        ctrl_status = mmio_read32(camera->csi_base);
        if ((ctrl_status & (OV7670_CTRL_DONE | OV7670_CTRL_FAILED)) != 0U)
            break;
        usleep(100UL);
    }
    console_puts("OV7670 CH");
    console_put_u32(camera->global_channel);
    console_puts(" RTL status=");
    console_put_hex32(ctrl_status);
    if ((ctrl_status & OV7670_CTRL_FAILED) != 0U)
        console_puts(" FAILED\r\n");
    else
        console_puts((ctrl_status & OV7670_CTRL_DONE) != 0U
                     ? " DONE\r\n" : " TIMEOUT\r\n");
    if ((ctrl_status & OV7670_CTRL_DONE) == 0U)
        return -1;
    console_puts("OV7670 CH");
    console_put_u32(camera->global_channel);
    console_puts(" RGB565 640x480 parallel stream started\r\n");
    return 0;
}

static int start_present_cameras(void)
{
    int result = 0;
    for (size_t index = 0U; index < camera_config_count; ++index) {
        if (camera_configs[index].present &&
            camera_start(&camera_configs[index]) != 0)
            result = -1;
    }
    return result;
}

static void print_help(void)
{
    console_puts("Commands: 1-8=display, s=status, a=snapshot, p=preprocess, i=AI input runtime, t=DATA tap, b=BIST, r=restart, c=clock ID, h=help\r\n");
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

    // No Gemmini consumer is connected yet, so the smoke test immediately
    // returns the finished arena to the fixed pool.
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
    console_puts(result == 0 ? "AI SNAP release OK\r\n"
                            : "AI SNAP release FAILED\r\n");
}

int main(void)
{
    uint32_t sample_tap = 2U;
    console_init();
    console_puts("\r\n8x OV7670 -> shared DMA -> DDR -> HDMI TX\r\n");
    console_puts("CH1-CH8 local + CH9-CH16 HDMI in 4x4 1080p60 mosaic\r\n");
    console_puts("All OV7670 initialization is hardware controlled\r\n");
    console_puts("OV7670 clock/reset/SCCB translated from ztachip camera.vhd\r\n");
    console_puts("OV7670 register table: reference RGB565/AWB/AEC/gamma configuration\r\n");
    console_puts("OV7670 firmware revision: V13-8CH-BASIC\r\n");
    console_puts("Camera output: ai/ stream2native path, no DDR backpressure into CSI\r\n");
    console_puts("Camera diagnostics: OV7670 clock/reset/SCCB ACK/input geometry and pipeline counters\r\n");
    console_puts("Camera MMIO: 0x40110000 + (camera-1)*0x4000\r\n");

    board_gpio_init_safe();
    usleep(10000UL);
    board_clock_release_reset();
    usleep(10000UL);
    axi_iic_init();

    if (hdmi_tx_init() != 0)
        console_puts("Video pipeline initialization failed; press r to retry\r\n");
    if (start_present_cameras() != 0)
        console_puts("Camera initialization failed; press r to retry\r\n");
    ai_batch_runtime_init();
    print_help();

    for (;;) {
        hdmi_tx_poll();
        ai_batch_runtime_poll();
        int command = console_getc_nonblock();
        switch (command) {
        case '1':
        case '2':
        case '3':
        case '4':
        case '5':
        case '6':
        case '7':
        case '8':
            if (hdmi_tx_select_camera((unsigned)(command - '0')) != 0)
                console_puts("[video] display channel selection failed\r\n");
            break;
        case 's':
            hdmi_tx_print_status();
            ai_batch_runtime_print_status();
            for (size_t index = 0U; index < camera_config_count; ++index)
                camera_video_print_status(&camera_configs[index]);
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
            ai_batch_runtime_set_enabled(!ai_batch_runtime_is_enabled());
            console_puts(ai_batch_runtime_is_enabled() != 0U ?
                         "AI input runtime enabled\r\n" :
                         "AI input runtime draining\r\n");
            break;
        case 't':
            sample_tap = (sample_tap + 1U) % 6U;
            for (size_t index = 0U; index < camera_config_count; ++index)
                camera_video_set_sample_tap(&camera_configs[index], sample_tap);
            console_puts("[camera] DATA sample tap=");
            console_put_u32(sample_tap);
            console_puts("\r\n");
            break;
        case 'r':
            hdmi_tx_restart();
            (void)start_present_cameras();
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
