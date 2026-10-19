#include "activation_memory.h"

bool activation_memory_capabilities_valid(const ActivationSramCapabilities *cap) {
    static const uintptr_t bases[ASRAM_BANK_COUNT] = {
        ASRAM_BASE_0, ASRAM_BASE_1, ASRAM_BASE_2
    };
    if (cap == NULL || cap->magic != UINT32_C(0x41535231) ||
        cap->abi != (ASRAM_ABI_MAJOR << 16 | ASRAM_ABI_MINOR) ||
        cap->enabled_mask != 7 || cap->physical_bytes != ASRAM_BYTES_PER_BANK ||
        cap->logical_bytes != ASRAM_ARENA_BYTES || cap->data_width_bits != 256 ||
        cap->clock_hz != ASRAM_CLOCK_HZ) {
        return false;
    }
    for (unsigned lane = 0; lane < ASRAM_BANK_COUNT; ++lane) {
        if (cap->base[lane] != bases[lane]) {
            return false;
        }
    }
    return true;
}

bool activation_memory_bind(ActivationArenaView *view, ActivationMemoryKind kind,
                            unsigned lane, int8_t *ddr_cpu, uintptr_t ddr_dma,
                            size_t ddr_bytes, const ActivationSramCapabilities *cap,
                            int8_t *host_local_backing, bool quiescent) {
    if (view == NULL || lane >= ASRAM_BANK_COUNT || !quiescent) {
        return false;
    }
    ActivationArenaView next = {
        .logical_bytes = ASRAM_ARENA_BYTES, .frontend_lane = lane, .kind = kind
    };
    if (kind == ACTIVATION_MEMORY_DDR) {
        if (ddr_cpu == NULL || ddr_bytes < next.logical_bytes ||
            ddr_dma > UINTPTR_MAX - ddr_bytes) {
            return false;
        }
        next.cpu_base = ddr_cpu;
        next.dma_base = ddr_dma;
        next.physical_bytes = ddr_bytes;
    } else if (kind == ACTIVATION_MEMORY_LOCAL) {
        if (!activation_memory_capabilities_valid(cap)) {
            return false;
        }
        next.dma_base = cap->base[lane];
        next.physical_bytes = cap->physical_bytes;
#ifdef ACTIVATION_MEMORY_HOST_TEST
        if (host_local_backing == NULL) {
            return false;
        }
        next.cpu_base = host_local_backing;
#else
        (void)host_local_backing;
        next.cpu_base = (int8_t *)next.dma_base;
#endif
    } else {
        return false;
    }
    *view = next;
    return true;
}

bool activation_memory_offset(const ActivationArenaView *view, size_t offset,
                              size_t bytes, int8_t **cpu, uintptr_t *dma) {
    if (view == NULL || view->cpu_base == NULL || cpu == NULL || dma == NULL ||
        bytes == 0 || offset > view->logical_bytes ||
        bytes > view->logical_bytes - offset ||
        view->logical_bytes > view->physical_bytes ||
        view->dma_base > UINTPTR_MAX - offset ||
        bytes > UINTPTR_MAX - (view->dma_base + offset)) {
        return false;
    }
    *cpu = view->cpu_base + offset;
    *dma = view->dma_base + offset;
    return true;
}

bool activation_memory_commit(const ActivationArenaView *view,
                              ActivationMemoryCompletion complete, void *context) {
    return view != NULL && view->frontend_lane < ASRAM_BANK_COUNT &&
        complete != NULL && complete(context, view->frontend_lane);
}
