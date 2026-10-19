#ifndef ACTIVATION_MEMORY_H
#define ACTIVATION_MEMORY_H
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include "activation_sram_map.h"

typedef enum {
    ACTIVATION_MEMORY_DDR = 0,
    ACTIVATION_MEMORY_LOCAL = 1
} ActivationMemoryKind;

typedef struct {
    int8_t *cpu_base;
    uintptr_t dma_base;
    size_t logical_bytes;
    size_t physical_bytes;
    unsigned frontend_lane;
    ActivationMemoryKind kind;
} ActivationArenaView;

typedef struct {
    uint32_t magic;
    uint32_t abi;
    uint32_t enabled_mask;
    uint32_t physical_bytes;
    uint32_t logical_bytes;
    uint32_t data_width_bits;
    uint32_t clock_hz;
    uintptr_t base[ASRAM_BANK_COUNT];
} ActivationSramCapabilities;

/* A platform integration must prove this callback covers scalar AND Saturn
 * writes and the service path. A missing callback fails closed; a compiler
 * clobber or an unrelated CSR read is not a completion implementation. */
typedef bool (*ActivationMemoryCompletion)(void *context, unsigned lane);

bool activation_memory_capabilities_valid(const ActivationSramCapabilities *cap);
bool activation_memory_bind(ActivationArenaView *view, ActivationMemoryKind kind,
                            unsigned lane, int8_t *ddr_cpu, uintptr_t ddr_dma,
                            size_t ddr_bytes, const ActivationSramCapabilities *cap,
                            int8_t *host_local_backing, bool quiescent);
bool activation_memory_offset(const ActivationArenaView *view, size_t offset,
                              size_t bytes, int8_t **cpu, uintptr_t *dma);
bool activation_memory_commit(const ActivationArenaView *view,
                              ActivationMemoryCompletion complete, void *context);
#endif
