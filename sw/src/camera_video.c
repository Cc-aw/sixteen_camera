#include "camera_video.h"

#include "console.h"
#include "mmio.h"
#include "platform.h"
#include "sleep.h"

#define OV_BIST_CONTROL       0x3CU
#define OV_BIST_RAW_LEVELS    0x40U
#define OV_BIST_SAMPLE_COUNT  0x44U
#define OV_BIST_PCLK_EDGES    0x48U
#define OV_BIST_VSYNC_EDGES   0x4CU
#define OV_BIST_HREF_EDGES    0x50U
#define OV_BIST_HREF_PCLK     0x54U
#define OV_BIST_DATA_TOGGLE   0x6CU
#define OV_BIST_HW_STATUS     0x70U
#define OV_BIST_SIGNATURE     0x74U
#define OV_PROBE_CONTROL      0x78U
#define OV_PAD_LEVELS         0x7CU
#define OV_PAD_XCLK_EDGES     0x80U
#define OV_PAD_RESET_EDGES    0x84U
#define OV_PAD_PWDN_EDGES     0x88U
#define OV_PAD_SCL_EDGES      0x8CU
#define OV_PAD_SDA_EDGES      0x90U
#define OV_PAD_SEEN_LEVELS    0x94U
#define OV_PAD_SIGNATURE      0x98U
#define OV_HREF_RAW_COUNT     0x9CU
#define OV_HREF_QUAL_COUNT    0xA0U
#define OV_HREF_SHORT_COUNT   0xA4U
#define OV_HREF_MIN_WIDTH     0xA8U
#define OV_HREF_LAST_WIDTH    0xACU
#define OV_VSYNC_RAW_EDGES    0xB0U
#define OV_VSYNC_QUAL_EDGES   0xB4U
#define OV_VSYNC_SHORT_COUNT  0xB8U
#define OV_VSYNC_MIN_WIDTH    0xBCU
#define OV_FIFO_FULL_STALL    0xC0U
#define OV_READY_LOW          0xC4U
#define OV_FIFO_MAX_LEVEL     0xC8U
#define OV_IIC_WRITTEN        0xCCU
#define OV_IIC_RETRIES        0xD0U
#define OV_IIC_NACK_ID        0xD4U
#define OV_IIC_NACK_REGISTER  0xD8U
#define OV_IIC_NACK_DATA      0xDCU
#define OV_IIC_FAILURE        0xE0U
#define OV_PCLK_REC_CANDIDATE  0x58U
#define OV_PCLK_REC_VALID      0x5CU
#define OV_PCLK_REC_GLITCH     0x60U
#define OV_PCLK_REC_MISSING    0x64U
#define OV_PCLK_REC_STATUS     0x68U
#define OV_PCLK_REC_LOCK_LOSS  0x110U
#define OV_PCLK_REC_HOLDOVER   0x114U
#define OV_PCLK_REC_HOLD_REC   0x118U
#define OV_PCLK_REC_HARMONIC   0x11CU
#define OV_PCLK_REC_SHORT      0x120U
#define OV_PCLK_REC_PHASE_MAX  0x124U
#define OV_PCLK_REC_INTERVALS  0x128U
#define OV_PCLK_REC_UNSTABLE   0x12CU
#define OV_PCLK_SNAPSHOT_CTRL   0x130U
#define OV_PCLK_SNAPSHOT_BASE   0x134U

#define OV_CTRL_REINIT        UINT32_C(0x01)
#define OV_CTRL_XCLK_DISABLE  UINT32_C(0x02)
#define OV_CTRL_FORCE_RESET   UINT32_C(0x04)
#define OV_CTRL_FORCE_PWDN    UINT32_C(0x08)
#define OV_CTRL_MANUAL_SCCB   UINT32_C(0x10)
#define OV_CTRL_SCL_HIGH      UINT32_C(0x20)
#define OV_CTRL_SDA_RELEASE   UINT32_C(0x40)
#define OV_CTRL_CLEAR_DIAG    UINT32_C(0x80)
#define OV_RAW_SDA            UINT32_C(0x800)
#define OV_CTRL_DONE          UINT32_C(0x00080000)
#define OV_BIST_MAGIC         UINT32_C(0xB1570001)
#define OV_PAD_MAGIC          UINT32_C(0x50414432)

