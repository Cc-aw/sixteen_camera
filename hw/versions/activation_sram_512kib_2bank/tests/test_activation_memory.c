#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include "activation_memory.h"

static bool complete(void *context, unsigned lane) {
    unsigned *seen = context;
    *seen |= 1U << lane;
    return true;
}

int main(void) {
    ActivationSramCapabilities cap = {
        .magic = UINT32_C(0x41535231), .abi = UINT32_C(0x10000),
        .enabled_mask = 7, .physical_bytes = ASRAM_BYTES_PER_BANK,
        .logical_bytes = ASRAM_ARENA_BYTES, .data_width_bits = 256,
        .clock_hz = ASRAM_CLOCK_HZ,
        .base = {ASRAM_BASE_0, ASRAM_BASE_1, ASRAM_BASE_2}
    };
    assert(activation_memory_capabilities_valid(&cap));
    unsigned seen = 0;
    for (unsigned lane = 0; lane < 3; ++lane) {
        int8_t *ddr = malloc(ASRAM_ARENA_BYTES + 64);
        int8_t *local = malloc(ASRAM_BYTES_PER_BANK + 64);
        assert(ddr != NULL && local != NULL);
        memset(ddr, 0x55, ASRAM_ARENA_BYTES + 64);
        memset(local, 0xa5, ASRAM_BYTES_PER_BANK + 64);
        ActivationArenaView reference, candidate;
        assert(activation_memory_bind(&reference, ACTIVATION_MEMORY_DDR, lane,
            ddr, UINT32_C(0x90000000) + lane * UINT32_C(0x400000),
            ASRAM_ARENA_BYTES, NULL, NULL, true));
        assert(!activation_memory_bind(&candidate, ACTIVATION_MEMORY_LOCAL, lane,
            NULL, 0, 0, &cap, local, false));
        assert(activation_memory_bind(&candidate, ACTIVATION_MEMORY_LOCAL, lane,
            NULL, 0, 0, &cap, local, true));
        for (size_t offset = 0; offset < ASRAM_ARENA_BYTES; offset += 64) {
            int8_t *a, *b;
            uintptr_t da, db;
            size_t size = ASRAM_ARENA_BYTES - offset;
            if (size > 64) size = 64;
            assert(activation_memory_offset(&reference, offset, size, &a, &da));
            assert(activation_memory_offset(&candidate, offset, size, &b, &db));
            assert(da - reference.dma_base == db - candidate.dma_base);
            memset(a, (int)lane + 1, size);
            memcpy(b, a, size);
        }
        assert(memcmp(ddr, local, ASRAM_ARENA_BYTES) == 0);
        for (size_t i = ASRAM_ARENA_BYTES; i < ASRAM_BYTES_PER_BANK + 64; ++i)
            assert((uint8_t)local[i] == 0xa5);
        int8_t *cpu;
        uintptr_t dma;
        assert(!activation_memory_offset(&candidate, ASRAM_ARENA_BYTES - 1, 2, &cpu, &dma));
        assert(!activation_memory_offset(&candidate, SIZE_MAX, 1, &cpu, &dma));
        assert(!activation_memory_offset(&candidate, 0, SIZE_MAX, &cpu, &dma));
        assert(!activation_memory_commit(&candidate, NULL, NULL));
        assert(activation_memory_commit(&candidate, complete, &seen));
        free(ddr); free(local);
    }
    assert(seen == 7);
    cap.base[0] = cap.base[2];
    assert(!activation_memory_capabilities_valid(&cap));
    return 0;
}
