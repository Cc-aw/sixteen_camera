#include "hdmi_tx.h"

#include <stdint.h>
#include <string.h>

#include "board_gpio.h"
#include "camera_config.h"
#include "camera_video.h"
#include "clock_chip.h"
#include "console.h"
#include "mmio.h"
#include "platform.h"
#include "sleep.h"
#include "video_edid.h"
#include "xstatus.h"
#include "xv_hdmirxss.h"
#include "xv_hdmitxss.h"
#include "xvphy.h"

#define POLL_CYCLES (SOC_CLOCK_HZ / UINT64_C(10000))

// Temporary bandwidth-isolation test.  Keep all camera writers enabled, but
// select the empty CH3 in single-channel mode so the frame manager cannot
// grant a DDR reader request.  HDMI stream start is also suppressed to avoid
// bridge-underflow interrupt noise while the reader is intentionally idle.
#define FRAMEBUFFER_READER_STOP_TEST 0
#define READER_STOP_LOCAL_CHANNEL    2U
#define DDR_UI_CLOCK_HZ              UINT64_C(300000000)

#define CAMERA_PCLK_STATUS_OFFSET    0x08U
#define CAMERA_FRAME_COUNT_OFFSET    0x0CU
#define CAMERA_OVERFLOW_OFFSET       0x10U
#define CAMERA_LOCK_LOSS_OFFSET      0x18U

#define VPHY_RX_MMCM_CTRL       UINT32_C(0x140)
#define VPHY_MMCM_LOCKED        UINT32_C(0x200)
#define VPHY_REF_CLK_SEL        UINT32_C(0x010)
#define VPHY_PLL_LOCK_STATUS    UINT32_C(0x018)
#define VPHY_TX_INIT            UINT32_C(0x01C)
#define VPHY_TX_INIT_STATUS     UINT32_C(0x020)
#define VPHY_TX_STATUS          UINT32_C(0x078)
#define VPHY_INTR_MASK          UINT32_C(0x118)
#define VPHY_INTR_STATUS        UINT32_C(0x11C)
#define VPHY_TX_MMCM_CTRL       UINT32_C(0x120)
#define VPHY_CLKDET_STATUS      UINT32_C(0x204)
#define HDMI_RX_PIO_IN          UINT32_C(0x064)
#define HDMI_RX_PIO_IN_EVENT    UINT32_C(0x068)
#define HDMI_RX_VTD_CONTROL     UINT32_C(0x0C4)
#define HDMI_RX_VTD_STATUS      UINT32_C(0x0D0)

typedef struct {
    uint8_t initialized;
    uint8_t clock_ok;
    uint8_t tx_connected;
    uint8_t tx_phy_ready;
    uint8_t tx_stream_up;
    uint8_t rx_connected;
    uint8_t rx_phy_ready;
    uint8_t rx_mmcm_ready;
    uint8_t rx_stream_up;
    uint8_t input_valid;
    uint8_t start_requested;
    uint8_t fatal_error;
    uint32_t underflows;
    uint32_t overflows;
    uint32_t rx_overflows;
    uint32_t tx_init_events;
    uint32_t tx_ready_events;
    uint32_t vphy_intr_seen;
} HdmiTxState;

typedef struct {
    uint64_t cycle;
    uint32_t aw_stall;
    uint32_t w_stall;
    uint32_t b_stall;
    uint32_t bursts_issued;
    uint32_t bursts_completed;
    uint32_t writer_frames[LOCAL_CAMERA_COUNT];
    uint32_t malformed[LOCAL_CAMERA_COUNT];
    uint32_t input_frames[LOCAL_CAMERA_COUNT];
    uint32_t pclk_status[LOCAL_CAMERA_COUNT];
    uint32_t pclk_lockloss[LOCAL_CAMERA_COUNT];
    uint32_t overflow[LOCAL_CAMERA_COUNT];
} VideoPerfSnapshot;

static XV_HdmiRxSs rx_ss;
static XV_HdmiTxSs tx_ss;
static XVphy vphy;
static HdmiTxState state;
static uint64_t next_poll_cycle;
static VideoPerfSnapshot previous_perf;
static uint8_t previous_perf_valid;

extern XV_HdmiTxSs_Config
    XV_HdmiTxSs_ConfigTable[XPAR_XV_HDMITXSS_NUM_INSTANCES];
extern XV_HdmiRxSs_Config
    XV_HdmiRxSs_ConfigTable[XPAR_XV_HDMIRXSS_NUM_INSTANCES];
extern XVphy_Config XVphy_ConfigTable[XPAR_XVPHY_NUM_INSTANCES];

static void line(const char *text)
{
    console_puts("[video] ");
    console_puts(text);
    console_puts("\r\n");
}

static int wait_clock_lock(void)
{
    for (unsigned wait = 0U; wait < 100U; ++wait) {
        if ((board_gpio_status() & GPIO_IN_CLK_LOL) == 0U)
            return XST_SUCCESS;
        usleep(5000U);
    }
    return XST_FAILURE;
}

