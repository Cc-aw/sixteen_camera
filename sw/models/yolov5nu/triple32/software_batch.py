"""One integrated four-slot image: native stage programs and local bindings.

All command operands come from existing native-C generated plans. This module
only specializes control flow and address-role selection, never FP16 packing.
"""
from pathlib import Path
import json
import re
from fixed_plans import graph_stages

HERE=Path(__file__).resolve().parent


def repeated(steps,packets,start,length):
    """Find affine packet-index motifs with identical config/LUT/wait order."""
    if start+2*length>len(steps):return 1,[]
    first=steps[start:start+length];second=steps[start+length:start+2*length]
    deltas=[]
    for (k,i),(k2,j) in zip(first,second):
        if k!=k2 or (k!=1 and i!=j):return 1,[]
        deltas.append(j-i if k==1 else 0)
    def tail(pos):return pos+1<len(steps) and steps[pos+1][0]==3
    count=1
    while start+(count+1)*length<=len(steps):
        for off,((kind,index),delta) in enumerate(zip(first,deltas)):
            pos=start+count*length+off;k,j=steps[pos]
            if k!=kind or j!=index+count*delta:break
            if kind==1 and (packets[j]['roles']!=packets[index]['roles'] or tail(pos)!=tail(start+off)):break
        else:
            count+=1;continue
        break
    return count,deltas


