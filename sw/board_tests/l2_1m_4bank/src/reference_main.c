#include "build_id.h"
#define main frozen_workload_main
#include "../reference/src/main.c"
#undef main
int main(int argc, char **argv) {
#ifdef __riscv
    volatile uint32_t *uart = (volatile uint32_t *)AT_UART_BASE;
    uart[2] = 1; uart[4] = 0; uart[6] = 867;
    text("L2BTEST,BUILD,schema=1,test=reference,build_id=" L2_BUILD_ID ",source=" L2_SOURCE_REVISION "\n");
#endif
    return frozen_workload_main(argc, argv);
}
