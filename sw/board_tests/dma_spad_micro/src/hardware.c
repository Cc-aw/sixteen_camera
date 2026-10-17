#include "micro.h"
#include "case_config.h"
#include "gemmini_frontend.h"

uint64_t hw_cycle(void)
{
    uint64_t value;
    __asm__ volatile("rdcycle %0":"=r"(value)::"memory");
    return value;
}
void hw_text(const char *s)
{
    volatile uint32_t *uart=(volatile uint32_t *)0x10020000UL;
    while(*s) {
        if(*s=='\n'){while(uart[0]&0x80000000U){}uart[0]='\r';}
        while(uart[0]&0x80000000U){}
        uart[0]=(unsigned char)*s++;
    }
}
void hw_init(void)
{
    volatile uint32_t *uart=(volatile uint32_t *)0x10020000UL;
    uart[2]=1;uart[4]=0;uart[6]=867;
}
uint64_t hw_identity(void){return gf_read(MICRO_LANE,10,0);}
uint32_t hw_capability(void){return (uint32_t)gf_read(MICRO_LANE,7,0);}

void hw_wait(void)
{
    gf_publish();
    uint64_t begin=hw_cycle();
    unsigned quiet=0;
    while(quiet<4) {
        uint64_t status=gf_status(MICRO_LANE);
        if(status&(GF_FAULT|GF_OWNED|GF_ARMED))micro_fail("lane_fault_or_owned",status);
        quiet=(!(status&(GF_GEMMINI_BUSY|GF_FENCE_BUSY))&&(status&GF_START_READY))?quiet+1:0;
        if(hw_cycle()-begin>100000000)micro_fail("mvin_timeout",status);
    }
    gf_publish();
}
void hw_select(unsigned mode)
{
    hw_wait();
    uint64_t result=gf_set_dma_load_mode(MICRO_LANE,mode,0);
    if(result||gf_read(MICRO_LANE,8,0)!=mode)micro_fail("mode_switch",result);
}
static void load_config(uint16_t scale,unsigned pixels,unsigned stride)
{
    GF_DIRECT(MICRO_LANE,0,micro_load_config(scale,pixels),(uint64_t)stride);
}
void hw_prepare(const MicroCase *c,const uint8_t *poison)
{
    load_config(0x3c00,1,32);
    unsigned rows=c->rows+c->pixels+1,first=MICRO_DEST-c->pixels;
    for(unsigned i=0;i<rows;i+=32) {
        unsigned n=rows-i;if(n>32)n=32;
        GF_DIRECT(MICRO_LANE,2,(uintptr_t)(poison+i*32),micro_shape(n,32,first+i));
    }
    hw_wait();
    load_config(c->scale,c->pixels,c->stride);
    hw_wait();
}
void hw_load(const MicroCase *c,const uint8_t *source)
{
    GF_DIRECT(MICRO_LANE,2,(uintptr_t)(source+c->offset),
              micro_shape(c->rows,c->cols,MICRO_DEST));
}
void hw_dump(const MicroCase *c,uint8_t *output)
{
    GF_DIRECT(MICRO_LANE,0,UINT64_C(2),(UINT64_C(0x3c00)<<32)|32);
    unsigned rows=c->rows+c->pixels+1,first=MICRO_DEST-c->pixels;
    for(unsigned i=0;i<rows;i+=32) {
        unsigned n=rows-i;if(n>32)n=32;
        GF_DIRECT(MICRO_LANE,3,(uintptr_t)(output+i*32),micro_shape(n,32,first+i));
    }
    hw_wait();
}
static uint32_t counter(uint32_t config)
{
    uint64_t out;
#define ACCESS(op) __asm__ volatile(".insn r " op ",7,126,%0,%1,x0" : "=&r"(out) : "r"((uint64_t)config) : "memory")
    switch(MICRO_LANE) {
        case 0:ACCESS("0x0b");break;
        case 1:ACCESS("0x2b");break;
        case 2:ACCESS("0x5b");break;
        default:micro_fail("lane",MICRO_LANE);
    }
#undef ACCESS
    return (uint32_t)out;
}
void hw_counter_reset(void){(void)counter(1);}
void hw_counters(uint32_t values[35])
{
    (void)counter(2);
    for(unsigned i=8;i<=34;i++) {
        (void)counter(UINT32_C(0x80000008)|(i<<12));
        values[i]=counter(0);
    }
}

void micro_trap(uint64_t cause,uint64_t pc,uint64_t val)
{
    (void)pc;(void)val;
    micro_fail("trap",cause);
}
void *memset(void *p,int value,size_t count)
{
    unsigned char *out=p;
    while(count--)*out++=(unsigned char)value;
    return p;
}
void *memcpy(void *p,const void *q,size_t count)
{
    unsigned char *out=p;const unsigned char *in=q;
    while(count--)*out++=*in++;
    return p;
}
