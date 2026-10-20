/* Host-only sequence and fault-injection model. It cannot validate TL, PMP,
 * real RVV ordering, hardware cycles or physical denied responses. */
#include "suite.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

static uint8_t banks[3][ASRAM_BYTES_PER_BANK] __attribute__((aligned(64)));
static uint8_t spad[3][128][DIM];
static uint64_t counters[3][2][COUNTERS], ticks, trap_count;
static int enabled(const char *key) { return getenv(key)!=NULL; }
static int local(unsigned lane,const void *p)
{ return (uintptr_t)p>=(uintptr_t)banks[lane] && (uintptr_t)p<(uintptr_t)banks[lane]+ASRAM_BYTES_PER_BANK; }
void host_abort(void) { exit(1); }
void hw_init(void) {}
void hw_text(const char *s) { fputs(s,stdout); }
uint64_t hw_cycle(void) { return ++ticks; }
void hw_publish(void) {}
volatile uint8_t *hw_bank(unsigned lane) { return banks[enabled("FAKE_ALIAS")?0:lane]; }
void hw_check_identity(void) { if(enabled("FAKE_ID")) fail("hardware_id",0,EXPECTED_HW_ID,0); }
void hw_rvv_copy(void *dst,const void *src,size_t n)
{ memcpy(dst,src,n); if(enabled("FAKE_RVV")) ((uint8_t *)dst)[n-1]^=1; }
uint64_t hw_probe_hole(unsigned lane,unsigned slot,unsigned write)
{
    (void)slot;
    uint64_t *c=counters[lane][1];
    c[0]++; c[1]+=!enabled("FAKE_HOLE_RETIRED"); c[write?3:2]++;
    c[15]+=!enabled("FAKE_HOLE");
    if(enabled("FAKE_HOLE_ALIAS")) c[write?13:12]++;
    if(enabled("FAKE_HOLE_ROUTE")) counters[lane][0][0]++;
    return !write && enabled("FAKE_HOLE_DATA");
}
uint64_t hw_trap_count(void) { return trap_count; }
void hw_select(unsigned lane,unsigned mode) { (void)lane;(void)mode; }
void hw_poison(unsigned lane,const uint8_t *p,unsigned rows,unsigned pixels)
{ for(unsigned r=0;r<rows;r++) memcpy(spad[lane][DEST-pixels+r],p+r*DIM,DIM); }
static void count(unsigned lane,unsigned read,size_t n)
{
    uint64_t *c=counters[lane][0]; c[0]++; c[1]++; c[read?2:3]++; c[read?5:6]+=n;
}
void hw_submit(unsigned lane,const TestShape *s,const uint8_t *src)
{
    if(enabled("FAKE_TIMEOUT")) fail("frontend_timeout",lane,0,0);
    /* Destination-index oracle: derive each cell's source rather than replay
       the reverse-repeat write loops in reference_output(). */
    for(unsigned r=DEST-s->pixels;r<DEST+s->rows+1;r++) for(unsigned c=0;c<DIM;c++) {
        unsigned k=c/s->cols; int source_row=(int)r-(int)DEST+(int)k;
        if(k<s->pixels && source_row>=0 && (unsigned)source_row<s->rows)
            spad[lane][r][c]=src[s->offset+(unsigned)source_row*s->stride+c%s->cols];
    }
    if(local(lane,src)) count(lane,1,s->rows*s->cols);
}
void hw_complete(unsigned lane) { (void)lane; }
void hw_store(unsigned lane,const TestShape *s,uint8_t *dst)
{
    for(unsigned r=0;r<s->rows+s->pixels+1;r++) memcpy(dst+r*DIM,spad[lane][DEST-s->pixels+r],DIM);
    if(local(lane,dst)) count(lane,0,output_size(s));
    if(enabled("FAKE_DATA")) dst[0]^=1;
    if(enabled("FAKE_GUARD")) dst[-1]=0;
}
void hw_clear(void) { memset(counters,0,sizeof(counters)); }
void hw_snapshot(unsigned lane,uint64_t v[2][COUNTERS])
{ memcpy(v,counters[lane],sizeof(counters[lane])); if(enabled("FAKE_COUNTER")) v[0][1]++; }