static void update_output_enable(void)
{
    uint32_t pins = board_gpio_status();
    int ready = state.initialized && state.clock_ok && state.tx_connected &&
                state.tx_phy_ready && state.tx_stream_up &&
                !state.fatal_error &&
                ((pins & GPIO_IN_TX_HPD) != 0U) &&
                ((pins & GPIO_IN_CLK_LOL) == 0U);
    board_tx_enable(ready);
}

static void tx_connect_callback(void *ref)
{
    XV_HdmiTxSs *ss = (XV_HdmiTxSs *)ref;
    uint8_t connected = ss->IsStreamConnected ? 1U : 0U;
    if (connected == state.tx_connected)
        return;
    state.tx_connected = connected;
    if (connected) {
        line("sink connected");
    } else {
        state.tx_stream_up = 0U;
        state.start_requested = 0U;
        board_tx_enable(0);
        line("sink disconnected");
    }
}

static void tx_toggle_callback(void *ref)
{
    (void)ref;
    state.tx_stream_up = 0U;
    state.start_requested = 0U;
    board_tx_enable(0);
    line("HPD toggle; restart armed");
}

static void tx_stream_up_callback(void *ref)
{
    (void)ref;
    state.tx_stream_up = 1U;
    XVphy_Clkout1OBufTdsEnable(&vphy, XVPHY_DIR_TX, TRUE);
    line("stream up: 1920x1080p60 RGB, 2 pixels/clock");
}

static void tx_stream_down_callback(void *ref)
{
    (void)ref;
    state.tx_stream_up = 0U;
    state.start_requested = 0U;
    board_tx_enable(0);
    line("stream down");
}

static void tx_underflow_callback(void *ref)
{
    (void)ref;
    ++state.underflows;
    // Repeated HDMI underflow IRQs must not monopolize the Rocket console;
    // keep the total visible in the video status command.
    if (state.underflows <= 4U ||
        (state.underflows & (state.underflows - 1U)) == 0U) {
        console_puts("[video] AXIS bridge underflow count=");
        console_put_u32(state.underflows);
        console_puts("\r\n");
    }
}

static void tx_overflow_callback(void *ref)
{
    (void)ref;
    ++state.overflows;
    line("AXIS bridge overflow");
}

static void rx_overflow_callback(void *ref)
{
    (void)ref;
    ++state.rx_overflows;
    line("RX AXIS bridge overflow");
}

static void print_rx_stream(const XVidC_VideoStream *stream)
{
    console_puts("[video] RX detected: active=");
    console_put_u32(stream->Timing.HActive);
    console_putc('x');
    console_put_u32(stream->Timing.VActive);
    console_puts(" total=");
    console_put_u32(stream->Timing.HTotal);
    console_putc('x');
    console_put_u32(stream->Timing.F0PVTotal);
    console_puts(" rate=");
    console_put_u32((uint32_t)stream->FrameRate);
    console_puts(" interlaced=");
    console_put_u32(stream->IsInterlaced);
    console_puts(" color=");
    console_put_u32((uint32_t)stream->ColorFormatId);
    console_puts(" depth=");
    console_put_u32((uint32_t)stream->ColorDepth);
    console_puts(" ppc=");
    console_put_u32((uint32_t)stream->PixPerClk);
    console_puts(" vm=");
    console_put_u32((uint32_t)stream->VmId);
    console_puts("\r\n");
}

static int validate_rx_stream(const XVidC_VideoStream *stream)
{
    if (stream->Timing.HActive != 3840U || stream->Timing.VActive != 2160U ||
        stream->IsInterlaced || stream->FrameRate != XVIDC_FR_30HZ) {
        line("RX rejected: expected progressive 3840x2160 at 30 Hz");
        return XST_FAILURE;
    }
    if (stream->ColorFormatId != XVIDC_CSF_RGB ||
        stream->ColorDepth != XVIDC_BPC_8 || stream->PixPerClk != XVIDC_PPC_2) {
        line("RX rejected: expected RGB 8-bit, 2 pixels/clock");
        return XST_FAILURE;
    }
    return XST_SUCCESS;
}

static void rx_connect_callback(void *ref)
{
    XV_HdmiRxSs *ss = (XV_HdmiRxSs *)ref;
    uint8_t connected = ss->IsStreamConnected ? 1U : 0U;
    if (connected == state.rx_connected)
        return;
    state.rx_connected = connected;
    XVphy_IBufDsEnable(&vphy, 0U, XVPHY_DIR_RX, connected);
    if (connected) {
        line("RX source connected");
    } else {
        state.rx_phy_ready = 0U;
        state.rx_mmcm_ready = 0U;
        state.rx_stream_up = 0U;
        state.input_valid = 0U;
        mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_HDMI_CONTROL, 0U);
        mmio_fence();
        vphy.HdmiRxTmdsClockRatio = 0U;
        line("RX source disconnected");
    }
}

