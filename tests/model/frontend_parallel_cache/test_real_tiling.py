#!/usr/bin/env python3
"""Execute a shortlisted FULL stage18 candidate on three real DIM32 Gemminis.

Uses the existing production RTL/Xilinx primitive test rig, in a separate build
folder. Only simulation memory sizes, tables, vectors and timeouts are changed.
No generated production RTL or existing regression source is edited.
"""
import json
import os
from pathlib import Path
import re
import struct
import subprocess
import sys
import numpy as np
PROJECT=Path(__file__).resolve().parents[3]
ROOT=PROJECT/'sw/benchmarks/frontend'
sys.path.insert(0,str(ROOT/'scripts'))
from parallel_cache_plan import sha,save
OUT=Path(os.environ.get('FRONTEND_BUILD',PROJECT/'build/firmware/sw-p3'))
GEN=OUT/'generated'
SIM=PROJECT/'build/sim/sw_p3_tiling_compact'
SIM.mkdir(parents=True,exist_ok=True)


def main():
    evidence_path=OUT/'tiling_numerical_evidence.json'
    if '--reuse' in sys.argv and evidence_path.exists():
        e=json.loads(evidence_path.read_text())
        if (e.get('status')=='FUNCTIONAL_PASS' and e['checker_sha256']==sha(Path(__file__).read_bytes()) and
            e['hardware_files_sha256']==sha((PROJECT/'hw/manifests/current.json').read_bytes()) and
            (PROJECT/e.get('generation_context','')).is_file() and sha((PROJECT/e['generation_context']).read_bytes())==e.get('generation_context_sha256') and
            (PROJECT/e['rtl_log']).is_file() and e['rtl_log_sha256']==sha((PROJECT/e['rtl_log']).read_bytes()) and
            all((PROJECT/name).is_file() and sha((PROJECT/name).read_bytes())==digest for name,digest in e.get('rtl_sources',{}).items())):
            subprocess.run([sys.executable,'-B',str(Path(__file__).with_name('test_cpu_reference.py'))],check=True)
            print('SW_P3_TILING_NUMERICAL=FUNCTIONAL_PASS stage=18 cached_evidence=1')
            return
    vivado=os.environ.get('VIVADO_BIN','vivado')
    if not Path(vivado).is_file():
        import shutil
        if not shutil.which(vivado):
            save(evidence_path,dict(status='BLOCKED',reason='Vivado/XSim executable missing'))
            print('SW_P3_TILING_NUMERICAL=BLOCKED missing=Vivado/XSim; frozen tiling retained')
            return
    evidence_path.unlink(missing_ok=True)
    desc=json.loads((GEN/'plan_description.json').read_text())
    stage=next(s for s in desc['stages'] if s['stage_id']==18)
    manifest=json.loads((GEN/'tiling_manifest.json').read_text())
    report=next(s for s in manifest['stages'] if s['stage_id']==18)
    candidate=next(c for c in report['candidates'] if c['status'] in ('BLOCKED_NUMERICAL_VALIDATION','SELECTED_FUNCTIONAL_PASS'))
    plan=json.loads((GEN/'candidate_packets.json').read_text())[f'18:{candidate["candidate_id"]}']
    s=stage['shape'];assert s['kernel']==s['stride']==1 and s['ic']==64 and s['oc']==32
    scale=struct.unpack('<e',struct.pack('<H',s['scale_bits']))[0]
    ninput=s['ih']*s['iw']*s['ic'];noutput=s['oh']*s['ow']*s['oc'];nw=s['ic']*s['oc']
    weights=(np.arange(nw,dtype=np.int64)*7+np.arange(nw,dtype=np.int64)//s['oc']*3)%15-7
    bias=np.arange(s['oc'],dtype=np.int64)*13-200
    for d in range(3):
        indices=np.arange(ninput,dtype=np.int64)
        inputs=(indices*13+indices//s['ic']*7+d*11)%31-15
        acc=inputs.reshape(-1,s['ic'])@weights.reshape(s['ic'],s['oc'])+bias
        quantized=np.clip(np.rint(acc*scale),-128,127).astype(np.int64)
        result=np.trunc(quantized/2).astype(np.int64).reshape(-1)
        for name,values in [('input',inputs),('gold',result)]:
            (SIM/f'{name}{d}.hex').write_text(''.join(f'{int(v)&255:02x}\n' for v in values))
    product=json.loads((PROJECT/'hw/manifests/current.json').read_text())
    missing=[str(Path(product['collateral_directory'])/name) for name in ('Gemmini.sv','CommandFrontendCluster.sv','CommandFrontendMemoryMux.sv') if not (PROJECT/product['collateral_directory']/name).is_file()]
    context=PROJECT/product['generation_context']
    if not context.is_file():missing.append(product['generation_context'])
    context_sha256=sha(context.read_bytes()) if context.is_file() else None
    if missing:
        subprocess.run([sys.executable,'-B',str(Path(__file__).with_name('test_cpu_reference.py'))],check=True)
        save(evidence_path,dict(status='BLOCKED',reason='Current hardware export is incomplete',missing=missing,log='tests/model/frontend_parallel_cache/test_real_tiling.py'))
        print('SW_P3_TILING_NUMERICAL=BLOCKED missing_current_RTL='+','.join(missing))
        return
    def raw(f,a,b):return f"  raw(7'd{f},64'd{a},64'd{b},0);\n"
    code='task prepare_conv;\n  reg [63:0] packed_lut;integer value;\n'
    code+=f'''  // Inputs/weights/bias are served by the deterministic DDR read function.
  for(integer base=0;base<256;base=base+8)begin
    packed_lut=0;
    for(integer b=0;b<8;b=b+1)begin
      value=base+b;if(value>=128)value=value-256;packed_lut[b*8+:8]=8'(value/2);
    end
    raw(26,64'(base),packed_lut,0);
  end
'''
    c=plan['config'];code+=raw(0,c[0],c[1])+raw(0,c[2],c[3])
    for p in plan['tiles']:
        code+=raw(16,c[4],c[5])
        for f,idx in [(17,0),(18,2),(19,4)]:code+=raw(f,*p['geometry'][idx:idx+2])
        off=p['offsets']
        for f,i,j,basea,baseb in [(20,0,1,0x60000,0x62000),(21,2,3,0x61000,0x10000)]:
            aa='64\'d0' if off[i]==0xffffffff else f"64'(BASE)+64'd{basea+off[i]}"
            bb='64\'d0' if off[j]==0xffffffff else f"64'(BASE)+64'd{baseb+off[j]}"
            code+=f'  raw({f},{aa},{bb},0);\n'
        code+=raw(15,*p['launch'])
    code+='endtask\n'
    code+=f'''reg [7:0] sw_p3_gold[0:{noutput}-1];
task check_conv;
  $readmemh($sformatf("{SIM}/gold%0d.hex",ID),sw_p3_gold);
  if(writes!=acks || gem_busy)$fatal(1,"SW-P3 completed before store ACK");
  for(integer i=0;i<{noutput};i=i+1)
    if(memory[sw_p3_map('h62000+i)]!==sw_p3_gold[i])$fatal(1,"SW-P3 stage18 mismatch lane=%0d index=%0d got=%h expected=%h",ID,i,memory[sw_p3_map('h62000+i)],sw_p3_gold[i]);
endtask
'''
    workload=SIM/'ConvWorkload.svh';workload.write_text(code)
    feature=PROJECT/'tests/rtl/command_frontend'
    runner=(feature/'test_real_gemmini.py').read_text()
    runner=runner.replace('feature = Path(__file__).resolve().parent',f'feature = Path({str(feature)!r})')
    runner=runner.replace('out = project / "build/sim/command_frontend/real32"',f'out = Path({str(SIM)!r})')
    runner=runner.replace('(feature/"ConvWorkload.svh").read_text()',f'Path({str(workload)!r}).read_text()')
    anchor='(out/"MemoryLane.sv").write_text(lane)\ntb=tb.replace'
    modifications='''lane=lane.replace("reg [7:0] memory[0:65535]", "reg [7:0] memory[0:262143]")
lane=lane.replace("memory[idx+n]", "memory[sw_p3_map(idx+n)]")
lane=lane.replace("memory[response_address+n]", "sw_p3_peek(response_address+n)")
lane=lane.replace("  task entry", """  function automatic integer sw_p3_map(input integer address);
    if(address>='hf0000)sw_p3_map='h8000+address-'hf0000;
    else if(address>='h62000 && address<'h87800)sw_p3_map='h10000+address-'h62000;
    else sw_p3_map=address;
  endfunction
  function automatic [7:0] sw_p3_peek(input integer address);
    integer i,value;
    if(address>='h10000 && address<'h5b000)begin
      i=address-'h10000;value=(i*13+i/64*7+ID*11)%31-15;sw_p3_peek=8'(value);
    end else if(address>='h60000 && address<'h60800)begin
      i=address-'h60000;value=(i*7+i/32*3)%15-7;sw_p3_peek=8'(value);
    end else if(address>='h61000 && address<'h61080)begin
      i=address-'h61000;value=(i/4*13-200)>>((i%4)*8);sw_p3_peek=8'(value);
    end else sw_p3_peek=memory[sw_p3_map(address)];
  endfunction
  task entry""")
lane=lane.replace("ID*32'h10000", "ID*32'h1000000")
lane=lane.replace("BASE+32'h10000", "BASE+32'h100000")
lane=lane.replace("memory['h8000+", "memory['hf0000+")
lane=lane.replace("memory['hf0000+command_count*32+b]", "memory[sw_p3_map('hf0000+command_count*32+b)]")
lane=lane.replace("response_delay<=7+ID*3", "response_delay<=1+ID")
lane=lane.replace("response_delay<=30+ID*11", "response_delay<=2+ID")
'''
    assert anchor in runner
    runner=runner.replace(anchor,modifications+anchor,1)
    extra=32+2+7*len(plan['tiles'])
    runner=runner.replace('tb=tb.replace("reset=0;",',f'''tb=tb.replace("116:115", "{41+extra}:{40+extra}").replace("fetches!=116", "fetches!={41+extra}").replace("fetches!=115", "fetches!={40+extra}")
tb=tb.replace("80008000", "800f0000").replace("i*65536", "i*16777216").replace("1000000);", "10000000);").replace("#20000000;", "#200000000;")
tb=tb.replace("reset=0;",''')
    runner=runner.replace('for command in (', '''import hashlib
sw_p3_source_hashes={str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in sources}
(out/"rtl_source_hashes.json").write_text(json.dumps(sw_p3_source_hashes,indent=2))
for command in (''',1)
    script=SIM/'run.py';script.write_text(runner)
    env=dict(os.environ,VIVADO_BIN=os.environ.get('VIVADO_BIN','vivado'))
    subprocess.run([sys.executable,'-B',str(script)],check=True,env=env)
    if not context.is_file() or sha(context.read_bytes())!=context_sha256:
        save(evidence_path,dict(status='BLOCKED',reason='Hardware export changed during numerical simulation'))
        print('SW_P3_TILING_NUMERICAL=BLOCKED hardware_export_changed=1')
        return
    rtl_inputs=json.loads((SIM/'rtl_source_hashes.json').read_text())
    if not all(Path(name).is_file() and sha(Path(name).read_bytes())==digest for name,digest in rtl_inputs.items()):
        save(evidence_path,dict(status='BLOCKED',reason='RTL sources changed during numerical simulation'))
        print('SW_P3_TILING_NUMERICAL=BLOCKED rtl_inputs_changed=1')
        return
    log=SIM/'result.log';text=log.read_text()
    if 'REAL_CLUSTER_PASS' not in text or 'Fatal:' in text:raise ValueError('Real candidate arithmetic failed')
    evidence=dict(generation_context=product['generation_context'],generation_context_sha256=context_sha256,schema=1,stage_id=18,candidate_id=candidate['candidate_id'],candidate_plan_hash=sha(plan),
        status='FUNCTIONAL_PASS',coverage='FULL stage18, three lanes, synthetic signed inputs/weights/bias, FP16 scale, nonidentity LUT, all output bytes, real DIM32 RTL',
        output_bytes_per_lane=noutput,rtl_log=str(log.relative_to(PROJECT)),rtl_log_sha256=sha(log.read_bytes()),
        checker_sha256=sha(Path(__file__).read_bytes()),hardware_files_sha256=sha((PROJECT/'hw/manifests/current.json').read_bytes()),
        plan_description_sha256=sha((GEN/'plan_description.json').read_bytes()))
    inputs=re.findall(r'sv work "([^"]+)"',(SIM/'simulation.prj').read_text())
    evidence['rtl_sources']={str(Path(p).relative_to(PROJECT)):sha(Path(p).read_bytes()) for p in inputs if Path(p).is_relative_to(PROJECT)}
    subprocess.run([sys.executable,'-B',str(Path(__file__).with_name('test_cpu_reference.py'))],check=True)
    evidence['native_cpu_reference']=json.loads((OUT/'native_cpu_reference.json').read_text())
    save(evidence_path,evidence)
    print('SW_P3_TILING_NUMERICAL=FUNCTIONAL_PASS stage=18 lanes=3 outputs='+str(noutput))

if __name__=='__main__':main()
