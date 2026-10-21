#!/usr/bin/env python3
"""Three real DIM32 lanes: original-layout representative layer A/B and traces.

Spatial dimensions are compact; channels, weights, strides, scales, LUTs and
channel tiling come from the frozen stages. This is not a full-network run.
"""
import argparse
import hashlib
import importlib.util
import json
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT/'sw/benchmarks/frontend/scripts'))
from first_layer_s2d_prepare import array
from parallel_cache_plan import regenerate, semantic


def write_evidence(out, rtl, trace=False):
    context=json.loads((rtl.resolve().parent/'GENERATION_CONTEXT.json').read_text())
    count=len(context['dma_load_supported_modes'])
    active=(0,2) if trace else tuple(range(count))
    log=(out/'result.log').read_text()
    records=re.findall(r'DMA_LAYER_PASS,lane=(\d+),case=(\d+),mode=(\d+),reads=(\d+),writes=(\d+),acks=(\d+)',log)
    keys={(int(l),int(c),int(m)) for l,c,m,*_ in records}
    assert len(records)==len(keys)==24*len(active)
    assert keys=={(l,c,m) for l in range(3) for c in range(8) for m in active}
    assert all(w==a for _,_,_,_,w,a in records)
    assert (f'REAL_CLUSTER_PASS,DMA_LAYERS=8,modes={count},lanes=3' if not trace else 'REAL_TRACE_LAYERS_PASS,mode_ids=0/2,lanes=3') in log
    assert not re.search(r'Fatal:|Error:|Assertion failed:',log)
    (out/'evidence.json').write_text(json.dumps(dict(status='TRACE_WORKLOAD_PASS' if trace else 'REPRESENTATIVE_LAYERS_PASS',
        build_id=context['dma_load_build_id'],stages=[0,2,4,5,8,10,59,132],modes=len(active),runtime_mode_ids=list(active),lanes=3,
        full_model_executed=False,log_sha256=hashlib.sha256(log.encode()).hexdigest()),indent=2)+'\n')