static void rx_stream_init_callback(void *ref)
{
    XV_HdmiRxSs *ss = (XV_HdmiRxSs *)ref;
    XVidC_VideoStream *stream = XV_HdmiRxSs_GetVideoStream(ss);
    XVidC_ColorDepth depth = stream->ColorDepth;

    print_rx_stream(stream);
    if (stream->ColorFormatId == XVIDC_CSF_YCRCB_422)
        depth = XVIDC_BPC_8;

    state.rx_mmcm_ready = 0U;
    if (XVphy_HdmiCfgCalcMmcmParam(&vphy, 0U, XVPHY_CHANNEL_ID_CH1,
                                   XVPHY_DIR_RX, stream->PixPerClk,
                                   depth) != XST_SUCCESS) {
        state.input_valid = 0U;
        line("RX MMCM parameter calculation failed");
        return;
    }
    XVphy_MmcmStart(&vphy, 0U, XVPHY_DIR_RX);
    usleep(10000U);
    state.rx_mmcm_ready = 1U;
    line("RX MMCM configured");
}

static void rx_stream_up_callback(void *ref)
{
    XV_HdmiRxSs *ss = (XV_HdmiRxSs *)ref;
    XVidC_VideoStream *stream = XV_HdmiRxSs_GetVideoStream(ss);
    state.rx_stream_up = 1U;
    state.input_valid = validate_rx_stream(stream) == XST_SUCCESS;
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_HDMI_CONTROL,
                 state.input_valid ? 1U : 0U);
    mmio_fence();
    if (!state.input_valid)
        return;
    line("RX stream up: 4K30 spatial transport -> CH9-CH16");
}

static void rx_stream_down_callback(void *ref)
{
    (void)ref;
    state.rx_mmcm_ready = 0U;
    state.rx_stream_up = 0U;
    state.input_valid = 0U;
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_HDMI_CONTROL, 0U);
    mmio_fence();
    line("RX stream down");
}

static void vphy_tx_init_callback(void *ref)
{
    (void)ref;
    ++state.tx_init_events;
    state.tx_phy_ready = 0U;
    state.tx_stream_up = 0U;
    state.start_requested = 0U;
    board_tx_enable(0);
    XV_HdmiTxSs_RefClockChangeInit(&tx_ss);
    line("VPHY TX initializing");
}

static void vphy_tx_ready_callback(void *ref)
{
    (void)ref;
    ++state.tx_ready_events;
    if (!state.tx_phy_ready)
        line("VPHY TX ready");
    state.tx_phy_ready = 1U;
}

static void vphy_rx_init_callback(void *ref)
{
    XVphy *phy = (XVphy *)ref;
    state.rx_phy_ready = 0U;
    state.rx_mmcm_ready = 0U;
    XV_HdmiRxSs_RefClockChangeInit(&rx_ss);
    phy->HdmiRxTmdsClockRatio = rx_ss.TMDSClockRatio;
    line("VPHY RX initializing");
}

static void vphy_rx_ready_callback(void *ref)
{
    XVphy *phy = (XVphy *)ref;
    XVphy_PllType pll = XVphy_GetPllType(phy, 0U, XVPHY_DIR_RX,
                                         XVPHY_CHANNEL_ID_CH1);
    XVphy_ChannelId channel = (pll == XVPHY_PLL_TYPE_CPLL) ?
                               XVPHY_CHANNEL_ID_CH1 : XVPHY_CHANNEL_ID_CMN0;
    state.rx_phy_ready = 1U;
    (void)XV_HdmiRxSs_SetStream(&rx_ss, phy->HdmiRxRefClkHz,
                                (u32)(XVphy_GetLineRateHz(
                                    phy, 0U, channel) / 1000000ULL));
    line("VPHY RX ready");
}

static void vphy_error_callback(void *ref)
{
    (void)ref;
    if (!state.fatal_error)
        line("VPHY error; output disabled (press r to restart)");
    state.fatal_error = 1U;
    board_tx_enable(0);
}

static int init_reference_clock(void)
{
    for (unsigned retry = 0U; retry < 3U; ++retry) {
        if ((clock_chip_program_148p5() == CLOCK_CHIP_OK) &&
            (wait_clock_lock() == XST_SUCCESS)) {
            state.clock_ok = 1U;
            line("8T49N241 Q2/Q3 locked at 148.5 MHz");
            return XST_SUCCESS;
        }
        line("8T49N241 lock retry");
    }
    line("8T49N241 failed to lock");
    return XST_FAILURE;
}

static void framebuffer_configure(void)
{
    static const uint32_t channel_bases[VIDEO_CHANNEL_COUNT] = {
        UINT32_C(0x08000000), UINT32_C(0x08100000),
        UINT32_C(0x08200000), UINT32_C(0x08300000),
        UINT32_C(0x08400000), UINT32_C(0x08500000),
        UINT32_C(0x08600000), UINT32_C(0x08700000),
        UINT32_C(0x08800000), UINT32_C(0x08900000),
        UINT32_C(0x08A00000), UINT32_C(0x08B00000),
        UINT32_C(0x08C00000), UINT32_C(0x08D00000),
        UINT32_C(0x08E00000), UINT32_C(0x08F00000)
    };

    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_CONTROL, 0U);
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_WIDTH, 368U);
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_HEIGHT, 270U);
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_STRIDE, 736U);
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_COUNT, 4U);
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_DISPLAY_CH,
                 FRAMEBUFFER_READER_STOP_TEST ?
                     READER_STOP_LOCAL_CHANNEL : 0U);
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_DISPLAY_MODE,
                 FRAMEBUFFER_READER_STOP_TEST ? 1U : 0U);
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_HDMI_CONTROL, 0U);
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_BUFFER_STRIDE, 0x00040000U);
    for (uint32_t channel = 0U; channel < VIDEO_CHANNEL_COUNT; ++channel)
        mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_BASE0 + channel * 4U,
                     channel_bases[channel]);
    mmio_fence();
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_CONTROL, 0x5U);
    mmio_fence();