def stage_source(stage,plan,packets):
    steps=plan['steps'];lines=[f'static void yolo32_batch_ws_{stage}(const struct yolo32_ws_binding *b) {{']
    def emit(pos,index,indent):
        kind,original=steps[pos]
        if kind==0:
            lines.append(indent+f'ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[{index}][0],prepared_ws_configs[{index}][1],0);')
        elif kind==2:lines.append(indent+f'yolo32_packed_silu_lut(packed_silu_luts[{index}]);')
        elif kind==3:lines.append(indent+'gemmini_fence();')
        else:
            roles=packets[original]['roles']
            lines.append(indent+'{')
            lines.append(indent+f'  const struct yolo32_prepared_ws_packet *p=&prepared_ws_packets[{index}];')
            if pos+1<len(steps) and steps[pos+1][0]==3:
                lines.append(indent+'  if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);')
            addresses=['UINT64_C(0)' if role==255 else f'(uintptr_t)b->base[{role}]+p->offsets[{i}]' for i,role in enumerate(roles)]
            lines.append(indent+'  yolo32_bound_ws_submit(p,'+','.join(addresses)+');')
            lines.append(indent+'}')
    pos=0;motifs=0
    while pos<len(steps):
        best=(1,1,[])
        for length in range(1,min(32,(len(steps)-pos)//2)+1):
            count,deltas=repeated(steps,packets,pos,length)
            if count>1 and count*length>best[0]*best[1]:best=(count,length,deltas)
        count,length,deltas=best
        if count>1:
            lines.append(f'  for (unsigned iteration=0;iteration<{count}U;++iteration) {{');motifs+=1
            for off,delta in enumerate(deltas):
                index=steps[pos+off][1]
                expr=f'{index}U+iteration*{delta}U' if delta else str(index)
                if delta<0:raise ValueError('Unexpected backwards native packet motif')
                emit(pos+off,expr,'    ')
            lines.append('  }');pos+=count*length
        else:emit(pos,str(steps[pos][1]),'  ');pos+=1
    lines.append('}')
    return '\n'.join(lines)+'\n',motifs


def bake(out,model):
    manifest=json.loads((out/'fixed_plans.json').read_text())
    conv_calls={}
    for stage,body in graph_stages(model).items():
        matches=list(re.finditer(r'yolo32_fixed_conv\(([^;]+)\);',body))
        if matches:
            if len(matches)!=1:raise ValueError('Ambiguous bound Conv stage')
            args=[x.strip() for x in matches[0][1].split(',')]
            if len(args)!=5:raise ValueError('Unexpected bound Conv signature')
            conv_calls[stage]=(args,matches[0][0])
    if len(conv_calls)!=58:raise ValueError('Expected all 58 ordinary Conv bindings')
    plans=manifest['prepared_ws'];packets=manifest['prepared_ws_packets']
    sources=[(HERE/'software_batch_runtime.inc').read_text()];motifs=0
    for s,p in sorted(plans.items(),key=lambda item:int(item[0])):
        code,n=stage_source(s,p,packets);sources.append(code);motifs+=n
    (out/'software_batch_packets.inc').write_text('\n'.join(sources))
    model=model.replace('#include "prepared_packets.inc"','#include "prepared_packets.inc"\n#include "software_batch_packets.inc"',1)
    bindings=['static struct yolo32_conv_binding batch_conv_bindings[3][58];',
              'static struct yolo32_ws_binding batch_ws_bindings[3][20];',
              'static uint32_t batch_binding_generation[3];',
              'static uint64_t batch_bind_once_cycles, batch_bind_cycles[3];']
    stable=[];dynamic=[];dynamic_count=0
    def bind(target,expr):
        nonlocal dynamic_count
        if 'model_input' in expr or 'context' in expr or re.search(r'\braw_(?:class|dfl)[012]\b',expr):
            dynamic.append(f'  {target}={expr};');dynamic_count+=1
        else:stable.append(f'  {target}={expr};')
    for index,(stage,(args,call)) in enumerate(sorted(conv_calls.items())):
        for name,expr in zip(['input','weights','bias','output'],args[1:]):bind(f'batch_conv_bindings[worker][{index}].{name}',expr)
        model=model.replace(call,f'yolo32_bound_conv({args[0]},&batch_conv_bindings[worker_id][{index}]);',1)
    for index,(s,p) in enumerate(sorted(plans.items(),key=lambda item:int(item[0]))):
        body=graph_stages(model)[int(s)]
        call=re.search(r'yolo32_prepared_ws\([^;]+\);',body)
        if not call:raise ValueError('Missing prepared WS stage')
        model=model.replace(call[0],f'yolo32_batch_ws_{s}(&batch_ws_bindings[worker_id][{index}]);',1)
        for role,expr in enumerate(p['bases']):bind(f'batch_ws_bindings[worker][{index}].base[{role}]',expr)
    bindings+=['static void yolo32_batch_bind_init(void) {',
               '  uint64_t begin=read_cycle();',
               '  memset(batch_binding_generation,0,sizeof(batch_binding_generation));',
               '  memset(batch_bind_cycles,0,sizeof(batch_bind_cycles));',
               '  for (unsigned worker=0;worker<3;++worker) {',
               '    select_worker_memory(worker);']+stable+[
               '  }','  batch_bind_once_cycles=read_cycle()-begin;','}',
               'static void yolo32_batch_bind_start(unsigned worker) {',
               '  uint64_t begin=read_cycle();',
               '  select_worker_memory(worker);',
               '  struct yolov5nu_worker_context *context=&worker_contexts[worker];',
               '  const elem_t *model_input=context->input;',
               '  if (!model_input) yolo32_fail("batch_binding_input");']+dynamic+[
               '  if (++batch_binding_generation[worker]==0) ++batch_binding_generation[worker];',
               '  batch_bind_cycles[worker]=read_cycle()-begin;','}']
    marker='int yolov5nu_dim16_worker_poll('
    model=model.replace(marker,'\n'.join(bindings)+'\n\n'+marker,1)
    needle='  gemmini_pool_active_worker = 0U;\n}'
    if needle not in model:raise ValueError('Binding init lifecycle changed')
    # Init occurs before definitions above, hence explicit prototypes.
    model=model.replace('static void (*head_callback)',
                        'static void yolo32_batch_bind_init(void);\nstatic void yolo32_batch_bind_start(unsigned);\nstatic void (*head_callback)',1)
    model=model.replace(needle,'  yolo32_batch_bind_init();\n'+needle,1)
    manifest['software_batch']={'schema':1,'stage_exec':'generated','binding':'stage-local',
        'conv_stages':58,'ws_stages':20,'ws_steps':sum(len(p['steps']) for p in plans.values()),
        'repeated_motifs':motifs,'binding_bytes':3*(58*4+20*10)*8,
        'dynamic_fields_per_worker':dynamic_count,'original_waits_preserved':True}
    (out/'fixed_plans.json').write_text(json.dumps(manifest,indent=2,sort_keys=True)+'\n')
    return model
