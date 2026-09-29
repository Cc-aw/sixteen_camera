#include "video_service.h"

#include "axi_iic.h"
#include "board_gpio.h"
#include "camera_config.h"
#include "camera_video.h"
#include "clock_chip.h"
#include "console.h"
#include "hdmi_tx.h"
#include "mmio.h"
#include "sleep.h"

#define OV7670_CTRL_DONE   UINT32_C(0x00080000)
#define OV7670_CTRL_FAILED UINT32_C(0x00001000)

static int start_camera(const CameraConfig *camera)
{
    if (camera == 0 || !camera->present)
        return -1;
    uint32_t status = 0U;
    for (unsigned timeout = 0U; timeout < 2000U; ++timeout) {
        status = mmio_read32(camera->csi_base);
        if ((status & (OV7670_CTRL_DONE | OV7670_CTRL_FAILED)) != 0U)
            break;
        usleep(100UL);
    }
    console_puts("OV7670 CH");
    console_put_u32(camera->global_channel);
    console_puts(" RTL status=");
    console_put_hex32(status);
    console_puts((status & OV7670_CTRL_FAILED) ? " FAILED\r\n" :
                 ((status & OV7670_CTRL_DONE) ? " DONE\r\n" : " TIMEOUT\r\n"));
    if ((status & OV7670_CTRL_DONE) == 0U)
        return -1;
    console_puts("OV7670 CH");
    console_put_u32(camera->global_channel);
    console_puts(" RGB565 640x480 parallel stream started\r\n");
    return 0;
}

int video_service_start_cameras(void)
{
    int result = 0;
    for (size_t i = 0U; i < camera_config_count; ++i)
        if (camera_configs[i].present && start_camera(&camera_configs[i]) != 0)
            result = -1;
    return result;
}

int video_service_init(void)
{
    board_gpio_init_safe();
    usleep(10000UL);
    board_clock_release_reset();
    usleep(10000UL);
    axi_iic_init();
    /* Frame capture/AI must work even when no HDMI sink is connected. */
    hdmi_tx_framebuffer_init();
    int result = hdmi_tx_init();
    if (video_service_start_cameras() != 0)
        result = -1;
    return result;
}

void video_service_poll(void)
{
    hdmi_tx_poll();
}
