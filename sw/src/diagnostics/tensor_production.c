#include "app/mode_manager.h"
#include "diagnostics/board_bandwidth.h"
#include "diagnostics/tensor_production.h"
#include "diagnostics/ai_postprocess_diag.h"
#include "platform/console.h"
#include "mmio.h"

void tensor_production_init(void)
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

void tensor_production_toggle(void)
{
    if (app_modes.tensor.mode == 1U) {
        app_modes.tensor.mode = 2U;
        mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_CONTROL, 0U);
        console_puts("TENSOR PROD draining\r\n");
        return;
    }
    if (app_modes.tensor.mode != 0U)
        return;
    if (rt_is_enabled() != 0U ||
        rt_is_idle() == 0U) {
        console_puts("TENSOR PROD: disable AI and drain all arenas first\r\n");
        return;
    }
    for (uint32_t channel = 0U; channel < VIDEO_CHANNEL_COUNT; ++channel) {
        app_modes.tensor.done[channel] = 0U;
        app_modes.tensor.last_frame[channel] = 0U;
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
    app_modes.tensor.mode = 1U;
    app_modes.tensor.report_cycle = read_cycle();
    console_puts("TENSOR PROD enabled, multi-channel capture, press m to drain\r\n");
}

void tensor_production_service(void)
{
    if (app_modes.tensor.mode == 0U)
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
                (app_modes.tensor.done[stream] != 0U &&
                 frame <= app_modes.tensor.last_frame[stream])) &&
               read_cycle() - metadata_start < SOC_CLOCK_HZ / 100U) {
            frame = mmio_read32(FRAMEBUFFER_BASE +
                                FRAMEBUFFER_TENSOR_PROD_FRAME);
            bytes = mmio_read32(FRAMEBUFFER_BASE +
                                FRAMEBUFFER_TENSOR_PROD_BYTES);
        }
        if (bytes != TENSOR_MEMBER_BYTES ||
            (app_modes.tensor.done[stream] != 0U &&
             frame <= app_modes.tensor.last_frame[stream])) {
            console_puts("TENSOR PROD FAIL slot/frame/bytes=");
            console_put_u32(slot);
            console_putc('/');
            console_put_u32(frame);
            console_putc('/');
            console_put_u32(bytes);
            console_puts("\r\n");
        } else {
            app_modes.tensor.done[stream]++;
            app_modes.tensor.last_frame[stream] = frame;
        }
        mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_RELEASE,
                     UINT32_C(1) << slot);
        mmio_fence();
        mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_CONTROL,
                     (app_modes.tensor.mode == 1U ?
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
                app_modes.tensor.mode = 2U;
                mmio_write32(FRAMEBUFFER_BASE +
                             FRAMEBUFFER_TENSOR_PROD_CONTROL, 0U);
                return;
            }
        }
        break;
    }
    if (app_modes.tensor.mode == 2U &&
        mmio_read32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_READY) == 0U &&
        mmio_read32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_WRITING) == 0U) {
        app_modes.tensor.mode = 0U;
        console_puts("TENSOR PROD drained\r\n");
    }
    if (read_cycle() - app_modes.tensor.report_cycle >= SOC_CLOCK_HZ) {
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
            console_put_u32(app_modes.tensor.done[channel]);
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
        app_modes.tensor.report_cycle = read_cycle();
    }
}

#ifdef TENSOR_INGRESS_STATS
#include "platform/tensor_ingress.h"
static uint32_t bandwidth_mbps(uint64_t bytes, uint64_t cycles)
{
    return cycles == 0U ? 0U :
        (uint32_t)((bytes * (SOC_CLOCK_HZ / UINT64_C(1000000))) / cycles);
}

void tensor_ingress_print_stats(void)
{
    static TensorIngressSnapshot previous;
    static uint32_t have_previous;
    TensorIngressSnapshot current = tensor_ingress_snapshot();
    console_puts("SOC TENSOR completed/accepted/errors=");
    console_put_hex64(current.completed_bytes);
    console_putc('/'); console_put_hex64(current.accepted_bytes);
    console_putc('/'); console_put_hex64(current.errors);
    if (have_previous != 0U) {
        console_puts(" completed_MBps=");
        console_put_u32(bandwidth_mbps(current.completed_bytes - previous.completed_bytes,
                                      current.cycles - previous.cycles));
        console_puts(" delta_stall(aw/w/tl/source/b)=");
        console_put_hex64(current.aw_stall - previous.aw_stall);
        console_putc('/'); console_put_hex64(current.w_stall - previous.w_stall);
        console_putc('/'); console_put_hex64(current.tl_a_stall - previous.tl_a_stall);
        console_putc('/'); console_put_hex64(current.source_stall - previous.source_stall);
        console_putc('/'); console_put_hex64(current.b_stall - previous.b_stall);
    }
    console_puts(" flight/max/ack_max_cycles=");
    console_put_u32((uint32_t)current.inflight);
    console_putc('/'); console_put_u32((uint32_t)current.max_inflight);
    console_putc('/'); console_put_hex64(current.ack_latency_max);
    console_puts("\r\n");
    previous = current;
    have_previous = 1U;
}
#endif