#if FRAMEBUFFER_READER_STOP_TEST
    line("framebuffer: writers enabled; DDR reader stopped on empty CH3");
#else
    line("framebuffer: sixteen 360x270 RGB565 four-buffer pools; 4x4 mosaic selected");
#endif
}

void hdmi_tx_framebuffer_init(void)
{
    framebuffer_configure();
}

static uint32_t framebuffer_total_frames(void)
{
    uint32_t total = 0U;
    for (uint32_t channel = 0U; channel < VIDEO_CHANNEL_COUNT; ++channel)
        total += mmio_read32(FRAMEBUFFER_BASE +
                             FRAMEBUFFER_WRITER_COUNT(channel));
    return total;
}

static void framebuffer_select_first_ready(void)
{
#if FRAMEBUFFER_READER_STOP_TEST
    // Do not replace the deliberately empty debug channel with a ready one.
    return;
#else
    uint32_t selected = mmio_read32(FRAMEBUFFER_BASE +
                                    FRAMEBUFFER_DISPLAY_CH);

    if ((selected < VIDEO_CHANNEL_COUNT) &&
        (mmio_read32(FRAMEBUFFER_BASE +
                     FRAMEBUFFER_WRITER_COUNT(selected)) != 0U))
        return;

    for (uint32_t channel = 0U; channel < VIDEO_CHANNEL_COUNT; ++channel) {
        if (mmio_read32(FRAMEBUFFER_BASE +
                        FRAMEBUFFER_WRITER_COUNT(channel)) == 0U)
            continue;

        mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_DISPLAY_CH, channel);
        mmio_fence();
        console_puts("[video] first ready camera CH");
        console_put_u32(channel + LOCAL_CAMERA_GLOBAL_BASE);
        console_puts(" selected\r\n");
        return;
    }
#endif
}

static void video_perf_capture(VideoPerfSnapshot *snapshot)
{
    snapshot->cycle = read_cycle();
    snapshot->aw_stall = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_WRITER_PERF_AW_STALL);
    snapshot->w_stall = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_WRITER_PERF_W_STALL);
    snapshot->b_stall = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_WRITER_PERF_B_STALL);
    snapshot->bursts_issued = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_WRITER_PERF_ISSUED);
    snapshot->bursts_completed = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_WRITER_PERF_COMPLETED);

    for (size_t index = 0U; index < camera_config_count; ++index) {
        uintptr_t camera_base = camera_configs[index].csi_base;
        snapshot->writer_frames[index] = mmio_read32(
            FRAMEBUFFER_BASE + FRAMEBUFFER_WRITER_COUNT(index));
        snapshot->malformed[index] = mmio_read32(
            FRAMEBUFFER_BASE + FRAMEBUFFER_MALFORMED(index));
        snapshot->input_frames[index] = mmio_read32(
            camera_base + CAMERA_FRAME_COUNT_OFFSET);
        snapshot->pclk_status[index] = mmio_read32(
            camera_base + CAMERA_PCLK_STATUS_OFFSET);
        snapshot->pclk_lockloss[index] = mmio_read32(
            camera_base + CAMERA_LOCK_LOSS_OFFSET);
        snapshot->overflow[index] = mmio_read32(
            camera_base + CAMERA_OVERFLOW_OFFSET);
    }
}

static void print_percent(uint32_t basis_points)
{
    uint32_t fraction = basis_points % 100U;
    console_put_u32(basis_points / 100U);
    console_putc('.');
    if (fraction < 10U)
        console_putc('0');
    console_put_u32(fraction);
    console_putc('%');
}

