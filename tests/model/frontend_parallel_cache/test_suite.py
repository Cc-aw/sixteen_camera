#!/usr/bin/env python3
"""Execute the actual finite suite with the actual dispatcher and fake devices."""
import ast
import os
from pathlib import Path
import re
import subprocess
import sys
PROJECT=Path(__file__).resolve().parents[3]
ROOT=PROJECT/'sw/benchmarks/frontend'
OUT=Path(os.environ.get('FRONTEND_BUILD',PROJECT/'build/firmware/sw-p3'))
sys.path.insert(0,str(ROOT/'scripts'))
from parallel_cache_plan import function
from analyze_parallel_cache import parse


def main():
    tree=ast.parse((PROJECT/'tests/model/frontend_v33/test_dispatch.py').read_text())
    harness=next(ast.literal_eval(n.value) for n in tree.body if isinstance(n,ast.Assign) and n.targets[0].id=='harness')
    source=(OUT/'generated/sw_p3_main.c').read_text()
    harness=harness.replace('@FRAME_CONSTANTS@',re.search(r'enum \{ FRAMES=.*?\};',source)[0])
    a=harness.index('static void text(');b=harness.index('static void at_fail(',a)
    harness=harness[:a]+'''static void text(const char *s){fputs(s,stdout);}
static void number(uint64_t n){printf("%llu",(unsigned long long)n);}
static void field(const char *s,uint64_t n){text(s);number(n);}
'''+harness[b:]
    harness=harness.replace('static unsigned seed,','''static uint64_t irq_count,irq_cycles;
static unsigned sw_p3_run_id,sw_p3_serial_lane,sw_p3_matched,sw_p3_replay_lane[FRAMES],sw_p3_tiling_enabled;
static unsigned sw_p3_serial_device(unsigned);
#include "parallel_cache_gate.inc"
static unsigned seed,''')
    harness=harness.replace('assert(d<active_lanes&&run==executor*FRAMES+current_frame+1);','assert(run==sw_p3_run_id);')
    harness=harness.replace('assert(d<active_lanes&&irq&&','assert((active_lanes==3||d==sw_p3_serial_device(bound[d]))&&irq&&')
    harness=harness.replace('slot_live[d][frames[f].slot]=0;', 'if(getenv("CORRUPT_WORD")&&sw_p3_run_id>12)ppu_result[d].words[9][3]=1;slot_live[d][frames[f].slot]=0;')
    harness=harness.replace('ticks<10000000','ticks<100000000')
    functions='\n'.join(function(source,s) for s in ('static void execute_host(', 'static void admit(',
        'static void graph_done(', 'static void finish(', 'static unsigned sw_p3_serial_busy(', 'static void parallel_batch(', 'static void prepare_batch('))
    functions=re.sub(r'__asm__ volatile\(.*?\);','((void)0);',functions,flags=re.S)
    functions=functions.replace('static void parallel_batch(unsigned active_lanes) {','static void parallel_batch(unsigned requested) {\n    active_lanes=requested;\n    unsigned active_lanes=requested;')
    stubs=r'''
static void sw_p3_tensor_fill(unsigned char value){(void)value;}
static void sw_p3_set_layout(unsigned profile){(void)profile;}
static void sw_p3_guards_check(void){}
static void ppu_init(void){}
static void prepare_model(void){
 for(unsigned d=0;d<3;d++)for(unsigned s=0;s<2;s++)for(unsigned i=0;i<3;i++){
  struct Plan *p=&plans[d][s][i];p->count=26;p->raw=14;p->host_count=12;
  for(unsigned h=0;h<12;h++)p->hosts[h]=(struct Host){.kind=h<6?HOST_PAD:HOST_HEAD,.head=h%6};
 }
}
'''
    serial=r'''
static void serial_batch(void){
 active_lanes=1;
 for(unsigned f=0;f<FRAMES;f++){
  admit(f,0);for(unsigned tag=1;tag<=12;tag++)execute_host(f,tag);
  graph_done(f);while(!ppu_done[0])ppu_service();finish(f);
 }
}
'''
    suite=(ROOT/'src/parallel_cache_suite.inc').read_text().split('#else\n#include "sw_p3_identity.inc"',1)[1].rsplit('#endif',1)[0]
    suite='#include "parallel_cache_config.h"\n#include "sw_p3_identity.inc"\n'+suite
    suite=suite.replace('    for(;;)__asm__ volatile("wfi");','')
    src=OUT/'sw_p3_suite_test.c';src.write_text(harness+stubs+functions+serial+suite+'\nint main(void){if(setjmp(failed)){fprintf(stderr,"%s\\n",reason);return 1;}return sw_p3_suite();}\n')
    exe=OUT/'sw_p3_suite_test'
    for compare in (0,1):
        subprocess.run(['cc','-std=gnu11','-O1','-g','-DYOLO32_FRONTEND_DIAG=0',
            f'-DSW_P3_COMPARE={compare}','-fsanitize=address,undefined',
            '-I'+str(ROOT/'include'),'-I'+str(ROOT/'src'),'-I'+str(OUT/'generated'),str(src),'-o',str(exe)],check=True)
        result=subprocess.run([str(exe)],check=True,capture_output=True,text=True,env=dict(os.environ,ASAN_OPTIONS='detect_leaks=0'))
        log=OUT/f'fake_suite_uart_compare{compare}.log';log.write_text(result.stdout)
        parsed=parse(result.stdout)
        assert parsed['runs']==(48 if compare else 12) and parsed['frames']==(576 if compare else 144)
        if not compare:
            assert 'name=layout' not in result.stdout and 'gate_peak=3' not in result.stdout
        corrupted=subprocess.run([str(exe)],capture_output=True,text=True,env=dict(os.environ,ASAN_OPTIONS='detect_leaks=0',CORRUPT_WORD='1'))
        assert corrupted.returncode==1 and 'sw_p3_full40_result_mismatch' in corrupted.stderr
    print('SW_P3_SUITE_PROTOCOL=PASS default=reference frames=144 compare_frames=576 matched_replay=1 result40=checked hardware_arithmetic=0')

if __name__=='__main__':main()
