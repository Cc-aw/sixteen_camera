/* Protocol/loop fault injection only; no hardware timing is modeled. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "micro.h"
#include "case_config.h"

static uint64_t ticks=1000;
static unsigned mode;
static uint32_t counters[35];
static uint8_t spad[MICRO_OUTPUT_BYTES];

void abort_test(void){exit(1);}
void hw_init(void){}
uint64_t hw_cycle(void){return ++ticks;}
void hw_text(const char *text){fputs(text,stdout);}
uint64_t hw_identity(void){return MICRO_EXPECTED_HW_ID;}
uint32_t hw_capability(void){return getenv("FAKE_CAPABILITY")?0:0x10007;}
void hw_select(unsigned selected){mode=selected;}
void hw_wait(void){ticks+=4;}
void hw_prepare(const MicroCase *c,const uint8_t *poison)
{
    memcpy(spad,poison,micro_output_bytes(c));
}
void hw_load(const MicroCase *c,const uint8_t *source)
{
    MicroCase once=*c;once.ops=1;
    micro_reference(source,spad,c);
    MicroTraffic t=micro_predict(&once,mode);
    counters[8]+=t.rows;counters[9]+=t.bytes;counters[11]+=t.groups;
    counters[18]+=t.get32;counters[19]+=t.get64;counters[21]+=t.assembled;
    counters[22]+=t.writes;counters[33]+=t.returned;
    ticks+=100+t.writes*2+t.get32+t.get64*2;
}
void hw_dump(const MicroCase *c,uint8_t *output)
{
    memcpy(output,spad,micro_output_bytes(c));
    if(getenv("FAKE_BAD_BYTE")&&mode==2)output[32]^=1;
    if(getenv("FAKE_BAD_GUARD")&&mode==2)output[micro_output_bytes(c)]=0;
}
void hw_counter_reset(void){memset(counters,0,sizeof(counters));}
void hw_counters(uint32_t values[35])
{
    memcpy(values,counters,sizeof(counters));
    if(getenv("FAKE_BAD_COUNTER")&&mode==2)values[22]++;
}