static void video_perf_print_delta(const VideoPerfSnapshot *current)
{
    if (!previous_perf_valid) {
        previous_perf = *current;
        previous_perf_valid = 1U;
        line("delta baseline captured; press s again after about 5 seconds");
        return;
    }

    uint64_t elapsed_cycles = current->cycle - previous_perf.cycle;
    uint64_t elapsed_ms = elapsed_cycles * UINT64_C(1000) / SOC_CLOCK_HZ;
    uint64_t ui_cycles = elapsed_cycles * DDR_UI_CLOCK_HZ / SOC_CLOCK_HZ;
    uint32_t delta_aw = current->aw_stall - previous_perf.aw_stall;
    uint32_t delta_w = current->w_stall - previous_perf.w_stall;
    uint32_t delta_b = current->b_stall - previous_perf.b_stall;
    uint32_t delta_issued = current->bursts_issued -
                            previous_perf.bursts_issued;
    uint32_t delta_completed = current->bursts_completed -
                               previous_perf.bursts_completed;
    uint32_t w_stall_basis_points = ui_cycles == 0U ? 0U :
        (uint32_t)(((uint64_t)delta_w * UINT64_C(10000)) / ui_cycles);
    uint32_t bursts_per_second = elapsed_cycles == 0U ? 0U :
        (uint32_t)(((uint64_t)delta_issued * SOC_CLOCK_HZ) /
                   elapsed_cycles);

    console_puts("DELTA ms="); console_put_u32((uint32_t)elapsed_ms);
    console_puts(" stall(aw/w/b)="); console_put_u32(delta_aw);
    console_putc('/'); console_put_u32(delta_w);
    console_putc('/'); console_put_u32(delta_b);
    console_puts(" w_stall="); print_percent(w_stall_basis_points);
    console_puts(" bursts(i/c)/s="); console_put_u32(delta_issued);
    console_putc('/'); console_put_u32(delta_completed);
    console_putc('/'); console_put_u32(bursts_per_second);
    console_puts("\r\n");

    if (elapsed_cycles > SOC_CLOCK_HZ * UINT64_C(12))
        line("delta interval too long; use less than 12 seconds to avoid counter ambiguity");

    for (size_t index = 0U; index < camera_config_count; ++index) {
        uint32_t delta_input_frames = current->input_frames[index] -
                                      previous_perf.input_frames[index];
        uint32_t delta_writer_frames = current->writer_frames[index] -
                                       previous_perf.writer_frames[index];
        uint32_t delta_malformed = current->malformed[index] -
                                   previous_perf.malformed[index];
        console_puts("DELTA CH");
        console_put_u32(camera_configs[index].global_channel);
        console_puts(" in/wr/mal="); console_put_u32(delta_input_frames);
        console_putc('/'); console_put_u32(delta_writer_frames);
        console_putc('/'); console_put_u32(delta_malformed);
        uint32_t delta_pclk_loss = current->pclk_lockloss[index] -
                                   previous_perf.pclk_lockloss[index];
        uint32_t delta_overflow = current->overflow[index] -
                                  previous_perf.overflow[index];
        uint32_t pclk_status = current->pclk_status[index];
        uint32_t period_fp = pclk_status >> 4;
        console_puts(" pclk(loss/overflow)=");
        console_put_u32(delta_pclk_loss);
        console_putc('/'); console_put_u32(delta_overflow);
        console_puts(" lock/state="); console_put_u32((pclk_status >> 1) & 1U);
        console_putc('/'); console_put_u32((pclk_status >> 2) & 3U);
        console_puts(" period="); console_put_u32(period_fp >> 8);
        console_putc('.');
        console_put_u32(((period_fp & UINT32_C(0xff)) * 100U) >> 8);
        console_puts("\r\n");
    }

    previous_perf = *current;
}