#define OV_PROBE_ENABLE       UINT32_C(0x01)
#define OV_PROBE_XCLK_HIGH    UINT32_C(0x02)
#define OV_PROBE_RESET_HIGH   UINT32_C(0x04)
#define OV_PROBE_PWDN_HIGH    UINT32_C(0x08)
#define OV_PROBE_SCL_HIGH     UINT32_C(0x10)
#define OV_PROBE_SDA_RELEASE  UINT32_C(0x20)
#define OV_PROBE_SAFE         (OV_PROBE_ENABLE | OV_PROBE_PWDN_HIGH | \
                               OV_PROBE_SCL_HIGH | OV_PROBE_SDA_RELEASE)
#define OV_RAW_DVP_MASK       UINT32_C(0x07FF)
#define OV_RAW_ALL_MASK       UINT32_C(0x0FFF)

#define OV_ERR_NO_BASE_PCLK   UINT32_C(0x001)
#define OV_ERR_XCLK_NO_EFFECT UINT32_C(0x002)
#define OV_ERR_PWDN_NO_EFFECT UINT32_C(0x004)
#define OV_ERR_NO_WAKE_PCLK   UINT32_C(0x008)
#define OV_ERR_ID             UINT32_C(0x010)
#define OV_ERR_VSYNC          UINT32_C(0x020)
#define OV_ERR_HREF           UINT32_C(0x040)
#define OV_ERR_VH_OVERLAP     UINT32_C(0x080)
#define OV_ERR_LINE_LENGTH    UINT32_C(0x100)
#define OV_ERR_FRAME_LINES    UINT32_C(0x200)
#define OV_ERR_PAD_READBACK   UINT32_C(0x400)
#define OV_ERR_PIN_CORRELATION UINT32_C(0x800)

struct ov7670_bist_sample {
    uint32_t samples;
    uint32_t pclk;
    uint32_t vsync;
    uint32_t href;
    uint32_t href_pclk;
    uint32_t overlap;
    uint32_t seen;
    uint32_t geometry;
    uint32_t period;
    uint32_t data_toggle;
};

static void ov_control_write(uintptr_t base, uint32_t value)
{
    mmio_write32(base + OV_BIST_CONTROL, value);
    mmio_fence();
}

static void ov_bist_sample(uintptr_t base, uint32_t control,
                           unsigned long duration_us,
                           struct ov7670_bist_sample *sample)
{
    ov_control_write(base, control | OV_CTRL_CLEAR_DIAG);
    usleep(duration_us);
    sample->samples = mmio_read32(base + OV_BIST_SAMPLE_COUNT);
    sample->pclk = mmio_read32(base + OV_BIST_PCLK_EDGES);
    sample->vsync = mmio_read32(base + OV_BIST_VSYNC_EDGES);
    sample->href = mmio_read32(base + OV_BIST_HREF_EDGES);
    sample->href_pclk = mmio_read32(base + OV_BIST_HREF_PCLK);
    sample->overlap = 0U;
    sample->seen = mmio_read32(base + OV_BIST_RAW_LEVELS);
    sample->geometry = mmio_read32(base + 0x34U);
    sample->period = mmio_read32(base + OV_PCLK_REC_STATUS) &
                     UINT32_C(0x3fff);
    sample->data_toggle = mmio_read32(base + OV_BIST_DATA_TOGGLE);
}

static int ov_wait_init(uintptr_t base)
{
    for (unsigned int timeout = 0U; timeout < 5000U; ++timeout) {
        if ((mmio_read32(base) & OV_CTRL_DONE) != 0U)
            return 0;
        usleep(100UL);
    }
    return -1;
}

static void ov_manual_set(uintptr_t base, uint32_t state)
{
    ov_control_write(base, state);
    usleep(2UL);
}

static void ov_manual_start(uintptr_t base, uint32_t *state)
{
    *state = OV_CTRL_MANUAL_SCCB | OV_CTRL_SCL_HIGH |
             OV_CTRL_SDA_RELEASE;
    ov_manual_set(base, *state);
    *state &= ~OV_CTRL_SDA_RELEASE;
    ov_manual_set(base, *state);
    *state &= ~OV_CTRL_SCL_HIGH;
    ov_manual_set(base, *state);
}

