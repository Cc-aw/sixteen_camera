#!/usr/bin/env python3
"""Four modes x three lanes x DDR/local/mixed, real Gemmini + ASRAM primitive."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys

FEATURE=Path(__file__).resolve().parents[1]


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--rtl',type=Path,required=True)
    p.add_argument('--output',type=Path,required=True)
    p.add_argument('--fault',action='store_true')
    p.add_argument('--verify-only',action='store_true',help='Recheck complete saved candidate simulation without rerunning it')
    args=p.parse_args();out=args.output.resolve()
    if not args.verify_only:
        out.mkdir(parents=True,exist_ok=False)
        if args.fault:
            source=(FEATURE/'tests/test_fault.py').read_text()
        else:
            source=(FEATURE/'tests/test_spad.py').read_text()
            anchor="    mode_count=len(json.loads((args.rtl.resolve().parent/'GENERATION_CONTEXT.json').read_text())['dma_load_supported_modes'])"
            # There are two identical workload bookkeeping occurrences; expand only
            # the main body's final occurrence after the SV body has been composed.
            pos=source.rindex(anchor)
            source=source[:pos]+'''    body=body.replace('    for(runtime_mode=0;', '    for(integer profile=0;profile<4;profile=profile+1)begin\\n      lanes[0].lane.storage_profile=profile;lanes[1].lane.storage_profile=profile;lanes[2].lane.storage_profile=profile;\\n    for(runtime_mode=0;')
        body=body.replace('    $display("REAL_CLUSTER_PASS,DMA_SPAD', '    end\\n    $display("REAL_CLUSTER_PASS,DMA_SPAD')
    '''+source[pos:]
            # A repeated profile/mode/case is intentional here; this runner checks
            # its expanded key matrix below instead of the original DDR-only parser.
            source=source.replace('\n    write_evidence(out,args.rtl,args.matrix,args.case)\n','\n')
        source=source.replace('ROOT=Path(__file__).resolve().parents[4]',f'ROOT=Path({str(FEATURE.parents[2])!r})')
        source=source.replace("(Path(__file__).parent/'test_real_gemmini.py')",f"(Path({str(FEATURE/'tests')!r})/'test_real_gemmini.py')")
        script=out/'driver.py';script.write_text(source)
        command=[sys.executable,str(script),'--rtl',str(args.rtl.resolve()),'--output',str(out/'simulation')]
        if not args.fault:command+=['--matrix']
        subprocess.run(command,env=dict(os.environ,STREAM_ASRAM_SIM='1',STREAM_ASRAM_COMPACT='fault' if args.fault else '1'),check=True)
    log=(out/'simulation/result.log').read_text()
    assert not re.search('Fatal:|Error:|Assertion failed:',log)
    marker='REAL_CLUSTER_PASS,DMA_FAULT=1,kinds=2,lanes=3' if args.fault else 'REAL_CLUSTER_PASS,DMA_SPAD=1,modes=4,lanes=3'
    assert log.count(marker)==1 and '-1^exit' in log,'Incomplete simulation session'
    context=json.loads((args.rtl.resolve().parent/'GENERATION_CONTEXT.json').read_text())
    project=(out/'simulation/simulation.prj').read_text()
    compiled=[Path(x) for x in re.findall(r'"([^"]+)"',project)]
    assert args.rtl.resolve()/'Gemmini.sv' in compiled
    for path in compiled:
        if path.is_relative_to(args.rtl.resolve()):
            assert hashlib.sha256(path.read_bytes()).hexdigest()==context['final_rtl_sha256'][str(path.relative_to(args.rtl.resolve()))]

    if args.fault:
        assert log.count('DMA_FAULT_HOLD_PASS,')==2
        assert log.count('DMA_FAULT_RECOVERY_PASS,')==2
        status='REAL_GEMMINI_ASRAM_LATE_FAULT_RECOVERY_PASS'
        matrix=6
    else:
        rows=re.findall(r'ASRAM_REAL_LANE_PASS,lane=(\d+),profile=(\d+)',log)
        assert len(rows)==4*4*6*3,(len(rows),log[-2000:])
        assert all(rows.count((str(lane),str(profile)))==24 for lane in range(3) for profile in range(4))
        assert log.count('DMA_SPAD_PASS,')==4*4*6*3
        assert log.count('DMA_STREAMING_SPAD_PASS,')==4*3*2*3
        profiles={};keys=set()
        for line in log.splitlines():
            if 'ASRAM_REAL_LANE_PASS,' in line:
                f=dict(re.findall(r'(\w+)=(\d+)',line));profiles[int(f['lane'])]=int(f['profile'])
            if 'DMA_SPAD_PASS,' in line:
                f=dict(re.findall(r'(\w+)=(\d+)',line));key=(profiles[int(f['lane'])],int(f['mode']),int(f['case']),int(f['lane']))
                assert key not in keys,'Duplicate route/mode/case/lane'
                keys.add(key)
        assert keys=={(p,m,c,l) for p in range(4) for m in range(4) for c in range(6) for l in range(3)}

        status='REAL_GEMMINI_ASRAM_FOUR_ROUTES_PASS';matrix=len(rows)
    (out/'evidence.json').write_text(json.dumps(dict(status=status,build_id=context['dma_load_build_id'],
       lanes=3,records=matrix,vendor_primitive_simulated=True,full_model_executed=False,
       cpu_rvv_executed=False,scope='Actual generated Gemmini/Reader/ASRAM TL, two-port storage and URAM primitives; simulation decoder/arbiter, not whole-SoC CPU execution.',
       log_sha256=hashlib.sha256(log.encode()).hexdigest()),indent=2)+'\n')
    print(status)


if __name__=='__main__':main()
