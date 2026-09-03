/*
 * Model-agnostic device services.  Host/Spike provide no-op stubs.
 * RoCC and Library consume the same model ABI; hardware details stay here.
 * instance init/destroy call idempotent backend init/shutdown; run calls fence.
 * Physical-device one-time setup is owned by the backend. Cross-thread model
 * calls require external serialization. dma_sync/cache_flush are reserved;
 * Library IR emits gemcc_cpu_to_gemmini / gemcc_gemmini_to_cpu at
 * execution-domain edges.  residency is Spike/pk page-in at init/run.
 */
#ifndef GEMCC_DEVICE_H
#define GEMCC_DEVICE_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

#ifndef GEMCC_DEVICE_HARDWARE_PROFILE_ID
#define GEMCC_DEVICE_HARDWARE_PROFILE_ID "xcvu13p-dim16-packed-quicktest"
#endif

typedef struct GemccDeviceHooks {
  int (*init)(void *ctx);
  int (*shutdown)(void *ctx);
  /* Reserved.  Model runtime does not call these; backends own coherence. */
  void (*dma_sync)(void *ctx, void *ptr, size_t bytes);
  void (*cache_flush)(void *ctx, void *ptr, size_t bytes);
  void (*fence)(void *ctx);
  void *ctx;
  /* Compiled execution target; set from the package HAL profile. */
  const char *hardware_profile_id;
  /* Spike/pk page residency at init/run. write!=0 stores once per page. */
  void (*residency)(void *ctx, void *ptr, size_t bytes, int write);
} GemccDeviceHooks;

const GemccDeviceHooks *gemcc_host_device_hooks(void);
const GemccDeviceHooks *gemcc_library_device_hooks(void);

#ifdef __cplusplus
}
#endif

#endif /* GEMCC_DEVICE_H */