static void ov_manual_stop(uintptr_t base, uint32_t *state)
{
    *state = OV_CTRL_MANUAL_SCCB;
    ov_manual_set(base, *state);
    *state |= OV_CTRL_SCL_HIGH;
    ov_manual_set(base, *state);
    *state |= OV_CTRL_SDA_RELEASE;
    ov_manual_set(base, *state);
}

static int ov_manual_write_byte(uintptr_t base, uint32_t *state,
                                uint8_t value)
{
    for (unsigned int bit = 0U; bit < 8U; ++bit) {
        *state &= ~OV_CTRL_SCL_HIGH;
        if ((value & UINT8_C(0x80)) != 0U)
            *state |= OV_CTRL_SDA_RELEASE;
        else
            *state &= ~OV_CTRL_SDA_RELEASE;
        ov_manual_set(base, *state);
        *state |= OV_CTRL_SCL_HIGH;
        ov_manual_set(base, *state);
        value <<= 1;
    }

    *state &= ~OV_CTRL_SCL_HIGH;
    *state |= OV_CTRL_SDA_RELEASE;
    ov_manual_set(base, *state);
    *state |= OV_CTRL_SCL_HIGH;
    ov_manual_set(base, *state);
    int nack = (mmio_read32(base + OV_BIST_RAW_LEVELS) & OV_RAW_SDA) != 0U;
    *state &= ~OV_CTRL_SCL_HIGH;
    ov_manual_set(base, *state);
    return nack;
}

static uint8_t ov_manual_read_byte(uintptr_t base, uint32_t *state)
{
    uint8_t value = 0U;
    *state |= OV_CTRL_SDA_RELEASE;
    for (unsigned int bit = 0U; bit < 8U; ++bit) {
        *state &= ~OV_CTRL_SCL_HIGH;
        ov_manual_set(base, *state);
        *state |= OV_CTRL_SCL_HIGH;
        ov_manual_set(base, *state);
        value <<= 1;
        if ((mmio_read32(base + OV_BIST_RAW_LEVELS) & OV_RAW_SDA) != 0U)
            value |= 1U;
    }
    *state &= ~OV_CTRL_SCL_HIGH;
    ov_manual_set(base, *state);
    *state |= OV_CTRL_SCL_HIGH;
    ov_manual_set(base, *state);
    *state &= ~OV_CTRL_SCL_HIGH;
    ov_manual_set(base, *state);
    return value;
}

static uint8_t ov_manual_read_register(uintptr_t base, uint8_t address,
                                       uint32_t *nack_mask)
{
    uint32_t state = OV_CTRL_MANUAL_SCCB | OV_CTRL_SCL_HIGH |
                     OV_CTRL_SDA_RELEASE;
    ov_manual_set(base, state);
    ov_manual_start(base, &state);
    if (ov_manual_write_byte(base, &state, UINT8_C(0x42)) != 0)
        *nack_mask |= UINT32_C(0x01);
    if (ov_manual_write_byte(base, &state, address) != 0)
        *nack_mask |= UINT32_C(0x02);
    ov_manual_stop(base, &state);
    usleep(10UL);
    ov_manual_start(base, &state);
    if (ov_manual_write_byte(base, &state, UINT8_C(0x43)) != 0)
        *nack_mask |= UINT32_C(0x04);
    uint8_t value = ov_manual_read_byte(base, &state);
    ov_manual_stop(base, &state);
    return value;
}

