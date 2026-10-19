#include "suite.h"

static uint8_t input[3][MAX_SOURCE] __attribute__((aligned(64)));
static uint8_t output[3][MAX_OUTPUT+128] __attribute__((aligned(64)));
static uint8_t poison[MAX_OUTPUT] __attribute__((aligned(64)));
static uint8_t gold[MAX_OUTPUT], vector_in[4096] __attribute__((aligned(64)));
static uint8_t expected_source[MAX_SOURCE];
static uint8_t vector_out[4096] __attribute__((aligned(64)));
static unsigned cases_done, dma_done, parallel_done, holes_denied;

void text_number(uint64_t v)
{
    char p[24]; unsigned n=sizeof(p); p[--n]=0;
    do { p[--n]=(char)('0'+v%10); v/=10; } while(v);
    hw_text(p+n);
}
void field(const char *s,uint64_t v) { hw_text(s); text_number(v); }
void fail(const char *reason,uint64_t addr,uint64_t expected,uint64_t actual)
{
    hw_text("ASRAM1,FAIL,reason="); hw_text(reason); field(",address=",addr);
    field(",expected=",expected); field(",actual=",actual); hw_text("\n");
#ifdef ASRAM_HOST_TEST
    extern void host_abort(void); host_abort();
#endif
    for (;;) {}
}
static void case_result(const char *kind,unsigned lane,unsigned pass,uint64_t start,size_t bytes)
{
    hw_text("ASRAM1,CASE,kind="); hw_text(kind); field(",lane=",lane); field(",pass=",pass);
    field(",bytes=",bytes); field(",cycles=",hw_cycle()-start); hw_text(",match=1\n"); cases_done++;
}
static void check_bytes(volatile const uint8_t *p,const uint8_t *expected,size_t n,const char *reason)
{
    for (size_t i=0;i<n;i++) if (p[i]!=expected[i]) fail(reason,(uintptr_t)(p+i),expected[i],p[i]);
}
static void scalar_full(void)
{
    for (unsigned pass=0;pass<2;pass++) {
        /* Write ALL banks before checking ANY bank: catches inter-lane aliasing. */
        for (unsigned lane=0;lane<3;lane++) {
            volatile uint64_t *p=(volatile uint64_t *)hw_bank(lane);
            for (size_t off=0;off<ASRAM_BYTES_PER_BANK;off+=8) p[off/8]=pattern_word(lane,off,pass);
        }
        hw_publish();
        for (unsigned lane=0;lane<3;lane++) {
            uint64_t start=hw_cycle(); volatile const uint64_t *p=(volatile const uint64_t *)hw_bank(lane);
            for (size_t off=0;off<ASRAM_BYTES_PER_BANK;off+=8) {
                uint64_t want=pattern_word(lane,off,pass), actual=p[off/8];
                if (actual!=want) fail("scalar_full",(uintptr_t)&p[off/8],want,actual);
            }
            case_result("scalar_full",lane,pass,start,ASRAM_BYTES_PER_BANK);
        }
    }
}
static void byte_masks(unsigned lane)
{
    uint64_t start=hw_cycle(); uint8_t expected[128];
    /* First/last span and both sides of every 128KiB depth-group boundary. */
    for (unsigned region=0;region<19;region++) {
        size_t off=region==0?0:(region==18?ASRAM_BYTES_PER_BANK-128:region*0x20000U-32);
        volatile uint8_t *p=hw_bank(lane)+off;
        for (unsigned i=0;i<128;i++) p[i]=expected[i]=0xa5;
        for (unsigned i=0;i<128;i++) {
            expected[i]=(uint8_t)(i*29+lane*43+region);
            p[i]=expected[i]; hw_publish(); check_bytes(p,expected,128,"byte_mask");
        }
        *(volatile uint16_t *)(p+2)=0x1234; expected[2]=0x34; expected[3]=0x12;
        *(volatile uint32_t *)(p+28)=0x89abcdefU;
        for (unsigned i=0;i<4;i++) expected[28+i]=(uint8_t)(0x89abcdefU>>(i*8));
        *(volatile uint64_t *)(p+56)=UINT64_C(0xfedcba9876543210);
        for (unsigned i=0;i<8;i++) expected[56+i]=(uint8_t)(UINT64_C(0xfedcba9876543210)>>(i*8));
        hw_publish(); check_bytes(p,expected,128,"mixed_width");
    }
    case_result("byte_masks",lane,0,start,19*128);
}
static void rvv_full(unsigned lane)
{
    uint64_t start=hw_cycle();
    for (size_t off=0;off<ASRAM_BYTES_PER_BANK;off+=sizeof(vector_in)) {
        size_t n=ASRAM_BYTES_PER_BANK-off; if (n>sizeof(vector_in)) n=sizeof(vector_in);
        for (size_t i=0;i<n;i++) { vector_in[i]=(uint8_t)(lane*73+(off+i)*13+((off+i)>>12)); vector_out[i]=0; }
        hw_publish();
        hw_rvv_copy((void *)(hw_bank(lane)+off),vector_in,n);
        hw_publish();
        hw_rvv_copy(vector_out,(const void *)(hw_bank(lane)+off),n);
        hw_publish();
        check_bytes(vector_out,vector_in,n,"rvv_readback");
        check_bytes(hw_bank(lane)+off,vector_in,n,"rvv_to_scalar");
    }
    /* Non-VL-multiple, unaligned tails across a 32-byte boundary. */
    hw_rvv_copy((void *)(hw_bank(lane)+0x2001f),vector_in,93);
    hw_rvv_copy(vector_out,(const void *)(hw_bank(lane)+0x2001f),93);
    hw_publish(); check_bytes(vector_out,vector_in,93,"rvv_tail");
    case_result("rvv_full",lane,0,start,ASRAM_BYTES_PER_BANK);
}
static void holes(unsigned lane)
{
    uint64_t start=hw_cycle();
    for (unsigned slot=0;slot<2;slot++) for (unsigned write=0;write<2;write++) {
        uint64_t values[2][COUNTERS];
        uintptr_t address=(uintptr_t)(lane==0?ASRAM_BASE_0:(lane==1?ASRAM_BASE_1:ASRAM_BASE_2))+
            (slot?ASRAM_RESERVED_STRIDE-8:ASRAM_BYTES_PER_BANK);
        hw_clear();
        uint64_t value=hw_probe_hole(lane,slot,write);
        hw_publish(); hw_snapshot(lane,values);
        uint64_t *s=values[1], *dma=values[0], put=s[3]+s[4];
        unsigned match=s[0]==1 && s[1]==1 && s[2]==!write && put==write && s[15]==1 &&
            !s[12] && !s[13] && !s[16] && !value && !hw_trap_count() &&
            !dma[0] && !dma[1] && !dma[12] && !dma[13] && !dma[15];
        field("ASRAM1,HOLE,lane=",lane); field(",slot=",slot); field(",write=",write);
        field(",address=",address); field(",accepted=",s[0]); field(",retired=",s[1]);
        field(",get=",s[2]); field(",put=",put); field(",denied=",s[15]);
        field(",physical_reads=",s[12]); field(",physical_writes=",s[13]);
        field(",corrupt=",s[16]); field(",value=",value); field(",match=",match); hw_text("\n");
        if (!match) fail("hole_denied_response",address,1,s[15]);
        holes_denied++;
    }
    case_result("cpu_holes",lane,0,start,4);
}
static void setup_trial(unsigned lane,unsigned mode,unsigned layout,unsigned slot,unsigned route,
                        const uint8_t **src,uint8_t **dst)
{
    const TestShape *s=&shapes[layout];
    static const size_t in_offset[3]={0x4000,0x1ffe0,ASRAM_BYTES_PER_BANK-4096};
    static const size_t out_offset[3]={0x10000,0x3ffe0,ASRAM_BYTES_PER_BANK-8192};
    hw_select(lane,mode); fill_source(input[lane],s,lane);
    *src=(route&1)?(const uint8_t *)(hw_bank(lane)+in_offset[slot]):input[lane];
    *dst=(route&2)?(uint8_t *)(hw_bank(lane)+out_offset[slot]):output[lane]+64;
    if (route==3) hw_rvv_copy((void *)*src,input[lane],source_size(s));
    else for (size_t i=0;i<source_size(s);i++) ((volatile uint8_t *)*src)[i]=input[lane][i];
    for (size_t i=0;i<output_size(s)+128;i++) ((volatile uint8_t *)*dst)[(ptrdiff_t)i-64]=0x6d;
    for (size_t i=0;i<output_size(s);i++) ((volatile uint8_t *)*dst)[i]=0x5a;
    hw_publish();
    hw_poison(lane,poison,s->rows+s->pixels+1,s->pixels);
}
static void verify_trial(unsigned lane,unsigned layout,unsigned route,const uint8_t *src,uint8_t *dst,
                         uint64_t values[2][COUNTERS])
{
    const TestShape *s=&shapes[layout]; reference_output(gold,s,lane);
    fill_source(expected_source,s,lane);
    check_bytes(dst,gold,output_size(s),"dma_output"); check_bytes(src,expected_source,source_size(s),"dma_source");
    check_bytes(input[lane],expected_source,source_size(s),"cpu_source");
    for (unsigned i=0;i<64;i++) {
        if (((volatile uint8_t *)dst)[(ptrdiff_t)i-64]!=0x6d || ((volatile uint8_t *)dst)[output_size(s)+i]!=0x6d)
            fail("dma_guard",lane,0x6d,i);
    }
    /* Read local DMA output using REAL RVV before any scalar fallback. */
    if (route&2) {
        hw_rvv_copy(vector_out,dst,output_size(s)); hw_publish();
        check_bytes(vector_out,gold,output_size(s),"dma_to_rvv");
    }
    hw_snapshot(lane,values);
    for (unsigned port=0;port<2;port++) {
        if (values[port][0]!=values[port][1] || values[port][15] || values[port][16])
            fail("asram_counters",lane*2+port,values[port][0],values[port][1]);
    }
    if (((route&1)!=0)!=(values[0][2]!=0) || ((route&2)!=0)!=((values[0][3]+values[0][4])!=0))
        fail("dma_route",lane,route,values[0][0]);
    if (!route && values[0][0]) fail("ddr_was_absorbed",lane,0,values[0][0]);
}
static void dma_trial(unsigned lane,unsigned mode,unsigned layout,unsigned slot,unsigned route)
{
    const uint8_t *src; uint8_t *dst; uint64_t values[2][COUNTERS];
    setup_trial(lane,mode,layout,slot,route,&src,&dst);
    hw_clear();
    uint64_t start=hw_cycle(); hw_submit(lane,&shapes[layout],src); hw_complete(lane);
    hw_store(lane,&shapes[layout],dst); uint64_t cycles=hw_cycle()-start;
    verify_trial(lane,layout,route,src,dst,values);
    field("ASRAM1,DMA,lane=",lane); field(",mode=",mode); field(",layout=",layout);
    field(",slot=",slot); field(",route=",route); field(",cycles=",cycles);
    field(",get=",values[0][2]); field(",put=",values[0][3]+values[0][4]);
    hw_text(",match=1,denied=0,pending=0\n"); dma_done++;
}
static void parallel_trial(unsigned mode)
{
    const uint8_t *src[3]; uint8_t *dst[3]; uint64_t values[2][COUNTERS];
    for (unsigned lane=0;lane<3;lane++) setup_trial(lane,mode,0,1,3,&src[lane],&dst[lane]);
    hw_clear(); uint64_t start=hw_cycle();
    for (unsigned lane=0;lane<3;lane++) hw_submit(lane,&shapes[0],src[lane]);
    for (unsigned lane=0;lane<3;lane++) hw_complete(lane);
    for (unsigned lane=0;lane<3;lane++) hw_store(lane,&shapes[0],dst[lane]);
    uint64_t cycles=hw_cycle()-start;
    for (unsigned lane=0;lane<3;lane++) verify_trial(lane,0,3,src[lane],dst[lane],values);
    field("ASRAM1,PARALLEL,mode=",mode); field(",cycles=",cycles);
    hw_text(",lanes=7,match=1\n"); parallel_done++;
}
int main(void)
{
    hw_init(); hw_check_identity();
    hw_text("ASRAM1,BUILD,schema=2,hardware=");
#ifdef ASRAM_HOST_TEST
    text_number(0);
#else
    text_number(1);
#endif
    hw_text(",hardware_id=" EXPECTED_HW_ID_TEXT ",package=" PACKAGE_ID ",clock_hz=100000000\n");
    for (unsigned i=0;i<MAX_OUTPUT;i++) poison[i]=0xa5;
    hw_text("ASRAM1,BEGIN,kind=scalar_full\n"); scalar_full();
    for (unsigned lane=0;lane<3;lane++) { byte_masks(lane); rvv_full(lane); holes(lane); }
    for (unsigned lane=0;lane<3;lane++) for (unsigned mode=0;mode<4;mode++)
        for (unsigned layout=0;layout<3;layout++) for (unsigned slot=0;slot<3;slot++)
            for (unsigned route=0;route<4;route++) dma_trial(lane,mode,layout,slot,route);
    for (unsigned mode=0;mode<4;mode++) parallel_trial(mode);
    for (unsigned lane=0;lane<3;lane++) hw_select(lane,0);
    field("ASRAM1,PASS,cases=",cases_done); field(",dma=",dma_done);
    field(",parallel=",parallel_done); field(",denied=",holes_denied);
    field(",traps=",hw_trap_count()); hw_text("\n");
#ifndef ASRAM_HOST_TEST
    for (;;) __asm__ volatile("wfi");
#endif
    return 0;
}