int hdmi_tx_init(void)
{
    u32 tx_ref_clock;

    memset(&state, 0, sizeof(state));
    previous_perf_valid = 0U;
    board_tx_enable(0);
    if (init_reference_clock() != XST_SUCCESS)
        return XST_FAILURE;

    if (XV_HdmiTxSs_CfgInitialize(&tx_ss, &XV_HdmiTxSs_ConfigTable[0],
                                  HDMI_TX_BASE) != XST_SUCCESS) {
        line("HDMI TX subsystem initialization failed");
        return XST_FAILURE;
    }
    XV_HdmiTxSS_SetAppVersion(&tx_ss, 1U, 0U);
    (void)XV_HdmiTxSs_SetCallback(&tx_ss, XV_HDMITXSS_HANDLER_CONNECT,
                                  tx_connect_callback, &tx_ss);
    (void)XV_HdmiTxSs_SetCallback(&tx_ss, XV_HDMITXSS_HANDLER_TOGGLE,
                                  tx_toggle_callback, &tx_ss);
    (void)XV_HdmiTxSs_SetCallback(&tx_ss, XV_HDMITXSS_HANDLER_STREAM_UP,
                                  tx_stream_up_callback, &tx_ss);
    (void)XV_HdmiTxSs_SetCallback(&tx_ss, XV_HDMITXSS_HANDLER_STREAM_DOWN,
                                  tx_stream_down_callback, &tx_ss);
    (void)XV_HdmiTxSs_SetCallback(&tx_ss,
                                  XV_HDMITXSS_HANDLER_BRDGUNDERFLOW,
                                  tx_underflow_callback, &tx_ss);
    (void)XV_HdmiTxSs_SetCallback(&tx_ss,
                                  XV_HDMITXSS_HANDLER_BRDGOVERFLOW,
                                  tx_overflow_callback, &tx_ss);

    XV_HdmiRxSs_SetEdidParam(&rx_ss, (u8 *)video_rx_edid,
                             (u16)sizeof(video_rx_edid));
    if (XV_HdmiRxSs_CfgInitialize(&rx_ss, &XV_HdmiRxSs_ConfigTable[0],
                                  HDMI_RX_BASE) != XST_SUCCESS) {
        line("HDMI RX subsystem initialization failed");
        return XST_FAILURE;
    }
    XV_HdmiRxSS_SetAppVersion(&rx_ss, 2U, 0U);
    (void)XV_HdmiRxSs_SetCallback(&rx_ss, XV_HDMIRXSS_HANDLER_CONNECT,
                                  rx_connect_callback, &rx_ss);
    (void)XV_HdmiRxSs_SetCallback(&rx_ss, XV_HDMIRXSS_HANDLER_STREAM_INIT,
                                  rx_stream_init_callback, &rx_ss);
    (void)XV_HdmiRxSs_SetCallback(&rx_ss, XV_HDMIRXSS_HANDLER_STREAM_UP,
                                  rx_stream_up_callback, &rx_ss);
    (void)XV_HdmiRxSs_SetCallback(&rx_ss, XV_HDMIRXSS_HANDLER_STREAM_DOWN,
                                  rx_stream_down_callback, &rx_ss);
    (void)XV_HdmiRxSs_SetCallback(&rx_ss,
                                  XV_HDMIRXSS_HANDLER_BRDGOVERFLOW,
                                  rx_overflow_callback, &rx_ss);

    if (XVphy_Hdmi_CfgInitialize(&vphy, 0U,
                                 &XVphy_ConfigTable[0]) != XST_SUCCESS) {
        line("VPHY initialization failed");
        return XST_FAILURE;
    }
    XVphy_SetHdmiCallback(&vphy, XVPHY_HDMI_HANDLER_TXINIT,
                          vphy_tx_init_callback, &vphy);
    XVphy_SetHdmiCallback(&vphy, XVPHY_HDMI_HANDLER_TXREADY,
                          vphy_tx_ready_callback, &vphy);
    XVphy_SetHdmiCallback(&vphy, XVPHY_HDMI_HANDLER_RXINIT,
                          vphy_rx_init_callback, &vphy);
    XVphy_SetHdmiCallback(&vphy, XVPHY_HDMI_HANDLER_RXREADY,
                          vphy_rx_ready_callback, &vphy);
    XVphy_SetErrorCallback(&vphy, vphy_error_callback, &vphy);

    XVphy_IBufDsEnable(&vphy, 0U, XVPHY_DIR_TX, TRUE);
    tx_ref_clock = XV_HdmiTxSs_SetStream(&tx_ss,
                                         XVIDC_VM_1920x1080_60_P,
                                         XVIDC_CSF_RGB, XVIDC_BPC_8, NULL);
    if (tx_ref_clock == 0U) {
        line("1080p60 timing setup failed");
        return XST_FAILURE;
    }
    vphy.HdmiTxRefClkHz = tx_ref_clock;
    if (XVphy_SetHdmiTxParam(&vphy, 0U, XVPHY_CHANNEL_ID_CHA,
                             XVIDC_PPC_2, XVIDC_BPC_8,
                             XVIDC_CSF_RGB) != XST_SUCCESS) {
        line("VPHY 1080p60 setup failed");
        return XST_FAILURE;
    }

    state.initialized = 1U;
    framebuffer_configure();
    XV_HdmiRxSs_Start(&rx_ss);
    XVphy_IBufDsEnable(&vphy, 0U, XVPHY_DIR_RX, TRUE);

    state.tx_connected =
        (board_gpio_status() & GPIO_IN_TX_HPD) ? 1U : 0U;
    next_poll_cycle = read_cycle();
    line(state.tx_connected ? "initialized; TX sink present, waiting for OV7670 frame" :
                              "initialized; waiting for TX sink and OV7670 frame");
    return XST_SUCCESS;
}

void hdmi_tx_poll(void)
{
    uint64_t now;
    uint32_t pins;
    uint8_t hpd;

    if (!state.initialized)
        return;
    now = read_cycle();
    if ((int64_t)(now - next_poll_cycle) < 0)
        return;
    next_poll_cycle = now + POLL_CYCLES;

    /* The driver clears handled interrupts, so retain a sticky diagnostic
     * copy before dispatching it. */
    state.vphy_intr_seen |= mmio_read32(VPHY_BASE + VPHY_INTR_STATUS);
    XVphy_InterruptHandler(&vphy);
    XV_HdmiRxSS_HdmiRxIntrHandler(&rx_ss);
    XV_HdmiTxSS_HdmiTxIntrHandler(&tx_ss);

    pins = board_gpio_status();
    if (state.clock_ok && ((pins & GPIO_IN_CLK_LOL) != 0U)) {
        state.clock_ok = 0U;
        state.fatal_error = 1U;
        board_tx_enable(0);
        line("reference clock lost lock");
    }

    hpd = (pins & GPIO_IN_TX_HPD) ? 1U : 0U;
    if (hpd != state.tx_connected) {
        state.tx_connected = hpd;
        if (hpd) {
            line("HPD high");
        } else {
            state.tx_stream_up = 0U;
            state.start_requested = 0U;
            board_tx_enable(0);
            line("HPD low");
        }
    }

    if (state.tx_connected && state.tx_phy_ready &&
        (framebuffer_total_frames() != 0U) &&
        !state.start_requested && !state.fatal_error) {
        framebuffer_select_first_ready();
        state.start_requested = 1U;
#if FRAMEBUFFER_READER_STOP_TEST
        line("DDR reader stop test active; HDMI stream start suppressed");
#else
        XV_HdmiTxSs_StreamStart(&tx_ss);
        line("OV7670 frame received; HDMI stream start requested");
#endif
    }
    update_output_enable();
}