static void ov_print_sccb_status(const CameraConfig *camera)
{
    uintptr_t base = camera->csi_base;
    uint32_t ctrl = mmio_read32(base);
    uint32_t writes = mmio_read32(base + OV_IIC_WRITTEN);
    uint32_t retries = mmio_read32(base + OV_IIC_RETRIES);
    uint32_t nack_id = mmio_read32(base + OV_IIC_NACK_ID);
    uint32_t nack_register = mmio_read32(base + OV_IIC_NACK_REGISTER);
    uint32_t nack_data = mmio_read32(base + OV_IIC_NACK_DATA);
    uint32_t failure = mmio_read32(base + OV_IIC_FAILURE);

    /* Keep the normal status compact.  The CAM line already reports OK;
     * print SCCB details only when they help diagnose a retry or failure. */
    if ((((ctrl >> 19) & 1U) != 0U) &&
        (((ctrl >> 12) & 1U) == 0U) && retries == 0U &&
        nack_id == 0U && nack_register == 0U && nack_data == 0U)
        return;

    console_puts("IIC CH");
    console_put_u32(camera->global_channel);
    console_puts(" state=");
    if (((ctrl >> 12) & 1U) != 0U)
        console_puts("FAILED");
    else if (((ctrl >> 19) & 1U) != 0U)
        console_puts("OK");
    else if (((ctrl >> 11) & 1U) != 0U)
        console_puts("RUN");
    else
        console_puts("WAIT");
    console_puts(" writes/retries=");
    console_put_u32(writes);
    console_putc('/');
    console_put_u32(retries);
    console_puts(" nack(id/reg/data)=");
    console_put_u32(nack_id);
    console_putc('/');
    console_put_u32(nack_register);
    console_putc('/');
    console_put_u32(nack_data);
    if (((ctrl >> 12) & 1U) != 0U) {
        console_puts(" fail(index/reg/value/phase/attempts)=");
        console_put_hex32((failure >> 8) & UINT32_C(0xFF));
        console_putc('/');
        console_put_hex32((failure >> 24) & UINT32_C(0xFF));
        console_putc('/');
        console_put_hex32((failure >> 16) & UINT32_C(0xFF));
        console_putc('/');
        console_put_u32((failure >> 2) & UINT32_C(0x3));
        console_putc('/');
        console_put_u32((failure & UINT32_C(0x3)) + 1U);
    }
    console_puts("\r\n");
}

static void ov_print_bist_sample(const char *name,
                                 const struct ov7670_bist_sample *sample)
{
    console_puts("OV7670 BIST ");
    console_puts(name);
    console_puts(" samples/pclk/vsync/href/href_pclk/overlap=");
    console_put_u32(sample->samples);
    console_putc('/'); console_put_u32(sample->pclk);
    console_putc('/'); console_put_u32(sample->vsync);
    console_putc('/'); console_put_u32(sample->href);
    console_putc('/'); console_put_u32(sample->href_pclk);
    console_putc('/'); console_put_u32(sample->overlap);
    console_puts(" geometry/period/seen/toggle=");
    console_put_hex32(sample->geometry);
    console_putc('/'); console_put_hex32(sample->period);
    console_putc('/'); console_put_hex32(sample->seen);
    console_putc('/'); console_put_hex32(sample->data_toggle);
    console_puts("\r\n");
}

static uint32_t ov_probe_level(uintptr_t base, uint32_t control)
{
    mmio_write32(base + OV_PROBE_CONTROL, control);
    mmio_fence();
    usleep(2000UL);
    return mmio_read32(base + OV_BIST_RAW_LEVELS) & OV_RAW_ALL_MASK;
}

static uint32_t ov_probe_output(uintptr_t base, const char *name,
                                uint32_t low_control,
                                uint32_t high_control, uint32_t pad_mask,
                                uint32_t *errors)
{
    uint32_t low_inputs = 0U;
    uint32_t high_inputs = 0U;

    for (unsigned int cycle = 0U; cycle < 3U; ++cycle) {
        low_inputs = ov_probe_level(base, low_control);
        high_inputs = ov_probe_level(base, high_control);
    }

    uint32_t low_pad = mmio_read32(base + OV_PAD_LEVELS) & UINT32_C(0x1F);
    (void)ov_probe_level(base, low_control);
    low_pad = mmio_read32(base + OV_PAD_LEVELS) & UINT32_C(0x1F);
    (void)ov_probe_level(base, high_control);
    uint32_t high_pad = mmio_read32(base + OV_PAD_LEVELS) & UINT32_C(0x1F);
    uint32_t rise = (~low_inputs) & high_inputs & OV_RAW_ALL_MASK;
    uint32_t fall = low_inputs & (~high_inputs) & OV_RAW_ALL_MASK;

    console_puts("OV7670 PROBE ");
    console_puts(name);
    console_puts(" pad(low/high)=");
    console_put_u32((low_pad & pad_mask) != 0U);
    console_putc('/');
    console_put_u32((high_pad & pad_mask) != 0U);
    console_puts(" input(low/high/rise/fall)=");
    console_put_hex32(low_inputs);
    console_putc('/'); console_put_hex32(high_inputs);
    console_putc('/'); console_put_hex32(rise);
    console_putc('/'); console_put_hex32(fall);
    console_puts("\r\n");

    if ((low_pad & pad_mask) != 0U || (high_pad & pad_mask) == 0U)
        *errors |= OV_ERR_PAD_READBACK;
    if (((rise | fall) & OV_RAW_DVP_MASK) != 0U)
        *errors |= OV_ERR_PIN_CORRELATION;
    return rise | fall;
}

