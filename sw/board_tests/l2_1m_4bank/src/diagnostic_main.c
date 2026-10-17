#include "build_id.h"
#define main frozen_workload_main
#include "../reference/src/boundary_main.c"
#undef main
int main(int argc, char **argv) {
#ifdef __riscv
    volatile uint32_t *uart = (volatile uint32_t *)AT_UART_BASE;
    uart[2] = 1; uart[4] = 0; uart[6] = 867;
    text("L2BTEST,BUILD,schema=1,test=diagnostic,build_id=" L2_BUILD_ID ",source=" L2_SOURCE_REVISION "\n");
    uint64_t lo = memory_safe_probe(0), hi = memory_probe_failed ? 0 : memory_safe_probe(4);
    if (memory_probe_failed || (lo | (hi << 32)) != UINT64_C(0x4d50563300010002) ||
        memory_read64(0x30) != 0x3000 || memory_read64(0x38) != 1048576 || memory_read64(0x58) != 4)
        at_fail("l2_board_test_requires_1m_4bank", lo | (hi << 32));
#endif
    return frozen_workload_main(argc, argv);
}