def write_trace_manifest(out, rtl):
    sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'scripts'))
    from spad_trace import probe
    # Bind the current probe to the exact generated/compiled test workload.
    assert probe() in (out/'feature/ConvWorkload.svh').read_text()
    context_path=rtl.resolve().parent/'GENERATION_CONTEXT.json'
    trace=out/'spad_events_lane0.csv'
    assert trace.is_file() and trace.stat().st_size>0
    manifest=dict(schema=1,build_id=json.loads(context_path.read_text())['dma_load_build_id'],
        trace=str(trace),trace_sha256=hashlib.sha256(trace.read_bytes()).hexdigest(),
        initial_state='Full real SPAD snapshot; test SRAM initialized to poison at reset',
        scope='Compact eight representative layers; lane 0; runtime mode 2; not full-network weighting',
        probe_sha256=hashlib.sha256((Path(__file__).resolve().parents[1]/'scripts/spad_trace.py').read_bytes()).hexdigest(),
        simulation_project_sha256=hashlib.sha256((out/'simulation.prj').read_bytes()).hexdigest(),
        workload_sha256=hashlib.sha256((out/'feature/ConvWorkload.svh').read_bytes()).hexdigest())
    (out/'trace_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--rtl', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--native', type=Path, default=ROOT/'build/firmware/dma-load-2bank/native')
    parser.add_argument('--memory-latency',type=int,choices=(1,7),default=7,help='Functional DDR response delay; dedicated backpressure/fault tests remain independent')
    parser.add_argument('--verify-only',action='store_true')
    parser.add_argument('--trace',action='store_true',help='Record a known-state SPAD trace for B0/B1 (compact layers, lane 0, mode 2)')
    args = parser.parse_args()
    if args.verify_only:
        write_evidence(args.output.resolve(),args.rtl,args.trace)
        if args.trace:write_trace_manifest(args.output.resolve(),args.rtl)
        return
    mode_count=len(json.loads((args.rtl.resolve().parent/'GENERATION_CONTEXT.json').read_text())['dma_load_supported_modes'])
    out = args.output.resolve()
    out.mkdir(parents=True, exist_ok=False)
    snap = args.native.resolve()
    frozen = json.loads((snap/'fixed_plans.json').read_text())
    params = next(snap.glob('*profile_params.h')).read_text()
    bindings = [(0,0),(2,1),(4,2),(5,3),(8,4),(10,5),(59,25),(132,57)]
    requests, shapes = [], []
    for stage, conv in bindings:
        s = semantic(frozen['fixed_packets'][str(stage)])
        spatial = 16 if stage == 0 else 2 if stage in (59,132) else 4
        oh = (spatial + 2*s['pad'] - s['kernel'])//s['stride'] + 1
        shape = dict(s, ih=spatial, iw=spatial, oh=oh, ow=oh)
        tile = list(frozen['ordinary'][str(stage)]['tile'])
        tile[1],tile[2] = min(tile[1],oh),min(tile[2],oh)
        requests.append((stage,0,shape,tile))
        shapes.append(shape)
    plans, capacities = regenerate(snap,requests,out)
    assert len(plans)==len(bindings), 'Representative plan exceeds capacity'
    feature = out/'feature'
    (feature/'reference').mkdir(parents=True)
    original = ROOT/'tests/rtl/command_frontend'
    lane = (original/'reference/MemoryLane.sv').read_text()
    lane = lane.replace('BASE+32\'h10000', 'BASE+32\'h100000').replace("ID*32'h10000", "ID*32'h100000")
    lane = lane.replace('memory[0:65535]', 'memory[0:1048575]')
    if args.memory_latency==1:
        lane=lane.replace('response_delay<=7+ID*3;','response_delay<=1;')
    (feature/'reference/MemoryLane.sv').write_text(lane)
    (feature/'reference/tb_real_cluster.sv').write_bytes((original/'reference/tb_real_cluster.sv').read_bytes())
    lut_text = (snap/'prepared_packets.inc').read_text().split('packed_silu_luts[69][32] = {',1)[1]
    lut_words = list(map(int,re.findall(r'UINT64_C\((\d+)\)',lut_text.split('};',1)[0])))
    assert len(lut_words)==69*32
    code = 'task prepare_conv;endtask\ntask check_conv;endtask\n'
    code += 'integer layer_case=0;integer row_trace;reg [7:0] legacy_output[0:32767];\n'
    code += 'initial row_trace=$fopen($sformatf("rows_lane%0d.csv",ID),"w");\n'
    signals = ['cmd_first','cmd_last','row_index','cmd_rows','cmd_id','vaddr','cols','pixel_repeats','cmd_stride_bytes','all_zeros']
    probe = 'gemmini.dut.load_controller.io_dma_req'
    code += f'always @(posedge clock)if(!reset && {probe}_valid && {probe}_ready)\n'
    code += '  $fdisplay(row_trace,"%0d,%0d,'+','.join(['%0d']*len(signals))+'",layer_case,dma_load_mode,'
    code += ','.join(probe+'_bits_'+name for name in signals)+');\n'
    code += 'task initialize_layer(input integer index);\n layer_case=index;command_count=0;reads=0;writes=0;acks=0;fetches=0;\n'
    code += " for(integer i=0;i<1048576;i=i+1)memory[i]=(dma_load_mode==0)?8'ha5:8'h5a;\n case(index)\n"
    metadata=[]
    for index, ((stage,conv),s) in enumerate(zip(bindings,shapes)):
        weights,bias = array(params,f'yolov5nu_conv{conv}_weights'),array(params,f'yolov5nu_conv{conv}_bias')
        data = out/f'layer_{stage}.mem'
        data.write_text('@4000\n'+'\n'.join(f'{((i*13+i//3*7)%63-31)&255:02x}' for i in range(s['ih']*s['iw']*s['istride']))+
            '\n@10000\n'+'\n'.join(f'{v&255:02x}' for v in weights)+
            '\n@60000\n'+'\n'.join(f'{(v>>(8*b))&255:02x}' for v in bias for b in range(4))+'\n')
        code += f' {index}:begin\n $readmemh("{data}",memory);\n'
        for word,value in enumerate(lut_words[conv*32:(conv+1)*32]):
            code += f" raw(26,64'd{word*8},64'd{value},0);\n"
        plan = plans[stage,0];c=plan['config']
        for f,a,b in ((0,c[0],c[1]),(0,c[2],c[3])):code+=f" raw({f},64'd{a},64'd{b},0);\n"
        for packet in plan['tiles']:
            code+=f" raw(16,64'd{c[4]},64'd{c[5]},0);\n"
            for k in range(3):code+=f" raw({17+k},64'd{packet['geometry'][2*k]},64'd{packet['geometry'][2*k+1]},0);\n"
            for f,k in ((20,0),(21,2)):
                bases=(0x10000,0x70000,0x60000,0x4000)
                operands=["64'd0" if packet['offsets'][j]==0xffffffff else f"64'(BASE)+64'd{bases[j]+packet['offsets'][j]}" for j in (k,k+1)]
                code+=f" raw({f},{operands[0]},{operands[1]},0);\n"
            code+=f" raw(15,64'd{packet['launch'][0]},64'd{packet['launch'][1]},0);\n"
        code+=' entry(256\'d1);end\n'
        metadata.append(dict(stage=stage,conv=conv,shape=s,plan=plan,capacity=capacities[stage,0],data_sha256=hashlib.sha256(data.read_bytes()).hexdigest()))
    code+=' endcase\n endtask\n task check_layer(input integer index);\n integer offset,changed;\n changed=0;\n'
    code+=' if(writes!=acks || gem_busy)$fatal(1,"layer completion before ACK");\n case(index)\n'
    for index,((stage,conv),s) in enumerate(zip(bindings,shapes)):
        code+=f' {index}:begin\n for(integer pixel=0;pixel<{s["oh"]*s["ow"]};pixel=pixel+1)for(integer c=0;c<{s["oc"]};c=c+1)begin\n'
        code+=f' offset=pixel*{s["ostride"]}+c;\n'
        code+=" if(dma_load_mode==0)legacy_output[offset]=memory['h70000+offset];\n"
        code+=" else if(legacy_output[offset]!==memory['h70000+offset])$fatal(1,\"layer byte mismatch lane=%0d stage=%0d mode=%0d offset=%0d\",ID,index,dma_load_mode,offset);\n"
        code+=" if(memory['h70000+offset]!==8'ha5 && memory['h70000+offset]!==8'h5a)changed=changed+1;\n end\n end\n"
    code+=' endcase\n if(changed==0)$fatal(1,"empty layer output");\n'
    code+=' $display("DMA_LAYER_PASS,lane=%0d,case=%0d,mode=%0d,reads=%0d,writes=%0d,acks=%0d",ID,index,dma_load_mode,reads,writes,acks);\n endtask\n'
    # Keep one golden per stage and lane across mode changes.
    code = code.replace('reg [7:0] legacy_output[0:32767]', 'reg [7:0] legacy_output[0:262143]')
    code = code.replace('legacy_output[offset]', 'legacy_output[index*32768+offset]')
    if args.trace:
        sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'scripts'))
        from spad_trace import probe
        code+=probe()
        probe_hash=hashlib.sha256((Path(__file__).resolve().parents[1]/'scripts/spad_trace.py').read_bytes()).hexdigest()
        code=code.replace('task initialize_layer(input integer index);',
            'task initialize_layer(input integer index);')
        code=code.replace('layer_case=index;command_count=0;', 'layer_case=index;trace_begin();command_count=0;')
        code=code.replace(' if(writes!=acks || gem_busy)', ' trace_end();\n if(writes!=acks || gem_busy)')
    (feature/'ConvWorkload.svh').write_text(code)
    runner=(Path(__file__).parent/'test_real_gemmini.py').read_text()
    runner=runner.replace('feature = Path(__file__).resolve().parent',f'feature = Path({str(feature)!r})')
    runner=runner.replace('project = feature.parents[2]',f'project = Path({str(ROOT)!r})')
    replacement='''
tb=tb[:tb.index('  initial begin')]+r'''+"'''"+'''
  initial begin
    repeat(20)@(negedge clock);reset=0;repeat(64)@(negedge clock);
    for(runtime_mode=0;runtime_mode<3;runtime_mode=runtime_mode+1)begin
      for(integer lane_id=0;lane_id<3;lane_id=lane_id+1)begin
        ctl(lane_id,9,64'(runtime_mode),0);read(lane_id,8,v);
        if(v!==64'(runtime_mode))$fatal(1,"mode readback");
      end
      for(integer layer=0;layer<8;layer=layer+1)begin
        lanes[0].lane.initialize_layer(layer);lanes[1].lane.initialize_layer(layer);lanes[2].lane.initialize_layer(layer);
        for(integer lane_id=0;lane_id<3;lane_id=lane_id+1)begin
          ctl(lane_id,0,64'h80008000+lane_id*1048576,lanes[0].lane.command_count);
          ctl(lane_id,1,64'h80000000+lane_id*1048576,1000000);
        end
        ctl(3,7,7,7);wait(&dut.complete);@(negedge clock);
        lanes[0].lane.check_layer(layer);lanes[1].lane.check_layer(layer);lanes[2].lane.check_layer(layer);
        ctl(0,5,0,0);ctl(1,5,0,0);ctl(2,5,0,0);
      end
    end
    $display("REAL_CLUSTER_PASS,DMA_LAYERS=8,modes=3,lanes=3");$finish;
  end
  initial begin #200000000;$fatal(1,"DMA layer timeout");end
endmodule
'''+"'''"+'''
'''
    replacement=replacement.replace('runtime_mode<3',f'runtime_mode<{mode_count}').replace('modes=3',f'modes={mode_count}')
    if args.trace:
        replacement=replacement.replace('runtime_mode=runtime_mode+1','runtime_mode=runtime_mode+2')
        replacement=replacement.replace('runtime_mode<4','runtime_mode<3')
        replacement=replacement.replace('REAL_CLUSTER_PASS,DMA_LAYERS=8,modes=4,lanes=3','REAL_TRACE_LAYERS_PASS,mode_ids=0/2,lanes=3')
    anchor='(out/"tb_real_cluster.sv").write_text(tb)' 
    assert runner.count(anchor)==1
    runner=runner.replace(anchor,replacement+'\n'+anchor)
    (out/'run.py').write_text(runner)
    (out/'cases.json').write_text(json.dumps(metadata,indent=2)+'\n')
    subprocess.run([sys.executable,str(out/'run.py'),'--rtl',str(args.rtl.resolve()),
                    '--output',str(out),'--dma-load-mode','all'],check=True)
    write_evidence(out,args.rtl,args.trace)
    if args.trace:write_trace_manifest(out,args.rtl)


if __name__ == '__main__':
    main()
