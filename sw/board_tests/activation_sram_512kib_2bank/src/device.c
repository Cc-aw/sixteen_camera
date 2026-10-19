#include "suite.h"
#include "gemmini_frontend.h"

static const uintptr_t bases[3]={ASRAM_BASE_0,ASRAM_BASE_1,ASRAM_BASE_2};
static const volatile uint64_t expected_identity=EXPECTED_HW_ID;
static GfCommand tables[3][3] __attribute__((aligned(64)));
static volatile uint64_t traps;
extern uint64_t probe_read(uintptr_t);
extern void probe_write(uintptr_t);
uint64_t hw_cycle(void) { uint64_t x; __asm__ volatile("rdcycle %0":"=r"(x)::"memory"); return x; }
void hw_publish(void) { gf_publish(); }
void hw_text(const char *s)
{
    volatile uint32_t *u=(volatile uint32_t *)0x10020000UL;
    while (*s) {
        if (*s=='\n') { while (u[0]&0x80000000U) {} u[0]='\r'; }
        while (u[0]&0x80000000U) {} u[0]=(uint8_t)*s++;
    }
}
void hw_init(void)
{
    volatile uint32_t *u=(volatile uint32_t *)0x10020000UL;
    u[2]=1; u[4]=0; u[6]=867;
}
volatile uint8_t *hw_bank(unsigned lane) { return (volatile uint8_t *)bases[lane]; }
static uint64_t reg_read(unsigned offset) { return *(volatile uint64_t *)(uintptr_t)(ASRAM_CONTROL_BASE+offset); }
static void action(unsigned value)
{
    *(volatile uint64_t *)(uintptr_t)(ASRAM_CONTROL_BASE+0x40)=value;
    hw_publish();
    uint64_t begin=hw_cycle();
    while (reg_read(0x40)) if (hw_cycle()-begin>TIMEOUT) fail("action_timeout",0,0,value);
}
void hw_check_identity(void)
{
    for (unsigned lane=0;lane<3;lane++) {
        uint64_t id=gf_read(lane,10,0), cap=gf_read(lane,7,0), status=gf_status(lane);
        if (id!=expected_identity) fail("hardware_id",lane,expected_identity,id);
        if ((cap>>16)!=1 || (cap&15)!=15) fail("dma_capability",lane,0x1000f,cap);
        if ((status>>32)!=0x20000 || (status&(GF_OWNED|GF_ARMED|GF_FAULT|GF_DONE|GF_HOST_WAIT)))
            fail("lane_not_clean",lane,0,status);
    }
    const uint64_t expected[8]={0x41535231,0x10000,7,ASRAM_BYTES_PER_BANK,
                               ASRAM_ARENA_BYTES,256,ASRAM_CLOCK_HZ,2};
    for (unsigned i=0;i<8;i++) if (reg_read(i*8)!=expected[i]) fail("asram_capability",i*8,expected[i],reg_read(i*8));
    for (unsigned lane=0;lane<3;lane++) if (reg_read(0x48+lane*8)!=bases[lane])
        fail("asram_base",lane,bases[lane],reg_read(0x48+lane*8));
}
uint64_t hw_trap_count(void) { return traps; }
uintptr_t asram_trap(uint64_t cause, uintptr_t pc, uintptr_t address)
{
    traps++;
    field("ASRAM1,TRAP,cause=",cause); field(",pc=",pc); field(",mtval=",address); hw_text("\n");
    fail("unexpected_trap",pc,0,cause);
}
uint64_t hw_probe_hole(unsigned lane, unsigned slot, unsigned write)
{
    uintptr_t address=bases[lane]+(slot?ASRAM_RESERVED_STRIDE-8:ASRAM_BYTES_PER_BANK);
    /* This Rocket reports uncached D-channel errors outside the synchronous
       access-fault path. The shared test verifies service-port denied counts
       and zero physical operations, rather than treating zero data as success. */
    if (write) { probe_write(address); return 0; }
    return probe_read(address);
}
static void direct_wait(unsigned lane)
{
    hw_publish(); uint64_t begin=hw_cycle(); unsigned quiet=0;
    while (quiet<4) {
        uint64_t s=gf_status(lane);
        if (s&(GF_FAULT|GF_OWNED|GF_ARMED|GF_DONE|GF_HOST_WAIT)) fail("direct_status",lane,0,s);
        quiet=(!(s&(GF_GEMMINI_BUSY|GF_FENCE_BUSY)) && (s&GF_START_READY))?quiet+1:0;
        if (hw_cycle()-begin>TIMEOUT) fail("direct_timeout",lane,0,s);
    }
    hw_publish();
}
void hw_select(unsigned lane, unsigned mode)
{
    direct_wait(lane);
    uint64_t rc=gf_set_dma_load_mode(lane,mode,0);
    if (rc || gf_read(lane,8,0)!=mode) fail("mode",lane,mode,rc);
}
static uint64_t shape(unsigned rows, unsigned cols, unsigned address)
{ return ((uint64_t)rows<<48)|((uint64_t)cols<<32)|address; }
static uint64_t load_config(unsigned pixels)
{ return (UINT64_C(0x3c00)<<32)|(UINT64_C(32)<<16)|((uint64_t)pixels<<8)|1; }
void hw_poison(unsigned lane, const uint8_t *poison, unsigned rows, unsigned pixels)
{
    GF_DIRECT(lane,0,load_config(1),UINT64_C(32));
    for (unsigned i=0;i<rows;i+=32) {
        unsigned n=rows-i; if (n>32) n=32;
        GF_DIRECT(lane,2,(uintptr_t)(poison+i*32),shape(n,32,DEST-pixels+i));
    }
    direct_wait(lane);
}
void hw_submit(unsigned lane, const TestShape *s, const uint8_t *source)
{
    tables[lane][0]=gf_raw(0,load_config(s->pixels),s->stride,0);
    tables[lane][1]=gf_raw(2,(uintptr_t)(source+s->offset),shape(s->rows,s->cols,DEST),0);
    tables[lane][2]=gf_drain();
    hw_publish();
    uint64_t rc=gf_launch(lane,tables[lane],3,0,TIMEOUT,0);
    if (rc) fail("launch",lane,0,rc);
}
void hw_complete(unsigned lane)
{
    uint64_t begin=hw_cycle();
    for (;;) {
        uint64_t s=gf_status(lane);
        if (s&(GF_FAULT|GF_HOST_WAIT)) fail("frontend_fault",lane,0,s);
        if ((s&GF_DONE) && !(s&(GF_OWNED|GF_GEMMINI_BUSY|GF_FENCE_BUSY))) break;
        if (hw_cycle()-begin>TIMEOUT) fail("frontend_timeout",lane,0,s);
    }
    uint64_t rc=gf_ack(lane,0,0); if (rc) fail("ack",lane,0,rc);
    direct_wait(lane);
}
void hw_store(unsigned lane, const TestShape *s, uint8_t *output)
{
    GF_DIRECT(lane,0,UINT64_C(2),(UINT64_C(0x3c00)<<32)|32);
    unsigned rows=s->rows+s->pixels+1;
    for (unsigned i=0;i<rows;i+=32) {
        unsigned n=rows-i; if (n>32) n=32;
        GF_DIRECT(lane,3,(uintptr_t)(output+i*32),shape(n,32,DEST-s->pixels+i));
    }
    direct_wait(lane);
}
void hw_clear(void) { action(2); }
void hw_snapshot(unsigned lane, uint64_t values[2][COUNTERS])
{
    hw_publish(); action(1);
    for (unsigned port=0;port<2;port++) {
        uint64_t n=reg_read(0x60+(lane*2+port)*8);
        if (n) fail("outstanding",lane*2+port,0,n);
        for (unsigned i=0;i<COUNTERS;i++) values[port][i]=reg_read(0x100+lane*0x400+port*0x100+i*8);
    }
}
void *memset(void *dst,int value,size_t n) { uint8_t *p=dst; while(n--) *p++=(uint8_t)value; return dst; }
void *memcpy(void *dst,const void *src,size_t n) { uint8_t *p=dst; const uint8_t *q=src; while(n--) *p++=*q++; return dst; }
