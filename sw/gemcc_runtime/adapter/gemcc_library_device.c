#include "gemcc_device.h"
#include "gemcc_ownership.h"
#include "gemmini_dma_prefault.h"
#include "gemmini.h"
#include "myboard_cache.h"

#include <stddef.h>
#include <stdint.h>

#ifndef GEMCC_GEMMINI_INSTANCE_COUNT
#define GEMCC_GEMMINI_INSTANCE_COUNT 1
#endif

#if defined(BAREMETAL) && !GEMCC_COHERENCE_BACKEND_DECLARED
#error "bare-metal Library target requires an explicit coherence backend"
#endif

enum {
  GEMCC_LIBRARY_UNINITIALIZED = 0,
  GEMCC_LIBRARY_INITIALIZING = 1,
  GEMCC_LIBRARY_READY = 2,
};

static int g_library_init_state;

static void library_flush_all(void) {
#if GEMCC_GEMMINI_INSTANCE_COUNT == 1
  gemmini_flush(0);
#else
#error "unsupported multi-Gemmini Library instance count"
#endif
}

static int library_ok(void *ctx) {
  (void)ctx;
  return 0;
}

static void library_platform_transition(void *ctx) {
  (void)ctx;
#if GEMCC_COHERENCE_BACKEND_MYBOARD
  gemcc_myboard_l1_evict();
#endif
}

static int library_init(void *ctx) {
  (void)ctx;
  int expected = GEMCC_LIBRARY_UNINITIALIZED;
  if (__atomic_compare_exchange_n(&g_library_init_state, &expected,
                                  GEMCC_LIBRARY_INITIALIZING, 0,
                                  __ATOMIC_ACQ_REL, __ATOMIC_ACQUIRE)) {
    gemcc_ownership_set_transition_hook(library_platform_transition, 0);
    library_flush_all();
    __atomic_store_n(&g_library_init_state, GEMCC_LIBRARY_READY,
                     __ATOMIC_RELEASE);
    return 0;
  }
  while (__atomic_load_n(&g_library_init_state, __ATOMIC_ACQUIRE) !=
         GEMCC_LIBRARY_READY) {
  }
  return 0;
}

static void library_nop_range(void *ctx, void *ptr, size_t bytes) {
  (void)ctx;
  (void)ptr;
  (void)bytes;
}

static void library_fence(void *ctx) {
  (void)ctx;
  gemcc_ownership_require_cpu();
#if defined(__riscv)
  __asm__ volatile("fence rw, rw" ::: "memory");
#endif
}

static void library_residency(void *ctx, void *ptr, size_t bytes, int write) {
  (void)ctx;
#ifdef BAREMETAL
  (void)ptr;
  (void)bytes;
  (void)write;
#else
  if (write)
    gemmini_dma_prefault(ptr, bytes);
  else
    gemmini_dma_touch(ptr, bytes);
#endif
}

static const GemccDeviceHooks kLibraryHooks = {
    .init = library_init,
    .shutdown = library_ok,
    .dma_sync = library_nop_range,
    .cache_flush = library_nop_range,
    .fence = library_fence,
    .ctx = 0,
    .hardware_profile_id = GEMCC_DEVICE_HARDWARE_PROFILE_ID,
    .residency = library_residency,
};

const GemccDeviceHooks *gemcc_library_device_hooks(void) {
  return &kLibraryHooks;
}
