#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
static void capture(unsigned f, uint64_t a, uint64_t b) {
    printf("%u %016llx %016llx\n",f,(unsigned long long)a,(unsigned long long)b);
}
#define gemmini_fence() do {} while(0)
#define GEMMINI_LOOPCONV_CREDIT_ADMISSION 0
#include "include/gemmini.h"
int main(int argc, char **argv) {
    int h=argc>1?atoi(argv[1]):480, w=h==480?640:20;
    tiled_conv_auto(1,h,w,3,16,h/2,w/2,2,1,1,2,6,
        false,false,false,false,false,(void*)0x83000000UL,(void*)0x83200000UL,
        (void*)0x83210000UL,(void*)0x83400000UL,SILU_LUT,1.0f,1,0,0,WS);
}