static void ov_run_output_probe(uintptr_t base, uint32_t *errors)
{
    ov_control_write(base, OV_CTRL_CLEAR_DIAG);
    (void)ov_probe_level(base, OV_PROBE_SAFE);

    (void)ov_probe_output(base, "XCLK", OV_PROBE_SAFE,
                          OV_PROBE_SAFE | OV_PROBE_XCLK_HIGH,
                          UINT32_C(0x01), errors);
    (void)ov_probe_output(base, "RESET_N", OV_PROBE_SAFE,
                          OV_PROBE_SAFE | OV_PROBE_RESET_HIGH,
                          UINT32_C(0x02), errors);
    (void)ov_probe_output(base, "PWDN",
                          OV_PROBE_SAFE & ~OV_PROBE_PWDN_HIGH,
                          OV_PROBE_SAFE, UINT32_C(0x04), errors);
    (void)ov_probe_output(base, "SCL",
                          OV_PROBE_SAFE & ~OV_PROBE_SCL_HIGH,
                          OV_PROBE_SAFE, UINT32_C(0x08), errors);
    (void)ov_probe_output(base, "SDA",
                          OV_PROBE_SAFE & ~OV_PROBE_SDA_RELEASE,
                          OV_PROBE_SAFE, UINT32_C(0x10), errors);

    console_puts("OV7670 PROBE edges(xclk/reset/pwdn/scl/sda)=");
    for (uint32_t offset = OV_PAD_XCLK_EDGES;
         offset <= OV_PAD_SDA_EDGES; offset += 4U) {
        if (offset != OV_PAD_XCLK_EDGES)
            console_putc('/');
        console_put_u32(mmio_read32(base + offset));
    }
    console_puts(" pad_seen=");
    console_put_hex32(mmio_read32(base + OV_PAD_SEEN_LEVELS));
    console_puts("\r\n");

    mmio_write32(base + OV_PROBE_CONTROL, 0U);
    mmio_fence();
    usleep(2000UL);
}

