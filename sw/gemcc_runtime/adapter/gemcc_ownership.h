#ifndef GEMCC_OWNERSHIP_H
#define GEMCC_OWNERSHIP_H

#ifdef __cplusplus
extern "C" {
#endif

typedef void (*GemccOwnershipTransitionHook)(void *ctx);

void gemcc_cpu_to_gemmini(void);
void gemcc_gemmini_to_cpu(void);
void gemcc_ownership_set_transition_hook(GemccOwnershipTransitionHook hook,
                                         void *ctx);
void gemcc_ownership_require_cpu(void);

unsigned gemcc_ownership_cpu_to_gemmini_count(void);
unsigned gemcc_ownership_gemmini_to_cpu_count(void);
unsigned gemcc_ownership_domain_switch_count(void);

#ifdef __cplusplus
}
#endif

#endif
