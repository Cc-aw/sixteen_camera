#!/usr/bin/env python3
"""I: complete N6 profiling UART log. P: validate histograms and reconcile transactions.
O: named per-layer JSON/CSV with overlapping time semantics. A: 王志瑞. T: 2026-09-11.
"""
import argparse,csv,json,re
from pathlib import Path
NAMES=['signature','requests','requested_bytes','tl_transactions','tl_coverage_bytes',
       'd_beats','read_response_bytes','write_mask_bytes','a_stall_cycles','d_stall_cycles',
       'request_stall_cycles','outstanding_integral','outstanding_peak','full_cycles',
       'full_and_request_stall_cycles','outstanding_busy_cycles','overflow']
NAMES += ['req_'+x for x in ['zero','1_4','5_8','9_16','17_32','33_64','65_128','129_plus']]
NAMES += ['tl_size_'+str(x) for x in [1,2,4,8,16,32,64]]+['tl_size_128_plus','protocol_errors','active_cycles']
def parse_records(text,memory,clock_hz):
    rows=[dict(re.findall(r'(\w+)=([^\s]+)',s)) for s in text.splitlines() if s.startswith('N6_DMA_PROFILE ')]
    if len(rows)!=2*len(memory): raise ValueError('missing DMA profiling records')
    result=[]
    for k,r in enumerate(rows):
        idx=k//2;direction=['read','write'][k%2]
        if (int(r['id']),r['direction'],r['op'])!=(idx,direction,memory[idx]['op']): raise ValueError('profile ordering mismatch')
        if r['abi']!='1' or r['ddr_bytes_measured']!='0': raise ValueError('unsupported ABI/DDR interpretation')
        c=[int(r[f'c{j}']) for j in range(35)]
        if any(v<0 or v>=2**64 for v in c): raise ValueError('counter range')
        if c[0]!=(0x4e36505200010000|(k%2)): raise ValueError('profiling signature mismatch')
        if c[16] or c[33]: raise ValueError('counter overflow or TL tracking error')
        if sum(c[17:25])!=c[1] or sum(c[25:33])!=c[3]: raise ValueError('histogram total mismatch')
        if c[32]: raise ValueError('unexpected >=128-byte TL request on frozen N6')
        if sum(c[25+j]*(1<<j) for j in range(7))!=c[4]: raise ValueError('transaction bytes mismatch')
        if not (c[12]<=32 and c[11]>=c[15] and c[11]<=32*c[15] and c[14]<=c[13]): raise ValueError('invalid outstanding counters')
        if direction=='read':
            if c[6]!=c[4] or c[7]!=0: raise ValueError('undrained/inconsistent read bytes')
            if c[5]!=sum(c[25:31])+2*c[31]: raise ValueError('read beat mismatch')
        else:
            if c[5]!=c[3] or c[6]!=0 or c[7]>c[4]: raise ValueError('undrained/inconsistent write bytes')
        d={'id':idx,'op':r['op'],'direction':direction,**dict(zip(NAMES,c))}
        cycles=int(memory[idx]['cycles'])
        if cycles<=0: raise ValueError('invalid timing window')
        d['window_ms']=cycles*1000/clock_hz
        # Counter clear precedes cycle start slightly; use this only as approximate mean.
        d['mean_outstanding_approx']=c[11]/cycles
        d['mean_outstanding_when_busy']=c[11]/c[15] if c[15] else 0
        d['useful_to_tl_ratio']=(c[2] if direction=='read' else c[7])/c[4] if c[4] else None
        for j in [8,9,10,13,14,15,34]: d[NAMES[j].replace('_cycles','_ms')]=c[j]*1000/clock_hz
        result.append(d)
    return result
def main():
    from analyze_timing import analyze
    p=argparse.ArgumentParser();p.add_argument('log',type=Path);p.add_argument('--output',type=Path,required=True)
    a=p.parse_args();r=analyze(a.log.read_text());a.output.parent.mkdir(parents=True,exist_ok=True)
    if 'dma_profile' not in r: raise ValueError('requires profiling ABI log, not legacy estimates')
    a.output.with_suffix('.json').write_text(json.dumps(r,indent=2,ensure_ascii=False)+'\n')
    rows=sorted(r['dma_profile'],key=lambda x:x['window_ms'],reverse=True)
    with a.output.with_suffix('.csv').open('w') as f:
        writer=csv.DictWriter(f,fieldnames=list(rows[0]));writer.writeheader();writer.writerows(rows)
    print(f'correct={r["correct"]}; {len(rows)} DMA rows; saved JSON/CSV; times overlap, not DDR time')
if __name__=='__main__': main()
