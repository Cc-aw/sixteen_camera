#!/usr/bin/env python3
"""Build native FIFO16/frontend/Gemmini/ASRAM replay from one selected output."""
import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'scripts'))
from common import selected_output, sha
from rtl_support import module_closure
from wrapper import wrapper


def adapt_primitive(source,target,minimum):
    original=source.read_text()
    adapted,n=re.subn(r'\bspecify\b.*?\bendspecify\b','',original,flags=re.S)
    if n!=1:raise ValueError('Unexpected vendor specify blocks')
    adapted,n=re.subn(r"\(([A-Za-z0-9_]+(?:\[\d+\])?) (===|!==) 1'bz\)",
        lambda m:"(1'b0)" if m[2]=='===' else "(1'b1)",adapted)
    if n<minimum:raise ValueError('Unexpected vendor Z checks')
    target.write_text(adapted.replace('tri0 glblGSR','wire glblGSR'))


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--generated',type=Path,required=True)
    parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--jobs',type=int,default=6)
    parser.add_argument('--asram-store',choices=('behavioral','vendor'),default='behavioral')
    args=parser.parse_args();out=args.output.resolve()
    if ROOT/'build' not in out.parents:raise ValueError('Use a new output below this hardware build/')
    out.mkdir(parents=True,exist_ok=False)
    generated,context=selected_output(args.generated);rtl=generated/'gen-collateral'
    sources=module_closure(rtl,['Gemmini','CommandFrontendEngine','CommandFrontendMemoryMux','ActivationSramTL'])
    configured=shutil.which(os.environ.get('VIVADO_BIN','vivado'))
    if not configured:raise ValueError('Set VIVADO_BIN')
    vendor=Path(configured).resolve().parents[1]/'data/verilog/src'
    snapshots=out/'tool_sources';snapshots.mkdir()
    for name in ('build_native.py','wrapper.py','driver.cpp'):
        shutil.copyfile(Path(__file__).with_name(name),snapshots/name)
    for name in ('common.py','rtl_support.py'):
        shutil.copyfile(ROOT/'scripts'/name,snapshots/name)
    text=wrapper(rtl,observation='')
    text=text.replace('output wire gem_busy',
        'output wire [15:0] rs_idle,output wire [31:0] scale_tasks,logical_read_bytes,path_switch_cycles,completion_wait_cycles,output wire bank_write_wait,output wire gem_busy')
    probe='''
assign scale_tasks=32'(dut.spad.vsm.pipe.io_in_valid)+32'(dut.spad.vsm.pipe_1.io_in_valid)+
    32'(dut.spad.vsm.pipe_2.io_in_valid)+32'(dut.spad.vsm.pipe_3.io_in_valid);
assign rs_idle=dut.reservation_station.cycles_since_issue;
assign logical_read_bytes=dut.spad.io_counter_external_values_9;
assign path_switch_cycles=dut.spad.io_counter_external_values_27;
assign completion_wait_cycles=dut.spad.io_counter_external_values_30;
assign bank_write_wait=dut.spad.mvinWriteBuffer.io_deq_valid && !dut.spad.mvinWriteBuffer.io_deq_ready;
'''
    text=text.removesuffix('endmodule\n')+probe+'\nendmodule\n'
    top=out/'S1TeamReplay.sv';top.write_text(text)
    primitives=[]
    originals=[]
    for name,minimum in (('RAMB36E2',100),('URAM288_BASE',32)):
        source=vendor/'unisims'/(name+'.v');target=out/(name+'_functional.v')
        adapt_primitive(source,target,minimum);primitives.append(target);originals.append(source)
    driver=snapshots/'driver.cpp'
    command=[os.environ.get('VERILATOR','verilator'),'--cc','--exe','--build','--assert','--timing',
        '-Wno-fatal','--top-module','S1TeamReplay','--Mdir',str(out/'obj'),'-j',str(args.jobs),
        '--output-split','20000','--output-split-cfuncs','2000','-CFLAGS','-O2 -std=c++17',
        str(top),*map(str,sources+primitives+[vendor/'glbl.v']),str(driver)]
    if args.asram_store=='behavioral':command.insert(1,'-DASRAM_BEHAVIORAL')
    (out/'compile_command.json').write_text(json.dumps(command,indent=2)+'\n')
    with (out/'compile.log').open('w') as log:
        subprocess.run(command,stdout=log,stderr=subprocess.STDOUT,check=True)
    paths=[generated/'GENERATION_CONTEXT.json',top,*originals,*sources,*primitives,
           vendor/'glbl.v',*sorted(snapshots.iterdir())]
    manifest=dict(status='PASS',hardware_build_id=context['dma_load_build_id'],
        generated_output=str(generated),native_rtl=['Gemmini','CommandFrontendEngine','CommandFrontendMemoryMux','ActivationSramTL'],
        asram_store=args.asram_store,experimental_rtl_overlays=False,
        observations='Read-only scale grants and existing DMA counters; no hardware event numbers changed',
        vendor_adaptation='specify removed; connected-input Z checks constant; glblGSR tri0 to wire',
        shared_l2_cpu_rvv_video=False,full_system_timing=False,
        sha256={str(p):sha(p) for p in paths},executable_sha256=sha(out/'obj/VS1TeamReplay'))
    (out/'build_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print('S1_TEAM_NATIVE_BUILT',context['dma_load_build_id'],out)


if __name__=='__main__':main()
