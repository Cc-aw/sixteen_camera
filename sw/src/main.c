#include <stdint.h>

#include "ai_batch_runtime.h"
#include "ai_runtime_bridge.h"
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

static void print_help(void)
{
    console_puts("Commands: s=status, p=per-frame profile, m=16-stream tensor soak, i=stream AI runtime, r=restart, c=clock ID, h=help\r\n");
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
        tensor_production_service();
        int command = console_getc_nonblock();
        if (tensor_production_mode != 0U && command >= 0 &&
            command != 'm' && command != 's' && command != 'h') {
            console_puts("TENSOR PROD active; press m and wait for drain\r\n");
            continue;
        }
        switch (command) {
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
