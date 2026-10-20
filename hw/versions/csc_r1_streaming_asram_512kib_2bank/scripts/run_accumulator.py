#!/usr/bin/env python3
"""Observe every physical Accumulator byte at native fences in real C1a RTL.

Relinks an observational driver only. The compiled RTL archive is unchanged.
The four actual 512-row, 1024-bit RAM arrays are read after real completion.
"""
import argparse
import json
from pathlib import Path
import shutil
import subprocess
import sys

from candidate_rtl import once, sha


def run(build, commands, memory, output, lanes, enabled, mode, frames, last_stage):
    manifest=json.loads((build/'build_manifest.json').read_text())
    for name,digest in manifest['sha256'].items():
        if sha(Path(name))!=digest: raise ValueError('Build input changed: '+name)
    obj=build/'obj'
    root_header=obj/'VFullGemmini___024root.h'
    acc_header=obj/'VFullGemmini_AccumulatorMem.h'
    banks=[f'__PVT__FullGemmini__DOT__dut__DOT__spad__DOT__acc_mems_{b}' for b in range(4)]
    cell='__PVT__mem__DOT__mem__DOT__mem_0_ext__DOT__ram'
    for bank in banks:
        if f'VFullGemmini_AccumulatorMem* {bank};' not in root_header.read_text():
            raise ValueError('Accumulator instance layout changed')
    if 'VlUnpacked<VlWide<32>/*1023:0*/, 512> '+cell+';' not in acc_header.read_text():
        raise ValueError('Actual Accumulator RAM layout changed')
    output.mkdir(parents=True,exist_ok=False)
    source=(build/'csc_gemmini_driver.cpp').read_text()
    source=once(source,'#include "VFullGemmini.h"', '''#include "VFullGemmini.h"
#include "VFullGemmini___024root.h"
#include "VFullGemmini_AccumulatorMem.h"''')
    source=once(source,'VFullGemmini rtl;Memory memory;', 'VFullGemmini rtl;std::ofstream accumulator;Memory memory;')
    source=once(source,'static void wide(', '''static void snapshot_accumulator(Lane &s,unsigned frame,unsigned stage) {
    const uint32_t header[3]={frame,stage,255};
    s.accumulator.write(reinterpret_cast<const char*>(header),sizeof(header));
    const std::array<VFullGemmini_AccumulatorMem*,4> banks={'''+','.join('s.rtl.rootp->'+b for b in banks)+'''};
    for(auto *bank:banks)for(unsigned r=0;r<512;++r)
        s.accumulator.write(reinterpret_cast<const char*>(bank->'''+cell+'''[r].data()),32*sizeof(uint32_t));
    if(!s.accumulator)throw std::runtime_error("Accumulator snapshot write failed");
}
static void wide(''')
    source=once(source, 'if(!state[i]->trace)throw std::runtime_error("Trace open failed");', '''if(!state[i]->trace)throw std::runtime_error("Trace open failed");
        state[i]->accumulator.open(std::filesystem::path(argv[3])/"accumulator.bin",std::ios::binary);
        if(!state[i]->accumulator)throw std::runtime_error("Accumulator snapshot open failed");''')
    source=once(source,'if(c.funct==253){flush_metrics(s,i,cycle);s.metric_live=true;}',
                'if(c.funct==255)snapshot_accumulator(s,c.frame,c.stage);\n                        if(c.funct==253){flush_metrics(s,i,cycle);s.metric_live=true;}')
    source=once(source,'s.finished=true;gzclose(s.trace);', 's.finished=true;gzclose(s.trace);s.accumulator.close();')
    replacements={
        'unsigned lanes=std::stoul(argv[4])':'unsigned lane_offset=std::stoul(argv[9]); unsigned lanes=std::stoul(argv[4])',
        'if(lane<lanes && command.frame<frames && command.stage<=last_stage)state[lane]':
            'if(lane>=lane_offset && lane<lane_offset+lanes && command.frame<frames && command.stage<=last_stage)state[lane-lane_offset]',
        'std::to_string(i)':'std::to_string(i+lane_offset)',
        'cycle%11!=i;':'cycle%11!=i+lane_offset;',
        'cycle,i,s.frame':'cycle,i+lane_offset,s.frame',
        '<<i<<':'<<i+lane_offset<<',
        'flush_metrics(s,i,':'flush_metrics(s,i+lane_offset,',
    }
    for old,new in replacements.items():
        if old not in source: raise ValueError('Driver adapter changed: '+old)
        source=source.replace(old,new)
    driver=output/'accumulator_driver.cpp'
    driver.write_text(source)
    prefix=Path(sys.executable).resolve().parents[1]
    compiler=shutil.which('x86_64-conda-linux-gnu-c++') or shutil.which('g++')
    objects=[obj/'VFullGemmini__ALL.a',obj/'verilated.o',obj/'verilated_timing.o',obj/'verilated_threads.o']
    executable=output/'VFullGemminiAccumulator'
    compile_command=[compiler,'-O2','-std=c++17','-fcoroutines','-I'+str(obj),
        '-I'+str(prefix/'share/verilator/include'),'-I'+str(prefix/'share/verilator/include/vltstd'),
        '-I'+str(prefix/'include'),str(driver),*map(str,objects),'-L'+str(prefix/'lib'),
        '-Wl,-rpath,'+str(prefix/'lib'),'-lz','-pthread','-latomic','-o',str(executable)]
    subprocess.run(compile_command,check=True)
    sources=[Path(__file__).resolve(),driver,executable,commands,build/'build_manifest.json',
             root_header,acc_header,obj/'VFullGemmini.h',*objects]
    sources+=sorted(memory.iterdir()) if memory.is_dir() else [memory]
    expected={lane:0 for lane in lanes}
    for line in commands.read_text().splitlines():
        lane,frame,stage,funct,*_=map(int,line.split())
        if lane in expected and frame<frames and stage<=last_stage and funct==255:
            expected[lane]+=1
    execution=dict(schema=1,csc_enabled=bool(enabled),mode=mode,lanes=lanes,frames=frames,
        full_system_performance_model=False,all_rtl_assertions_enabled=True,
        accumulator_bytes_per_snapshot=262144,snapshot_boundary='Native completed fence',
        expected_snapshots=expected,compile_command=compile_command,
        sha256={str(p):sha(p) for p in sources})
    (output/'execution_manifest.json').write_text(json.dumps(execution,indent=2)+'\n')
    running=[]
    for lane in lanes:
        log=(output/f'lane{lane}.log').open('w')
        command=[str(executable),str(commands),str(memory),str(output/f'lane{lane}'),'1',str(frames),
            str(last_stage),str(enabled),str(mode),str(lane),'+gemmini_timeout=60000']
        running.append((lane,subprocess.Popen(command,stdout=log,stderr=subprocess.STDOUT),log,command))
    results=[]
    for lane,process,log,command in running:
        code=process.wait();log.close()
        path=output/f'lane{lane}/accumulator.bin'
        size=path.stat().st_size if path.is_file() else -1
        results.append(dict(lane=lane,returncode=code,command=command,
            snapshots=size//262156,bytes=size,complete=size==expected[lane]*262156 and expected[lane]>0))
    for name,digest in execution['sha256'].items():
        if sha(Path(name))!=digest: raise ValueError('Snapshot test input changed: '+name)
    passed=all(r['returncode']==0 and r['complete'] for r in results)
    (output/'execution_result.json').write_text(json.dumps(dict(status='PASS' if passed else 'FAIL',lanes=results),indent=2)+'\n')
    if not passed: raise RuntimeError('Accumulator run failed: '+str(results))
    print('CSC_ACCUMULATOR_SNAPSHOTS_PASS',lanes,'enabled',enabled)


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    for name in ('build','commands','memory','output'): parser.add_argument('--'+name,type=Path,required=True)
    parser.add_argument('--lanes',default='0,1,2')
    parser.add_argument('--enabled',type=int,choices=(0,1),required=True)
    parser.add_argument('--mode',type=int,choices=(0,1,2,3),default=2)
    parser.add_argument('--frames',type=int,choices=(1,2,3),default=3)
    parser.add_argument('--last-stage',type=int,default=165)
    args=parser.parse_args()
    lanes=list(map(int,args.lanes.split(',')))
    if not lanes or len(set(lanes))!=len(lanes) or any(lane not in range(3) for lane in lanes): parser.error('invalid lanes')
    run(args.build.resolve(),args.commands.resolve(),args.memory.resolve(),args.output.resolve(),
        lanes,args.enabled,args.mode,args.frames,args.last_stage)
