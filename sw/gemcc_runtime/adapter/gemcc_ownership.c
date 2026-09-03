#include "gemcc_ownership.h"

enum { GEMCC_OWNER_CPU = 0, GEMCC_OWNER_GEMMINI = 1 };

static int g_owner = GEMCC_OWNER_CPU;
static unsigned g_cpu_to;
static unsigned g_gemmini_to;
static unsigned g_domain_switch;
static GemccOwnershipTransitionHook g_transition_hook;
static void *g_transition_ctx;

unsigned gemcc_ownership_cpu_to_gemmini_count(void) { return g_cpu_to; }
unsigned gemcc_ownership_gemmini_to_cpu_count(void) { return g_gemmini_to; }
unsigned gemcc_ownership_domain_switch_count(void) { return g_domain_switch; }

void gemcc_ownership_set_transition_hook(GemccOwnershipTransitionHook hook,
                                         void *ctx) {
  g_transition_hook = hook;
  g_transition_ctx = ctx;
}

static void gemcc_ownership_fence(void) {
#if defined(__riscv)
  __asm__ volatile("fence rw, rw" ::: "memory");
#endif
}

static void enter_gemmini(void) {
  if (g_owner == GEMCC_OWNER_GEMMINI)
    return;
  gemcc_ownership_fence();
  if (g_transition_hook)
    g_transition_hook(g_transition_ctx);
  gemcc_ownership_fence();
  g_owner = GEMCC_OWNER_GEMMINI;
  g_domain_switch++;
}

static void enter_cpu(void) {
  if (g_owner == GEMCC_OWNER_CPU)
    return;
  gemcc_ownership_fence();
  if (g_transition_hook)
    g_transition_hook(g_transition_ctx);
  gemcc_ownership_fence();
  g_owner = GEMCC_OWNER_CPU;
  g_domain_switch++;
}

void gemcc_cpu_to_gemmini(void) {
  g_cpu_to++;
  enter_gemmini();
}

void gemcc_gemmini_to_cpu(void) {
  g_gemmini_to++;
  enter_cpu();
}

void gemcc_ownership_require_cpu(void) { enter_cpu(); }
