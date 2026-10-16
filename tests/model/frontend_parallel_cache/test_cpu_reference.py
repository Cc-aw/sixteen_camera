#!/usr/bin/env python3
"""Check the RTL oracle against the frozen native CPU convolution and rounding."""
import json
import os
from pathlib import Path
import struct
import subprocess
import sys
PROJECT=Path(__file__).resolve().parents[3]
sys.path.insert(0,str(PROJECT/'sw/benchmarks/frontend/scripts'))
from parallel_cache_plan import function,sha,save
OUT=Path(os.environ.get('FRONTEND_BUILD',PROJECT/'build/firmware/sw-p3'))
SIM=PROJECT/'build/sim/sw_p3_tiling_compact'


def main():
    snap=OUT/'native';desc=json.loads((OUT/'generated/plan_description.json').read_text())
    s=next(s for s in desc['stages'] if s['stage_id']==18)['shape']
    header=(snap/'include/gemmini.h').read_text()
    scale=struct.unpack('<e',struct.pack('<H',s['scale_bits']))[0]
    code='''#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#define IGELU 2
#define RELU 1
'''
    code+=f'#include "{snap}/include/gemmini_params.h"\n'
    code+=function(header,'static elem_t scale_and_sat(')+'\n'
    code+=function(header,'static void conv_cpu_without_pool(')+'\n'
    code+='static elem_t inputs[307200],weights[2048],outputs[153600];\nstatic acc_t bias[32];\n'
    code+='int main(void){\n'
    for d in range(3):
        code+=f'''for(int i=0;i<307200;i++)inputs[i]=(i*13+i/64*7+{d}*11)%31-15;
for(int i=0;i<2048;i++)weights[i]=(i*7+i/32*3)%15-7;
for(int i=0;i<32;i++)bias[i]=i*13-200;
conv_cpu_without_pool(1,60,80,64,32,60,80,1,1,1,0,1,64,32,32,false,false,false,false,false,inputs,weights,bias,outputs,0,{float(scale).hex()}f);
FILE *gold{d}=fopen("{SIM}/gold{d}.hex","r");assert(gold{d});
for(int i=0;i<153600;i++){{unsigned expected;assert(fscanf(gold{d},"%x",&expected)==1);assert((uint8_t)(outputs[i]/2)==expected);}}
fclose(gold{d});
'''
    code+='puts("NATIVE_CPU_REFERENCE_PASS stage18 lanes=3 output_bytes=460800");return 0;}\n'
    src=OUT/'native_cpu_reference.c';src.write_text(code);exe=OUT/'native_cpu_reference'
    subprocess.run(['cc','-O2','-std=gnu11','-Wall','-Wextra','-Werror','-Wno-unused-parameter',str(src),'-lm','-o',str(exe)],check=True)
    result=subprocess.run([str(exe)],check=True,capture_output=True,text=True)
    log=OUT/'native_cpu_reference.log';log.write_text(result.stdout);print(result.stdout,end='')
    save(OUT/'native_cpu_reference.json',dict(status='FUNCTIONAL_PASS',stage_id=18,lanes=3,output_bytes=460800,
        checker_sha256=sha(Path(__file__).read_bytes()),native_header_sha256=sha((snap/'include/gemmini.h').read_bytes()),
        log_sha256=sha(log.read_bytes())))

if __name__=='__main__':main()
