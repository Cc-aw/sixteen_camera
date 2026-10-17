#include "micro.h"
#include "case_config.h"

static const char *const modes[3]={"legacy","read_coalesced","read_assembled"};
static const char *const cases[2]={"continuous","strided"};
static struct {uint8_t before[64],data[MICRO_SOURCE_BYTES],after[64];}
    source __attribute__((aligned(64)));
static uint8_t saved[MICRO_SOURCE_BYTES];
static uint8_t gold[MICRO_OUTPUT_BYTES],poison[MICRO_OUTPUT_BYTES] __attribute__((aligned(64)));
static struct {uint8_t before[64],data[MICRO_OUTPUT_BYTES],after[64];}
    output __attribute__((aligned(64)));
static const volatile uint64_t expected_identity=MICRO_EXPECTED_HW_ID;
static uint32_t values[35];
typedef struct {uint64_t total,min,max;unsigned count;} Stats;
static Stats stats[2][3];

static void number(uint64_t value)
{
    char buf[24];unsigned n=sizeof(buf);
    buf[--n]=0;
    do {buf[--n]=(char)('0'+value%10);value/=10;}while(value);
    hw_text(buf+n);
}
static void field(const char *name,uint64_t value){hw_text(name);number(value);}
void micro_fail(const char *reason,uint64_t value)
{
    hw_text("SPADM1,FAIL,reason=");hw_text(reason);field(",value=",value);hw_text("\n");
#ifdef MICRO_HOST_TEST
    extern void abort_test(void);
    abort_test();
#endif
    for(;;){}
}
static void fill(uint8_t *p,unsigned n,uint8_t value){while(n--)*p++=value;}
static void equal(const uint8_t *a,const uint8_t *b,unsigned n,const char *kind)
{
    for(unsigned i=0;i<n;i++)if(a[i]!=b[i]) {
        hw_text("SPADM1,DIFF,kind=");hw_text(kind);field(",byte=",i);
        field(",expected=",b[i]);field(",actual=",a[i]);hw_text("\n");
        micro_fail(kind,i);
    }
}
static void guard(const uint8_t *p)
{
    for(unsigned i=0;i<64;i++)if(p[i]!=0x6d)micro_fail("guard",i);
}
static void check_count(unsigned id,uint32_t expected)
{
    if(values[id]!=expected) {
        field("SPADM1,COUNT_DIFF,id=",id);field(",expected=",expected);
        field(",actual=",values[id]);hw_text("\n");micro_fail("counter",id);
    }
}
static void trial(const MicroCase *c,unsigned which,unsigned mode,unsigned sample,unsigned warmup)
{
    hw_select(mode);
    fill(output.data,sizeof(output.data),0x5a);
    hw_prepare(c,poison);
    hw_counter_reset();
    uint64_t begin=hw_cycle();
    for(unsigned op=0;op<c->ops;op++)hw_load(c,source.data);
    hw_wait();
    uint64_t elapsed=hw_cycle()-begin;
    hw_counters(values);
    /* Counter capture precedes mvout; initialization, verification and UART
     * are outside the complete mvin issue-to-idle timing window. */
    hw_dump(c,output.data);
    equal(output.data,gold,micro_output_bytes(c),"spad");
    equal(source.data,saved,micro_source_bytes(c),"source");
    guard(source.before);guard(source.after);guard(output.before);guard(output.after);
    MicroTraffic t=micro_predict(c,mode);
    check_count(8,t.rows);check_count(9,t.bytes);check_count(11,t.groups);
    check_count(18,t.get32);check_count(19,t.get64);check_count(21,t.assembled);
    check_count(22,t.writes);check_count(31,0);check_count(33,t.returned);
    if(!elapsed)micro_fail("zero_cycles",0);
    hw_text("SPADM1,RESULT,case=");hw_text(cases[which]);hw_text(",mode=");hw_text(modes[mode]);
    field(",sample=",sample);field(",warmup=",warmup);field(",ops=",c->ops);field(",cycles=",elapsed);
    field(",read_merge=",t.merge);field(",assembly=",t.assembly);
    field(",compared_bytes=",micro_output_bytes(c));
    hw_text(",bit_exact=1,source_unchanged=1,guards=1");
    for(unsigned i=8;i<=34;i++){hw_text(",c");number(i);field("=",values[i]);}
    hw_text("\n");
    if(!warmup) {
        Stats *s=&stats[which][mode];
        if(!s->count||elapsed<s->min)s->min=elapsed;
        if(!s->count||elapsed>s->max)s->max=elapsed;
        s->total+=elapsed;s->count++;
    }
}

