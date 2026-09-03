#include "gemcc_device.h"

static int host_ok(void *ctx) {
  (void)ctx;
  return 0;
}

static void host_nop(void *ctx, void *ptr, size_t bytes) {
  (void)ctx;
  (void)ptr;
  (void)bytes;
}

static void host_fence(void *ctx) { (void)ctx; }

static const GemccDeviceHooks kHostHooks = {
    .init = host_ok,
    .shutdown = host_ok,
    .dma_sync = host_nop,
    .cache_flush = host_nop,
    .fence = host_fence,
    .ctx = 0,
    .hardware_profile_id = GEMCC_DEVICE_HARDWARE_PROFILE_ID,
    .residency = 0,
};

/* I: 无
 * P: 返回 Host/Spike 空设备钩子；profile 取编译期 GEMCC_DEVICE_HARDWARE_PROFILE_ID
 * O: 静态 GemccDeviceHooks 指针
 * A: shiroha_suki
 * T: 2026-08-27
 */
const GemccDeviceHooks *gemcc_host_device_hooks(void) { return &kHostHooks; }
