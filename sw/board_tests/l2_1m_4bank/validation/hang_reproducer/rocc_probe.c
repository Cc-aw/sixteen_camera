#include "board_io.h"
#include "gemmini_frontend.h"
#ifndef ROUTE_TEST
#define ROUTE_TEST 0
#endif
int main(void) {
    volatile uint32_t *uart=(volatile uint32_t *)0x10020000UL;
    uart[2]=1;uart[4]=0;uart[6]=867;
    board_field("L2PROBE,BEGIN,route=",ROUTE_TEST);board_text("\n");
    uint64_t v;__asm__ volatile("csrr %0,vlenb":"=r"(v));
    board_field("L2PROBE,VLENB,value=",v);board_text("\n");
#if ROUTE_TEST == 0
    for(unsigned lane=0;lane<3;lane++) {
        board_field("L2PROBE,STATUS_BEGIN,lane=",lane);board_text("\n");
        v=gf_status(lane);
        board_field("L2PROBE,STATUS_END,lane=",lane);board_field(",value=",v);board_text("\n");
    }
#else
    board_text("L2PROBE,DIRECT_BEGIN,lane=0,funct=7\n");
    GF_DIRECT(0,7,0,0);
    board_fence();
    board_text("L2PROBE,DIRECT_END,lane=0,funct=7\n");
#endif
    board_text("L2PROBE,PASS\n");
    for(;;)__asm__ volatile("nop");
}