int main(void)
{
    hw_init();
    uint64_t identity=hw_identity();uint32_t capability=hw_capability();
    if(identity!=expected_identity)micro_fail("hardware_identity",identity);
    if((capability>>16)!=1||(capability&7)!=7)micro_fail("three_modes_required",capability);
    hw_text("SPADM1,BUILD,schema=1,suite=two_layout_mvin,hardware=");
#ifdef MICRO_HOST_TEST
    number(0);
#else
    number(1);
#endif
    field(",hardware_id=",identity);field(",capability=",capability);
    field(",clock_hz=",MICRO_CLOCK_HZ);field(",lane=",MICRO_LANE);
    field(",samples=",MICRO_SAMPLES);field(",warmups=",MICRO_WARMUPS);field(",ops=",MICRO_OPS);
    hw_text(",timing=cpu_issue_to_idle,package_build=" MICRO_BUILD_ID "\n");
    fill(source.before,64,0x6d);fill(source.after,64,0x6d);
    fill(output.before,64,0x6d);fill(output.after,64,0x6d);
    fill(poison,sizeof(poison),MICRO_POISON);
    for(unsigned which=0;which<2;which++) {
        MicroCase c={MICRO_C,MICRO_N,MICRO_P,which?MICRO_STRIDE:MICRO_C,MICRO_OFFSET,MICRO_OPS,MICRO_SCALE_BITS};
        micro_fill_source(source.data,&c);
        for(unsigned i=0;i<micro_source_bytes(&c);i++)saved[i]=source.data[i];
        micro_reference(source.data,gold,&c);
        hw_text("SPADM1,CASE,case=");hw_text(cases[which]);
        field(",c=",c.cols);field(",n=",c.rows);field(",p=",c.pixels);
        field(",stride=",c.stride);field(",offset=",c.offset);field(",scale_bits=",c.scale);
        field(",output_bytes=",micro_output_bytes(&c));
        hw_text(",group_cost=included\n");
        for(unsigned pass=0;pass<MICRO_WARMUPS+MICRO_SAMPLES;pass++)
            for(unsigned order=0;order<3;order++) {
                unsigned mode=pass&1?2-order:order;
                trial(&c,which,mode,pass<MICRO_WARMUPS?pass:pass-MICRO_WARMUPS,pass<MICRO_WARMUPS);
            }
    }
    for(unsigned which=0;which<2;which++)for(unsigned mode=0;mode<3;mode++) {
        Stats *s=&stats[which][mode];
        hw_text("SPADM1,SUMMARY,case=");hw_text(cases[which]);hw_text(",mode=");hw_text(modes[mode]);
        field(",samples=",s->count);field(",ops=",MICRO_OPS);
        field(",total_cycles=",s->total);field(",min_cycles=",s->min);field(",max_cycles=",s->max);
        field(",gain_x1000=",stats[which][0].total*1000/s->total);hw_text("\n");
    }
    hw_select(0);
    field("SPADM1,PASS,measured_records=",2*3*MICRO_SAMPLES);
    field(",warmup_records=",2*3*MICRO_WARMUPS);
    hw_text(",full_spad_bit_exact=1,source_unchanged=1,guards=1,group_cost=included\n");
#ifndef MICRO_HOST_TEST
    for(;;)__asm__ volatile("wfi");
#endif
    return 0;
}
