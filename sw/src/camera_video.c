#include "camera_video.h"

#include "console.h"
#include "mmio.h"

#define OV_STATUS          0x00U
#define OV_PCLK_STATUS     0x08U
#define OV_FRAME_COUNT     0x0CU
#define OV_OVERFLOW_COUNT  0x10U
#define OV_GEOMETRY        0x14U
#define OV_LOCK_LOSS_COUNT 0x18U
#define OV_SCCB_ERROR      0x1CU

void camera_video_print_status(const CameraConfig *camera)
{
    if (camera == 0 || !camera->present)
        return;

    uint32_t status = mmio_read32(camera->csi_base + OV_STATUS);
    uint32_t pclk = mmio_read32(camera->csi_base + OV_PCLK_STATUS);
    uint32_t frames = mmio_read32(camera->csi_base + OV_FRAME_COUNT);
    uint32_t overflow = mmio_read32(camera->csi_base + OV_OVERFLOW_COUNT);
    uint32_t geometry = mmio_read32(camera->csi_base + OV_GEOMETRY);
    uint32_t lock_loss = mmio_read32(camera->csi_base + OV_LOCK_LOSS_COUNT);
    uint32_t sccb_error = mmio_read32(camera->csi_base + OV_SCCB_ERROR);

    console_puts("CAM CH");
    console_put_u32(camera->global_channel);
    console_puts(" init=");
    if (((status >> 12) & 1U) != 0U)
        console_puts("FAIL");
    else if (((status >> 19) & 1U) != 0U)
        console_puts("OK");
    else
        console_puts("WAIT");
    console_puts(" frames=");
    console_put_u32(frames);
    console_puts(" size=");
    console_put_u32(geometry & UINT32_C(0xffff));
    console_putc('x');
    console_put_u32(geometry >> 16);
    console_puts(" pclk(lock/state/period)=");
    console_put_u32((pclk >> 1) & 1U);
    console_putc('/');
    console_put_u32((pclk >> 2) & 3U);
    console_putc('/');
    console_put_u32((pclk >> 4) >> 8);
    console_puts(" lock_loss=");
    console_put_u32(lock_loss);
    console_puts(" overflow=");
    console_put_u32(overflow);
    if (sccb_error != 0U) {
        console_puts(" sccb_error=");
        console_put_hex32(sccb_error);
    }
    console_puts("\r\n");
}

int camera_video_snapshot(const CameraConfig *camera)
{
    return (camera != 0 && camera->present) ? 0 : -1;
}