void hdmi_tx_restart(void)
{
    line("restarting TX stack");
    board_tx_enable(0);
    (void)hdmi_tx_init();
}

int hdmi_tx_select_camera(unsigned camera_channel)
{
#if FRAMEBUFFER_READER_STOP_TEST
    (void)camera_channel;
    line("camera selection disabled during DDR reader stop test");
    return XST_FAILURE;
#else
    uint32_t present_mask;
    unsigned local_channel;

    if ((camera_channel < LOCAL_CAMERA_GLOBAL_BASE) ||
        (camera_channel >= LOCAL_CAMERA_GLOBAL_BASE + LOCAL_CAMERA_COUNT))
        return XST_FAILURE;

    local_channel = camera_channel - LOCAL_CAMERA_GLOBAL_BASE;
    present_mask = mmio_read32(FRAMEBUFFER_BASE + FRAMEBUFFER_PRESENT_MASK);
    if ((present_mask & (UINT32_C(1) << local_channel)) == 0U)
        return XST_FAILURE;

    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_DISPLAY_CH, local_channel);
    mmio_fence();
    if (mmio_read32(FRAMEBUFFER_BASE + FRAMEBUFFER_DISPLAY_CH) !=
        local_channel)
        return XST_FAILURE;

    console_puts("[video] display channel CH");
    console_put_u32(camera_channel);
    console_puts(" selected\r\n");
    return XST_SUCCESS;
#endif
}

