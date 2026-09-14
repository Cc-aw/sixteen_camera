#!/usr/bin/env python3
"""I: one complete v5 UART run. P: validate records and reconcile nested timings.
O: JSON timing ledger, without adding overlapping counters. A: 王志瑞. T: 2026-09-10.
"""
import argparse, collections, json, re
from pathlib import Path

def analyze(text):
    lines=text.splitlines()
    def rows(prefix):
        return [dict(re.findall(r'(\w+)=([^\s]+)',line)) for line in lines if line.startswith(prefix)]
    def one(prefix):
        found=rows(prefix)
        if len(found)!=1: raise ValueError(f'{prefix}: expected one run/record, got {len(found)}')
        return found[0]
    header=one('YOLOV5NU_N6 ')
    if header['revision'] not in {'n6_port_v5_timing','n6_port_v6_conv_tiles','n6_port_v7_conv0_align','n6_port_v8_ddr_v6','n6_port_v8_ddr_v7','n6_port_m01_s2d2','n6_port_dma_profile_v6','n6_port_dma_profile_v7'}: raise ValueError('expected supported N6 timing software')
    inference=one('N6_INFERENCE '); timing=one('N6_TIMING ')
    profile=one('YOLOV5NU_PROFILE records='); cache=one('N6_CACHE ')
    scopes=rows('N6_SCOPE '); flushes=rows('N6_FLUSH ')
    ops=rows('YOLOV5NU_PROFILE record='); memory=rows('N6_MEMORY ')
    if int(timing['overflow']): raise ValueError('trace overflow')
    if len(scopes)!=int(timing['scopes']) or len(flushes)!=int(timing['flushes']): raise ValueError('missing trace lines')
    if len(ops)!=int(profile['records']) or len(memory)!=len(scopes): raise ValueError('missing operator/memory lines; enable verbose UART')
    for key in ('uart_included','validation_included'):
        if inference[key]!='0': raise ValueError('unexpected FPS boundary')
    is_m01=header['revision']=='n6_port_m01_s2d2'
    if inference['input_preprocessing_included']!=('1' if is_m01 else '0'): raise ValueError('unexpected input preparation timing')
    prep=one('N6_PREP ') if is_m01 else {}
    if is_m01 and (prep['kind']!='s2d2' or prep['included_in_inference']!='1' or int(prep['bytes'])!=921600): raise ValueError('invalid M01 preparation')
    def total(records,key): return sum(int(r[key]) for r in records)
    if total(flushes,'cycles')!=int(cache['cycles']) or total(flushes,'bytes')!=int(cache['flushed_bytes']): raise ValueError('cache totals do not reconcile')
    for i,r in enumerate(scopes):
        if int(r['id'])!=i or r['op']!=memory[i]['op']: raise ValueError('scope ordering mismatch')
        f=[x for x in flushes if int(x['scope'])==i]
        if total(f,'cycles')!=int(r['cache_cycles']): raise ValueError('scope cache mismatch')
        if sum(int(r[k]) for k in ('cache_cycles','wait_cycles','other_cycles'))!=int(r['total_cycles']): raise ValueError('scope partition mismatch')
    for k,field in [('scope_cycles','total_cycles'),('cache_cycles','cache_cycles'),('wait_cycles','wait_cycles')]:
        if int(timing[k])!=total(scopes,field): raise ValueError('scope totals mismatch')
    # I: v6 per-group admission counters. P: reconcile hardware and software.
    # O: validated submission and credit-wait evidence. A: 王志瑞. T: 2026-09-10.
    credit=rows('N6_CREDIT ')
    if header['revision'] in {'n6_port_v6_conv_tiles','n6_port_v7_conv0_align','n6_port_v8_ddr_v6','n6_port_v8_ddr_v7','n6_port_m01_s2d2','n6_port_dma_profile_v6','n6_port_dma_profile_v7'}:
        if len(credit)!=len(scopes): raise ValueError('missing credit records')
        for i,c in enumerate(credit):
            if int(c['id'])!=i or c['op']!=memory[i]['op']: raise ValueError('credit ordering mismatch')
            if not (int(c['calls'])==int(c['accepted'])==int(c['retired'])): raise ValueError('admission/hardware counters differ')
            if int(c['waited_calls'])>int(c['calls']): raise ValueError('invalid waited call count')
            expected={'yolov5nu_conv0_weights':(75 if is_m01 else 100),'yolov5nu_conv1_weights':27,'yolov5nu_conv7_weights':10}.get(c['op'])
            if expected is not None and int(c['calls'])!=expected: raise ValueError('unexpected candidate submission count')
    # I: raw v8 DMA counters. P: retain multi-beat caveat and occupancy meaning.
    # O: response-byte bounds, never claimed as measured DDR bandwidth.
    # A: 王志瑞. T: 2026-09-10.
    dma=rows('N6_DMA ')
    if header['revision'].startswith(('n6_port_v8_ddr_','n6_port_dma_profile_')) or is_m01:
        if len(dma)!=len(scopes): raise ValueError('missing DMA records')
        for i,d in enumerate(dma):
            if int(d['id'])!=i or d['op']!=memory[i]['op']: raise ValueError('DMA ordering mismatch')
            if d['rdma_multibeat_overcount']!='1' or d['ddr_bytes_measured']!='0': raise ValueError('invalid DMA byte interpretation')
            for k in ('rdma_bytes_raw','wdma_transaction_bytes','rdma_occupancy_cycles','wdma_occupancy_cycles'):
                if not 0<=int(d[k])<2**32: raise ValueError('invalid hardware counter value')
            for k in ('load_req_backpressure','store_req_backpressure','rdma_tlb_wait'):
                if k not in memory[i]: raise ValueError('wrong memory event set')
            raw=int(d['rdma_bytes_raw']);cycles=int(memory[i]['cycles'])
            if cycles<=0: raise ValueError('invalid DMA timing window')
            d['tl_response_bytes_lower_bound']=(raw+1)//2
            d['tl_response_bytes_upper_bound']=raw
            d['rdma_mean_outstanding_approx']=int(d['rdma_occupancy_cycles'])/cycles
            d['wdma_mean_outstanding_approx']=int(d['wdma_occupancy_cycles'])/cycles
    if is_m01 and not 0<=int(prep['cycles'])<=int(inference['cycles']): raise ValueError('invalid preparation duration')
    groups=collections.Counter()
    for r in ops: groups[r['kind']]+=int(r['cycles'])
    # Conv subphases are already inside Conv. Decode/NMS live outside graph.
    graph_ops=sum(v for k,v in groups.items() if k not in {'CONV_IN_LAYOUT','CONV_GEMMINI','CONV_OUT_LAYOUT','DECODE','NMS'})
    phase=sum(int(profile[k]) for k in ('graph_cycles','decode_cycles','nms_cycles'))+int(prep.get('cycles',0))
    result={'header':header,'inference':inference,'correct':all(int(v)==0 for v in one('N6_CHECK ').values()) and any(x.startswith('RESULT: PASS') for x in lines),
      'first_layer_including_preparation_cycles':int(prep.get('cycles',0))+int(scopes[0]['total_cycles']),
      'preparation':prep,'ledger_cycles':{'preparation':int(prep.get('cycles',0)),'inference':int(inference['cycles']),'graph':int(profile['graph_cycles']),
      'decode':int(profile['decode_cycles']),'nms':int(profile['nms_cycles']),
      'between_phases':int(inference['cycles'])-phase,'graph_operator_sum':graph_ops,
      'graph_unattributed':int(profile['graph_cycles'])-graph_ops,
      'accelerator_scopes':total(scopes,'total_cycles'),'scope_cache':total(scopes,'cache_cycles'),
      'scope_explicit_wait':total(scopes,'wait_cycles'),'scope_other':total(scopes,'other_cycles')},
      'dma':dma,'credit':credit,'operator_kind_cycles':dict(groups),'top_scopes':sorted(scopes,key=lambda r:int(r['total_cycles']),reverse=True),
      'top_flushes':sorted(flushes,key=lambda r:int(r['cycles']),reverse=True),
      'report':one('N6_REPORT '),'validation':one('N6_VALIDATION '),
      'notes':['Scopes are inside graph operators; hardware events overlap and must not be summed.',
      'Explicit waits do not cover waits inside precompiled header functions. Other includes submission, internal waits and instrumentation.',
      'Graph residual includes measurement/dispatch overhead; negative residual indicates overlapping operator records.',
      'Report includes formatting and UART calls; validation includes its check-line UART; both excluded from FPS.', 'M01 includes per-frame input packing; baseline revisions start with ready input. Compare preparation plus graph, never graph alone.']}
    # I: ABI-v1 trace. P: enforce complete per-layer histograms and drained transactions.
    # O: named DMA evidence. A: 王志瑞. T: 2026-09-11.
    if header['revision'].startswith('n6_port_dma_profile_'):
        from analyze_dma_profile import parse_records
        result['dma_profile']=parse_records(text,memory,int(header['clock_hz']))
        result['notes'].append('New counters observe Gemmini TL, not DDR; legacy raw-byte ABI remains unchanged. Profiling reads are included in frame/scope overhead.')
    return result

def main():
    p=argparse.ArgumentParser();p.add_argument('log',type=Path);p.add_argument('--output',type=Path);a=p.parse_args()
    result=analyze(a.log.read_text());data=json.dumps(result,ensure_ascii=False,indent=2)+'\n'
    if a.output: a.output.write_text(data)
    else: print(data,end='')
if __name__=='__main__': main()
