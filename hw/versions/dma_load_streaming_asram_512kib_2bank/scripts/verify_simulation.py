#!/usr/bin/env python3
"""Accept only explicit, complete merged-candidate simulation evidence."""
import argparse
import hashlib
import json
from pathlib import Path
import re

FEATURE=Path(__file__).resolve().parents[1]
ROOT=FEATURE.parents[2]


def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--context',type=Path,required=True)
    p.add_argument('--evidence-map',type=Path,required=True)
    p.add_argument('--buffered-context',type=Path,required=True)
    p.add_argument('--output',type=Path,required=True)
    args=p.parse_args();context=json.loads(args.context.read_text());paths=json.loads(args.evidence_map.read_text())
    required={'units','store','tl','first_ddr','first_local','layers','joint','fault_ddr','fault_local','memory','buffered_spad'}
    assert set(paths)==required,(set(paths),required)
    assert context['hardware_variant']==FEATURE.name and context['activation_sram_enabled'] and context['dma_load_streaming_enable']
    for name,digest in context['final_rtl_sha256'].items():assert sha(args.context.parent/'gen-collateral'/name)==digest,name
    expected=context['dma_load_build_id'];evidence={}
    for name,path in paths.items():
        path=Path(path);record=json.loads(path.read_text());status=record['status']
        assert status=='PASS' or status.endswith('_PASS'),(name,status)
        if name not in ('units','store','tl','first_ddr','first_local','buffered_spad'):
            assert record['build_id']==expected,(name,record.get('build_id'),expected)
        if name.startswith('first_'):
            assert Path(record['candidate_rtl']).resolve()==(args.context.parent/'gen-collateral').resolve()
            assert record['runtime_modes']=='all'
        if name=='units':
            for source,digest in record['source_sha256'].items():assert sha(ROOT/source)==digest,source
            log=(path.parent/'streaming.log').read_text()
            rows=re.findall(r'DMA_LOAD_STREAMING_CASE_PASS,local=(true|false),streaming=(true|false),mode=(\d+),c=(\d+),fault=(\d+)',log)
            assert len(rows)==72 and len(set(rows))==72
            assert 'DMA_LOAD_ASSEMBLER_PASS,cases=2975,' in (path.parent/'unit.log').read_text()
            assert 'DMA_STREAM_ASRAM_ADDRESS_PASS,cases=4766,' in (path.parent/'address.log').read_text()
        if name=='store':
            assert set(record['models'])=={'behavioral','vendor'} and all(x['status']=='PASS' for x in record['models'].values())
            assert record['physical_bytes']==0x240000
        if name=='tl':
            log=(path.parent/'simulation.log').read_text()
            assert all(f'cases=589 seed=171016 bank={lane}' in log for lane in range(3))
            for source,digest in record['source_sha256'].items():assert sha(FEATURE/source)==digest
        if name=='joint':assert record['records']==288 and record['lanes']==3
        if name=='layers':
            assert record['modes']==4 and record['lanes']==3 and len(record['stages'])==8
            trace=json.loads((path.parent/'trace_evidence.json').read_text())
            assert trace['status']=='ROW_TRACE_GET_CLOSURE_PASS' and len(trace['results'])==96
            for source,digest in trace['sha256'].items():assert sha(Path(source))==digest

        if name=='buffered_spad':
            controls=json.loads(args.buffered_context.read_text())
            assert controls['effective_scala']==context['effective_scala']
            assert controls['build_sbt_sha256']==context['build_sbt_sha256']
            assert record['build_id']==controls['dma_load_build_id'] and not controls['dma_load_streaming_enable'] and controls['activation_sram_enabled']
            assert record['parameter_cases']==1 and record['modes']==4 and record['lanes']==3
            assert 'early_sram_writes=0' in (path.parent/'result.log').read_text()
        log_digest=record.get('log_sha256')
        if log_digest:
            candidates=[path.parent/x for x in ('result.log','simulation.log','simulation/result.log')]
            assert any(x.is_file() and sha(x)==log_digest for x in candidates),name+' log hash'
        evidence[name]=dict(path=str(path),sha256=sha(path),status=status)
        if name=='layers':evidence[name]['trace']=dict(path=str(path.parent/'trace_evidence.json'),sha256=sha(path.parent/'trace_evidence.json'))
    joint_log=(Path(paths['joint']).parent/'simulation/result.log').read_text()
    profile_by_lane={};stream_traffic={};all_keys=set()
    for line in joint_log.splitlines():
        if 'ASRAM_REAL_LANE_PASS,' in line:
            f=dict(re.findall(r'(\w+)=(\d+)',line));profile_by_lane[int(f['lane'])]=int(f['profile'])
        if 'DMA_SPAD_PASS,' in line:
            f=dict(re.findall(r'(\w+)=(\d+)',line));lane=int(f['lane'])
            key=(profile_by_lane[lane],int(f['mode']),int(f['case']),lane)
            assert key not in all_keys,'Duplicate route/mode/case/lane'
            all_keys.add(key)
            if profile_by_lane[lane]==0:
                stream_traffic[lane,int(f['mode']),int(f['case'])]=(int(f['sram_writes']),int(f['dma_gets']))
    assert all_keys=={(p,m,c,l) for p in range(4) for m in range(4) for c in range(6) for l in range(3)}
    buffered=json.loads(Path(paths['buffered_spad']).read_text())
    for row in buffered['traffic']:
        assert stream_traffic[row['lane'],row['mode'],row['case']]==(row['sram_writes'],row['dma_gets'])
    for name in ('DmaLoadGroup.sv','DmaLoadRowAssembler.sv'):
        literal_widths=[int(x) for x in re.findall(r"\b(\d+)'[hbd]",(args.context.parent/'gen-collateral'/name).read_text())]
        assert max(literal_widths)<4096,'Unexpected unbounded shift: '+name
    report=dict(status='MERGED_FUNCTIONAL_SIMULATION_PASS',hardware_build_id=expected,
                generation_context=str(args.context),generation_context_sha256=sha(args.context),buffered_context=str(args.buffered_context),buffered_context_sha256=sha(args.buffered_context),evidence=evidence,
                board_accessed=False,bitstream='NOT_GENERATED',synthesis='NOT_RUN',timing='NOT_MEASURED',
                scope='Complete defined feature regression matrix; real three-DIM32 candidate RTL and Xilinx functional primitives. Compact layers, not full-network RTL or Rocket/Saturn instruction execution.',
                full_model_rtl_executed=False,cpu_rvv_rtl_executed=False,
                buffered_streaming_work_equal='C3/N32/P6, four modes, three lanes: TL Gets and physical SPAD writes identical; no performance claim')
    args.output.parent.mkdir(parents=True,exist_ok=True);args.output.write_text(json.dumps(report,indent=2)+'\n')
    print('MERGED_FUNCTIONAL_SIMULATION_PASS hardware_id='+expected)


if __name__=='__main__':main()