void hdmi_tx_print_status(void)
{
    VideoPerfSnapshot perf_snapshot;
    video_perf_capture(&perf_snapshot);
    uint32_t reader_debug =
        mmio_read32(FRAMEBUFFER_BASE + FRAMEBUFFER_READER_DEBUG);
    uint32_t display_channel = mmio_read32(FRAMEBUFFER_BASE +
                                           FRAMEBUFFER_DISPLAY_CH) + 1U;
    uint32_t displayed = mmio_read32(FRAMEBUFFER_BASE +
                                     FRAMEBUFFER_READER_COUNT);
    uint32_t present_mask = mmio_read32(FRAMEBUFFER_BASE +
                                        FRAMEBUFFER_PRESENT_MASK);
    uint32_t reader_underflow = mmio_read32(FRAMEBUFFER_BASE +
                                            FRAMEBUFFER_UNDERFLOW);
    uint32_t reader_axi_error = (reader_debug >> 31) & 1U;
    uint32_t reader_active = (reader_debug >> 30) & 1U;
    uint32_t reader_display = (reader_debug >> 29) & 1U;
    uint32_t reader_state = (reader_debug >> 4) & 7U;
    uint32_t reader_phase = (reader_debug >> 2) & 3U;
    uint32_t reader_line = (reader_debug >> 17) & 0x7FFU;
    uint32_t reader_x = (reader_debug >> 7) & 0x3FFU;
    uint32_t vphy_pll_type = (uint32_t)XVphy_GetPllType(
        &vphy, 0U, XVPHY_DIR_TX, XVPHY_CHANNEL_ID_CH1);
    uint32_t vphy_ref_measured = XVphy_ClkDetGetRefClkFreqHz(
        &vphy, XVPHY_DIR_TX);

    console_puts("PIPE init="); console_put_u32(state.initialized);
    console_puts(" clock="); console_put_u32(state.clock_ok);
    console_puts(" tx_hpd="); console_put_u32(state.tx_connected);
    console_puts(" tx_phy="); console_put_u32(state.tx_phy_ready);
    console_puts(" tx_stream="); console_put_u32(state.tx_stream_up);
    console_puts(" video_frames=");
    console_put_u32(framebuffer_total_frames());
    console_puts(" tx_underflows=");
    console_put_u32(state.underflows);
    console_puts(" started="); console_put_u32(state.start_requested);
    console_puts(" fatal="); console_put_u32(state.fatal_error);
    console_puts("\r\nVPHY TX evt(init/ready)=");
    console_put_u32(state.tx_init_events);
    console_putc('/'); console_put_u32(state.tx_ready_events);
    console_puts(" fsm=");
    console_put_u32((uint32_t)vphy.Quads[0].Ch1.TxState);
    console_puts(" pll(type/lock)="); console_put_u32(vphy_pll_type);
    console_putc('/');
    console_put_hex32(mmio_read32(VPHY_BASE + VPHY_PLL_LOCK_STATUS));
    console_puts(" ref(cfg/meas)="); console_put_u32(vphy.HdmiTxRefClkHz);
    console_putc('/'); console_put_u32(vphy_ref_measured);
    console_puts("\r\nVPHY RAW ref/init/initst/txst/mmcm/clkdet=");
    console_put_hex32(mmio_read32(VPHY_BASE + VPHY_REF_CLK_SEL));
    console_putc('/'); console_put_hex32(mmio_read32(VPHY_BASE + VPHY_TX_INIT));
    console_putc('/'); console_put_hex32(mmio_read32(VPHY_BASE + VPHY_TX_INIT_STATUS));
    console_putc('/'); console_put_hex32(mmio_read32(VPHY_BASE + VPHY_TX_STATUS));
    console_putc('/'); console_put_hex32(mmio_read32(VPHY_BASE + VPHY_TX_MMCM_CTRL));
    console_putc('/'); console_put_hex32(mmio_read32(VPHY_BASE + VPHY_CLKDET_STATUS));
    console_puts(" intr(now/seen/mask)=");
    console_put_hex32(mmio_read32(VPHY_BASE + VPHY_INTR_STATUS));
    console_putc('/'); console_put_hex32(state.vphy_intr_seen);
    console_putc('/'); console_put_hex32(mmio_read32(VPHY_BASE + VPHY_INTR_MASK));
    console_puts("\r\nFB ch=");
    console_put_u32(display_channel);
    console_puts(" displayed="); console_put_u32(displayed);
    console_puts(" present="); console_put_hex32(present_mask);
    console_puts(" underflow="); console_put_u32(reader_underflow);
    console_puts(" reader(axi/active/mosaic/fill/phase/line/x)=");
    console_put_u32(reader_axi_error);
    console_putc('/'); console_put_u32(reader_active);
    console_putc('/'); console_put_u32(reader_display);
    console_putc('/'); console_put_u32(reader_state);
    console_putc('/'); console_put_u32(reader_phase);
    console_putc('/'); console_put_u32(reader_line);
    console_putc('/'); console_put_u32(reader_x);
    console_puts("\r\n");
    console_puts("DMA outstanding(cur/max)=");
    console_put_u32(mmio_read32(FRAMEBUFFER_BASE +
                                FRAMEBUFFER_WRITER_PERF_CURRENT));
    console_putc('/');
    console_put_u32(mmio_read32(FRAMEBUFFER_BASE +
                                FRAMEBUFFER_WRITER_PERF_MAX));
    console_puts(" stall(aw/w/b)=");
    console_put_u32(mmio_read32(FRAMEBUFFER_BASE +
                                FRAMEBUFFER_WRITER_PERF_AW_STALL));
    console_putc('/');
    console_put_u32(mmio_read32(FRAMEBUFFER_BASE +
                                FRAMEBUFFER_WRITER_PERF_W_STALL));
    console_putc('/');
    console_put_u32(mmio_read32(FRAMEBUFFER_BASE +
                                FRAMEBUFFER_WRITER_PERF_B_STALL));
    console_puts(" bursts(issued/completed/errors)=");
    console_put_u32(mmio_read32(FRAMEBUFFER_BASE +
                                FRAMEBUFFER_WRITER_PERF_ISSUED));
    console_putc('/');
    console_put_u32(mmio_read32(FRAMEBUFFER_BASE +
                                FRAMEBUFFER_WRITER_PERF_COMPLETED));
    console_putc('/');
    console_put_u32(mmio_read32(FRAMEBUFFER_BASE +
                                FRAMEBUFFER_WRITER_PERF_ERRORS));
    console_puts("\r\n");
    for (uint32_t channel = 0U; channel < VIDEO_CHANNEL_COUNT; ++channel) {
        console_puts("FB CH");
        console_put_u32(LOCAL_CAMERA_GLOBAL_BASE + channel);
        console_puts(" written/drop/malformed=");
        console_put_u32(mmio_read32(FRAMEBUFFER_BASE +
                                    FRAMEBUFFER_WRITER_COUNT(channel)));
        console_putc('/');
        console_put_u32(mmio_read32(FRAMEBUFFER_BASE +
                                    FRAMEBUFFER_DROP_COUNT(channel)));
        console_putc('/');
        console_put_u32(mmio_read32(FRAMEBUFFER_BASE +
                                    FRAMEBUFFER_MALFORMED(channel)));
        console_puts("\r\n");
    }
    console_puts("HDMI transport(total/malformed)=");
    console_put_u32(mmio_read32(FRAMEBUFFER_BASE +
                                FRAMEBUFFER_HDMI_TRANSPORT_FRAMES));
    console_putc('/');
    console_put_u32(mmio_read32(FRAMEBUFFER_BASE +
                                FRAMEBUFFER_HDMI_TRANSPORT_MALFORMED));
    console_puts(" capture=");
    console_put_u32(mmio_read32(FRAMEBUFFER_BASE +
                                FRAMEBUFFER_HDMI_CONTROL) & 1U);
    console_puts("\r\n");
    console_puts("\r\n");
    video_perf_print_delta(&perf_snapshot);
}