void camera_video_print_status(const CameraConfig *camera)
{
    if (camera == 0 || !camera->present)
        return;

    (void)camera_video_snapshot(camera);

    uint32_t ctrl = mmio_read32(camera->csi_base + 0x00U);
    uint32_t frame_count = mmio_read32(camera->csi_base + 0x20U);
    uint32_t geometry = mmio_read32(camera->csi_base + 0x34U);
    uint32_t href_qualified = mmio_read32(camera->csi_base + OV_HREF_QUAL_COUNT);
    uint32_t href_short = mmio_read32(camera->csi_base + OV_HREF_SHORT_COUNT);
    uint32_t href_last = mmio_read32(camera->csi_base + OV_HREF_LAST_WIDTH);
    uint32_t vsync_qualified = mmio_read32(camera->csi_base + OV_VSYNC_QUAL_EDGES);
    uint32_t vsync_short = mmio_read32(camera->csi_base + OV_VSYNC_SHORT_COUNT);
    uint32_t pclk_candidate = mmio_read32(
        camera->csi_base + OV_PCLK_REC_CANDIDATE);
    uint32_t pclk_valid = mmio_read32(
        camera->csi_base + OV_PCLK_REC_VALID);
    uint32_t pclk_glitch = mmio_read32(
        camera->csi_base + OV_PCLK_REC_GLITCH);
    uint32_t pclk_missing = mmio_read32(
        camera->csi_base + OV_PCLK_REC_MISSING);
    uint32_t pclk_status = mmio_read32(
        camera->csi_base + OV_PCLK_REC_STATUS);
    uint32_t pclk_lock_loss = mmio_read32(
        camera->csi_base + OV_PCLK_REC_LOCK_LOSS);
    uint32_t period_fp = pclk_status & UINT32_C(0x3fff);

    console_puts("CAM CH");
    console_put_u32(camera->global_channel);
    console_puts(" init=");
    if (((ctrl >> 12) & 1U) != 0U)
        console_puts("FAIL");
    else if (((ctrl >> 19) & 1U) != 0U)
        console_puts("OK");
    else
        console_puts("WAIT");
    console_puts(" frames=");
    console_put_u32(frame_count);
    console_puts(" size=");
    console_put_u32(geometry & UINT32_C(0xffff));
    console_putc('x');
    console_put_u32(geometry >> 16);
    console_puts(" line(ok/short/last)=");
    console_put_u32(href_qualified);
    console_putc('/');
    console_put_u32(href_short);
    console_putc('/');
    console_put_u32(href_last);
    console_puts(" vs(ok/short)=");
    console_put_u32(vsync_qualified);
    console_putc('/');
    console_put_u32(vsync_short);
    console_puts(" pclk(c/v/g/m/l)=");
    console_put_u32(pclk_candidate);
    console_putc('/'); console_put_u32(pclk_valid);
    console_putc('/'); console_put_u32(pclk_glitch);
    console_putc('/'); console_put_u32(pclk_missing);
    console_putc('/'); console_put_u32(pclk_lock_loss);
    console_puts(" lock/state=");
    console_put_u32(pclk_status >> 31);
    console_putc('/'); console_put_u32((pclk_status >> 29) & 3U);
    console_puts(" period=");
    console_put_u32(period_fp >> 8);
    console_putc('.');
    console_put_u32(((period_fp & UINT32_C(0xff)) * 100U) >> 8);
    console_puts("\r\n");
    ov_print_sccb_status(camera);
}

int camera_video_snapshot(const CameraConfig *camera)
{
    if (camera == 0 || !camera->present)
        return -1;
    uintptr_t address = camera->csi_base + OV_PCLK_SNAPSHOT_CTRL;
    uint32_t old_request = mmio_read32(address) & 1U;
    mmio_write32(address, 1U);
    mmio_fence();
    for (unsigned int timeout = 0U; timeout < 10000U; ++timeout) {
        uint32_t status = mmio_read32(address);
        uint32_t request = status & 1U;
        uint32_t acknowledge = (status >> 1) & 1U;
        if (request != old_request && acknowledge == request)
            return 0;
    }
    return -1;
}

void camera_video_set_sample_tap(const CameraConfig *camera, uint32_t tap)
{
    if (camera == 0 || !camera->present || tap > 5U)
        return;
    mmio_write32(camera->csi_base + OV_BIST_CONTROL, tap << 8);
    mmio_fence();
}

