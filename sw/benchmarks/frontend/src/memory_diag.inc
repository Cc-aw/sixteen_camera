/* All existing MPV3 blocks/slots are retained raw. Selector reads happen only
 * after the workload, never between HOST and RESUME in the primary 12-frame
 * comparison. Dedicated matched three-frame passes isolate each boundary. */
#define MEMORY_BASE UINT64_C(0x02020000)
static void direct(const GfCommand *c);
static void prepare_batch(void);
static void parallel_batch(unsigned active_lanes);
volatile unsigned memory_probe_active,memory_probe_failed;
static unsigned memory_available,memory_blocks,memory_window_id,memory_open,memory_stopped;
static unsigned memory_target,memory_kind,memory_lane_map[3];
static uint64_t memory_abi,memory_soc_hz,memory_ddr_hz,memory_begin_cycle,memory_end_cycle;
static uint64_t memory_setup_cycles,memory_stop_cycles,memory_snapshot_cycles,memory_read_cycles;
static uint32_t memory_sequence;
static uint64_t memory_values[16][32];
static uint64_t memory_start_cursor[3],memory_end_cursor[3];
static unsigned memory_start_state[3],memory_end_state[3];
struct MemoryFrame {
    uint64_t config_begin,config_end,capture_begin,capture_end;
    uint32_t value[6];
};
static struct MemoryFrame memory_frames[FRAMES];
static uint32_t memory_counter_access(unsigned lane,uint32_t config) {
    uint64_t out;
#define COUNTER_ROUTE(op) __asm__ volatile(".insn r " op ", 7, 126, %0, %1, x0" : "=&r"(out):"r"((uint64_t)config):"memory")
    switch(lane) {
        case 0:COUNTER_ROUTE("0x0b");break;
        case 1:COUNTER_ROUTE("0x2b");break;
        case 2:COUNTER_ROUTE("0x5b");break;
        default:at_fail("counter_lane",lane);
    }
#undef COUNTER_ROUTE
    return (uint32_t)out;
}
static void memory_counter_begin(unsigned f,unsigned lane) {
    /* Only issue legacy counter commands before ownership and after ACK.
     * HOST_WAIT still owns the lane and cannot accept direct counter reads. */
    if(gf_status(lane)&GF_OWNED)at_fail("counter_on_owned_lane",lane);
    struct MemoryFrame *m=&memory_frames[f];m->config_begin=clock_cycle();
    const unsigned events[6]={42,8,10,24,11,14};
    (void)memory_counter_access(lane,1);
    for(unsigned i=0;i<6;i++)(void)memory_counter_access(lane,(i<<4)|8|(events[i]<<12));
    m->config_end=clock_cycle();
}
static void memory_counter_end(unsigned f,unsigned lane) {
    if(gf_status(lane)&GF_OWNED)at_fail("counter_on_owned_lane",lane);
    struct MemoryFrame *m=&memory_frames[f];m->capture_begin=clock_cycle();
    (void)memory_counter_access(lane,4);
    for(unsigned i=0;i<6;i++)m->value[i]=memory_counter_access(lane,i<<4);
    m->capture_end=clock_cycle();
}
static void memory_counter_report(unsigned mode,unsigned pass,unsigned count) {
    for(unsigned f=0;f<count;f++) {
        const struct Frame *t=&frames[f];const struct MemoryFrame *m=&memory_frames[f];
        text("ATSOFT1,GEM_COUNTER,executor=");text(executor_name(mode));
        field(",pass=",pass);field(",frame=",f);field(",device=",t->device);field(",image=",t->image);
        field(",valid=",m->value[0]!=0&&m->value[3]!=0);
        field(",config_cycles=",m->config_end-m->config_begin);
        field(",capture_cycles=",m->capture_end-m->capture_begin);
        const char *keys[6]={",rs_active=",",load_dma_wait=",",load_spad_wait=",",exec_active=",",store_dma_wait=",",store_spad_wait="};
        for(unsigned i=0;i<6;i++)field(keys[i],m->value[i]);
        text("\n");
    }
}
static uint64_t memory_read64(unsigned off) {
    uint32_t lo=mmio_read32(MEMORY_BASE+off),hi=mmio_read32(MEMORY_BASE+off+4);
    return lo|((uint64_t)hi<<32);
}
static __attribute__((noinline)) uint32_t memory_safe_probe(unsigned off) {
    uint32_t value;memory_probe_active=1;
    /* boundary_irq.c recovers only this guarded, fixed-width load on an
     * unmapped MPV3 window. Ordinary access faults remain fatal. */
    __asm__ volatile(".option push\n.option norvc\nlw %0,0(%1)\n.option pop"
        :"=&r"(value):"r"(MEMORY_BASE+off):"memory");
    memory_probe_active=0;return value;
}
static uint64_t memory_diag_wait(void) {
    uint64_t begin=clock_cycle(),s;
    do {
        s=memory_read64(0x10);
        if(!(s&8)||(s&16))at_fail("memory_external_reset_or_invalid_command",s);
        if(clock_cycle()-begin>10000000)at_fail("memory_command_timeout",s);
    }while(s&1);
    return s;
}
static uint64_t memory_command(unsigned value) {
    (void)memory_diag_wait();mmio_write32(MEMORY_BASE+8,value);return memory_diag_wait();
}
static void memory_init(void) {
    uint64_t lo=memory_safe_probe(0),hi=memory_probe_failed?0:memory_safe_probe(4);
    memory_abi=lo|(hi<<32);memory_blocks=0;
    for(unsigned d=0;d<3;d++)memory_lane_map[d]=UINT32_MAX;
    unsigned known_abi=memory_abi==UINT64_C(0x4d50563300010000)||memory_abi==UINT64_C(0x4d50563300010001)||memory_abi==UINT64_C(0x4d50563300010002);
    if(!memory_probe_failed&&known_abi)memory_blocks=memory_read64(0x50);
    uint64_t status=memory_probe_failed||!known_abi?0:memory_read64(0x10);
    memory_available=!memory_probe_failed&&
        ((memory_abi==UINT64_C(0x4d50563300010000)&&memory_blocks==13)||
         (memory_abi==UINT64_C(0x4d50563300010001)&&(memory_blocks==14||memory_blocks==16))||
         (memory_abi==UINT64_C(0x4d50563300010002)&&memory_blocks==16))&&
        (status&8)&&!(status&17);
    if(memory_available) {
        memory_soc_hz=memory_read64(0x40);memory_ddr_hz=memory_read64(0x48);
        unsigned banks=memory_abi==UINT64_C(0x4d50563300010002)?4:2;
        if(memory_read64(0x58)!=banks||memory_read64(0x60)!=512||memory_read64(0x68)!=32||
           memory_soc_hz!=100000000||memory_ddr_hz!=300000000)
            at_fail("memory_unsupported_geometry",memory_abi);
        if(status&2)(void)memory_command(2);
    }
    text("ATSOFT1,MEM_DEVICE,available=");number(memory_available);
    field(",probe_fault=",memory_probe_failed);field(",abi=",memory_abi);field(",blocks=",memory_blocks);
    field(",status=",status);
    field(",soc_hz=",memory_soc_hz);field(",ddr_hz=",memory_ddr_hz);
    text(",base=33685504,slots=32,mapping=calibrated_when_available\n");
}
static void memory_start(void) {
    uint64_t begin=clock_cycle();
    if(!memory_available||memory_open)at_fail("memory_start_state",memory_open);
    if(memory_command(3)&6)at_fail("memory_clear",0);
    memory_sequence=(uint32_t)memory_read64(0x18);
    if(!(memory_command(1)&2))at_fail("memory_start",0);
    for(unsigned d=0;d<3;d++){
        memory_start_cursor[d]=gf_read(d,2,0);memory_start_state[d]=gf_read(d,4,0);
    }
    memory_begin_cycle=clock_cycle();memory_setup_cycles=memory_begin_cycle-begin;
    memory_open=1;memory_stopped=0;memory_stop_cycles=0;memory_window_id++;
}
static void memory_stop(void) {
    if(!memory_open||memory_stopped)at_fail("memory_stop_state",0);
    memory_end_cycle=clock_cycle();
    if(memory_command(2)&2)at_fail("memory_stop",0);
    for(unsigned d=0;d<3;d++){
        memory_end_cursor[d]=gf_read(d,2,0);memory_end_state[d]=gf_read(d,4,0);
    }
    memory_stop_cycles=clock_cycle()-memory_end_cycle;memory_stopped=1;
}
static void memory_boundary_begin(unsigned f,unsigned tag) {
    if(memory_available&&short_window_pass&&f==0&&tag==memory_target&&!memory_open)memory_start();
}
static void memory_boundary_end(unsigned f,unsigned tag) {
    if(memory_available&&short_window_pass&&f==0&&tag==memory_target&&memory_open&&!memory_stopped)memory_stop();
}
static void memory_whole_begin(unsigned mode) {
    (void)mode;memory_kind=1;memory_target=0;if(memory_available)memory_start();
}
static void memory_finish(unsigned mode,unsigned pass,uint64_t batch_cycles) {
    if(!memory_available)return;
    if(!memory_open)at_fail("memory_missing_window",memory_target);
    if(!memory_stopped) {
        if(short_window_pass)at_fail("memory_missing_window_end",memory_target);
        memory_stop();
    }
    uint64_t begin=clock_cycle(),s=memory_command(4);
    uint32_t sequence=(uint32_t)memory_read64(0x18);
    if(!(s&4)||(s&2)||sequence!=(uint32_t)(memory_sequence+1))at_fail("memory_snapshot",s);
    memory_snapshot_cycles=clock_cycle()-begin;begin=clock_cycle();
    for(unsigned block=0;block<memory_blocks;block++)for(unsigned slot=0;slot<32;slot++) {
        unsigned select=block*32+slot;mmio_write32(MEMORY_BASE+0x20,select);
        if(mmio_read32(MEMORY_BASE+0x20)!=select)at_fail("memory_selector",select);
        memory_values[block][slot]=memory_read64(0x28);
    }
    memory_read_cycles=clock_cycle()-begin;
    if((memory_diag_wait()&7)!=4||(uint32_t)memory_read64(0x18)!=sequence)at_fail("memory_snapshot_changed",sequence);
    text("ATSOFT1,MEM_WINDOW,executor=");text(executor_name(mode));
    field(",id=",memory_window_id);field(",pass=",pass);field(",kind=",memory_kind);
    field(",target_tag=",memory_target);field(",sequence=",sequence);field(",blocks=",memory_blocks);
    field(",cpu_span_cycles=",memory_end_cycle-memory_begin_cycle);field(",batch_cycles=",batch_cycles);
    field(",cpu_begin_cycles=",memory_begin_cycle);field(",cpu_end_cycles=",memory_end_cycle);
    field(",setup_cycles=",memory_setup_cycles);field(",stop_cycles=",memory_stop_cycles);
    field(",snapshot_cycles=",memory_snapshot_cycles);field(",read_cycles=",memory_read_cycles);
    for(unsigned d=0;d<3;d++){
        char sc[]={',','s','t','a','r','t','_','c','u','r','s','o','r',(char)('0'+d),'=',0};
        char ec[]={',','e','n','d','_','c','u','r','s','o','r',(char)('0'+d),'=',0};
        char ss[]={',','s','t','a','r','t','_','s','t','a','t','e',(char)('0'+d),'=',0};
        char es[]={',','e','n','d','_','s','t','a','t','e',(char)('0'+d),'=',0};
        field(sc,memory_start_cursor[d]);field(ec,memory_end_cursor[d]);
        field(ss,memory_start_state[d]);field(es,memory_end_state[d]);
    }
    text("\n");
    for(unsigned block=0;block<memory_blocks;block++) {
        text("ATSOFT1,MEM_BLOCK,id=");number(memory_window_id);field(",block=",block);
        field(",clock_hz=",block>=9&&block<=11?memory_ddr_hz:
            (block<=12||memory_abi==UINT64_C(0x4d50563300010002)||(memory_blocks==14&&block==13))?memory_soc_hz:0);
        for(unsigned slot=0;slot<32;slot++) {
            char key[]={',','c',(char)('0'+slot/10),(char)('0'+slot%10),'=',0};field(key,memory_values[block][slot]);
        }
        text("\n");
    }
    text("ATSOFT1,MEM_END,id=");number(memory_window_id);text(",valid=1\n");memory_open=0;
}
static void memory_calibrate(void) {
    if(!memory_available)return;
    /* A native first-convolution prefix performs real DDR reads on just one
     * idle lane. Learn the client block instead of reusing v32's opcode map. */
    for(unsigned d=0;d<3;d++) {
        current_lane=d;current_frame=0;struct Plan *p=&plans[d][0][0];unsigned worked=0,drained=0;
        memory_kind=0;memory_target=d;memory_start();uint64_t begin=clock_cycle();
        for(unsigned i=0;i<p->count;i++) {
            const GfCommand *c=&p->commands[i];unsigned kind=c->control&255;
            if(kind==GF_RAW){direct(c);unsigned funct=c->control>>8;worked|=funct==2||funct==8||funct==15;}
            else if(kind==GF_DRAIN){gf_publish();if(worked){drained=1;break;}}
            else at_fail("memory_calibration_prefix",d);
        }
        if(!drained)at_fail("memory_calibration_empty",d);
        memory_stop();memory_finish(0,0,clock_cycle()-begin);
        unsigned found=0;
        for(unsigned block=0;block<3;block++)if(memory_values[block][1]&&memory_values[block][4]){found++;memory_lane_map[d]=block;}
        if(found!=1)memory_lane_map[d]=UINT32_MAX;
    }
    unsigned valid=memory_lane_map[0]<3&&memory_lane_map[1]<3&&memory_lane_map[2]<3&&
        memory_lane_map[0]!=memory_lane_map[1]&&memory_lane_map[0]!=memory_lane_map[2]&&memory_lane_map[1]!=memory_lane_map[2];
    text("ATSOFT1,MEM_MAPPING,valid=");number(valid);
    for(unsigned d=0;d<3;d++){char key[]={',','l','a','n','e',(char)('0'+d),'=',0};field(key,memory_lane_map[d]);}text("\n");
}
static void memory_short_passes(void) {
    if(!memory_available)return;
    for(unsigned tag=1;tag<=13;tag++)for(unsigned mode=1;mode<=2;mode++) {
        executor=mode;short_window_pass=(tag-1)*2+mode;run_frames=3;memory_kind=2;memory_target=tag;
        prepare_batch();batch_begin=clock_cycle();parallel_batch(mode==1?1:3);
        uint64_t cycles=clock_cycle()-batch_begin;
        if(completed!=3||host_calls!=36||launches!=3)at_fail("memory_pair_incomplete",short_window_pass);
        unsigned mismatch=0;
        for(unsigned f=0;f<3;f++) {
            if(use[frames[f].device]!=(mode==1?3:1))at_fail("memory_pair_quota",f);
            mismatch+=output[mode][f].count!=output[0][f].count;
            for(unsigned i=0;i<10;i++)for(unsigned j=0;j<4;j++)mismatch+=output[mode][f].words[i][j]!=output[0][f].words[i][j];
        }
        if(mismatch)at_fail("memory_pair_ppu_mismatch",mismatch);
        memory_finish(mode,short_window_pass,cycles);memory_counter_report(mode,short_window_pass,3);
        text("ATSOFT1,MEM_PAIR,executor=");text(executor_name(mode));field(",pass=",short_window_pass);
        field(",target_tag=",tag);field(",target_frame=",0);field(",target_lane=",0);field(",image=",0);
        field(",frames=",3);field(",cycles=",cycles);text(",ppu_results=bit_exact\n");
    }
    short_window_pass=0;run_frames=FRAMES;
}