uint32_t camera_ov7670_run_bist(const CameraConfig *camera)
{
    if (camera == 0 || !camera->present ||
        camera->sensor_type != CAMERA_SENSOR_OV7670)
        return UINT32_MAX;

    uintptr_t base = camera->csi_base;
    struct ov7670_bist_sample baseline;
    struct ov7670_bist_sample xclk_off;
    struct ov7670_bist_sample pwdn;
    struct ov7670_bist_sample wake;
    uint32_t errors = 0U;
    uint32_t nack_mask = 0U;

    console_puts("OV7670 BIST start: selected channel will pause; other channels remain active\r\n");
    uint32_t signature = mmio_read32(base + OV_BIST_SIGNATURE);
    if (signature != OV_BIST_MAGIC) {
        console_puts("OV7670 BIST register signature mismatch: ");
        console_put_hex32(signature);
        console_puts("\r\n");
        return UINT32_MAX;
    }
    uint32_t pad_signature = mmio_read32(base + OV_PAD_SIGNATURE);
    if (pad_signature != OV_PAD_MAGIC) {
        console_puts("OV7670 output diagnostic signature mismatch: ");
        console_put_hex32(pad_signature);
        console_puts("\r\n");
        return UINT32_MAX;
    }

    ov_run_output_probe(base, &errors);
    ov_control_write(base, OV_CTRL_FORCE_RESET);
    usleep(10000UL);
    ov_control_write(base, OV_CTRL_REINIT);
    if (ov_wait_init(base) != 0)
        errors |= OV_ERR_NO_WAKE_PCLK;
    usleep(50000UL);

    ov_bist_sample(base, 0U, 250000UL, &baseline);
    ov_print_bist_sample("BASE", &baseline);
    if (baseline.pclk < UINT32_C(1000000))
        errors |= OV_ERR_NO_BASE_PCLK;

    ov_control_write(base, OV_CTRL_XCLK_DISABLE);
    usleep(20000UL);
    ov_bist_sample(base, OV_CTRL_XCLK_DISABLE, 100000UL, &xclk_off);
    ov_print_bist_sample("XCLK_OFF", &xclk_off);
    if (xclk_off.pclk > UINT32_C(100))
        errors |= OV_ERR_XCLK_NO_EFFECT;

    ov_control_write(base, OV_CTRL_FORCE_RESET);
    usleep(10000UL);
    ov_control_write(base, OV_CTRL_REINIT);
    if (ov_wait_init(base) != 0)
        errors |= OV_ERR_NO_WAKE_PCLK;
    usleep(50000UL);

    ov_control_write(base, OV_CTRL_FORCE_PWDN);
    usleep(20000UL);
    ov_bist_sample(base, OV_CTRL_FORCE_PWDN, 100000UL, &pwdn);
    ov_print_bist_sample("PWDN", &pwdn);
    if (pwdn.pclk > UINT32_C(100))
        errors |= OV_ERR_PWDN_NO_EFFECT;

    ov_control_write(base, OV_CTRL_FORCE_RESET);
    usleep(10000UL);
    ov_control_write(base, OV_CTRL_REINIT);
    if (ov_wait_init(base) != 0)
        errors |= OV_ERR_NO_WAKE_PCLK;
    usleep(50000UL);

    uint8_t pid = ov_manual_read_register(base, UINT8_C(0x0A), &nack_mask);
    uint8_t ver = ov_manual_read_register(base, UINT8_C(0x0B), &nack_mask);
    ov_control_write(base, 0U);
    console_puts("OV7670 BIST SCCB PID/VER/nack_mask=");
    console_put_hex32(((uint32_t)pid << 8) | ver);
    console_putc('/');
    console_put_hex32(nack_mask);
    console_puts(" expect=0x00007673\r\n");
    if (pid != UINT8_C(0x76) || ver != UINT8_C(0x73))
        errors |= OV_ERR_ID;

    ov_bist_sample(base, 0U, 250000UL, &wake);
    ov_print_bist_sample("WAKE", &wake);
    if (wake.pclk < UINT32_C(1000000))
        errors |= OV_ERR_NO_WAKE_PCLK;
    if (wake.vsync == 0U || wake.vsync > UINT32_C(100))
        errors |= OV_ERR_VSYNC;
    if (wake.href < UINT32_C(100) || wake.href > UINT32_C(10000))
        errors |= OV_ERR_HREF;
    if (wake.overlap > UINT32_C(1000))
        errors |= OV_ERR_VH_OVERLAP;

    uint32_t line_pclks = wake.geometry & UINT32_C(0xFFFF);
    uint32_t frame_lines = wake.geometry >> 16;
    if (line_pclks < UINT32_C(1000) || line_pclks > UINT32_C(1600))
        errors |= OV_ERR_LINE_LENGTH;
    if (frame_lines < UINT32_C(400) || frame_lines > UINT32_C(600))
        errors |= OV_ERR_FRAME_LINES;

    console_puts("OV7670 BIST RESULT=");
    console_put_hex32(errors);
    if (errors == 0U) {
        console_puts(" PASS\r\n");
    } else {
        console_puts(" FAIL bits: 0=no_base_pclk 1=xclk_no_effect 2=pwdn_no_effect");
        console_puts(" 3=no_wake_pclk 4=id 5=vsync 6=href 7=vh_overlap");
        console_puts(" 8=line_length 9=frame_lines 10=pad_readback");
        console_puts(" 11=output_correlates_with_dvp_input\r\n");
    }
    return errors;
}
