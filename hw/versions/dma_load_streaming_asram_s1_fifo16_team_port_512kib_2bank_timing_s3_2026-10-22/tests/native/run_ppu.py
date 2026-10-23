#!/usr/bin/env python3
"""Execute the candidate's actual PPU on full native six-head dumps."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'scripts'))
from common import sha


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--heads',type=Path,nargs='+',required=True)
    parser.add_argument('--jobs',type=int,default=4)
    args=parser.parse_args();out=args.output.resolve()
    if ROOT/'build' not in out.parents:raise ValueError('Use a fresh candidate build output')
    heads=[p.resolve() for p in args.heads]
    if any(p.stat().st_size!=907200 for p in heads):raise ValueError('Require all 907200 raw head bytes')
    if out.exists():
        # Reuse only completed, immutable evidence for these exact six tensors
        # and current candidate RTL. Never replace a partial/running output.
        evidence=json.loads((out/'evidence.json').read_text())
        if evidence['status']!='PASS' or len(evidence['results'])!=len(heads):
            raise ValueError('Existing output is not a completed matching PPU run')
        for name,digest in evidence['source_sha256'].items():
            frozen=out/name
            current=(Path(__file__) if frozen.name=='run_ppu.py' else
                Path(__file__).with_name('tb_raw_heads.sv') if frozen.name=='tb_raw_heads.sv' else
                ROOT/'board/rtl/ai/postprocess'/frozen.relative_to(out/'sources'))
            if sha(frozen)!=digest or sha(current)!=digest:raise ValueError('PPU source changed: '+name)
        if sha(out/'obj/Vtb_raw_heads')!=evidence['executable_sha256']:raise ValueError('PPU executable changed')
        for index,(path,result) in enumerate(zip(heads,evidence['results'])):
            if str(path)!=result['heads'] or sha(path)!=result['heads_sha256']:
                raise ValueError('Different raw-head input')
            actual=out/f'result{index}.txt';log=out/f'run{index}.log'
            if (sha(actual)!=result['result_sha256'] or actual.read_text().splitlines()!=result['result'] or
                log.read_text()!=result['log'] or 'S1_RAW_HEAD_PPU_PASS' not in result['log']):
                raise ValueError('PPU result/log changed')
        print('S1_NATIVE_PPU_REUSE_VERIFIED',out,flush=True)
        return
    out.mkdir(parents=True,exist_ok=False)
    rtl=ROOT/'board/rtl/ai/postprocess'
    # Freeze the entire PPU closure; no production/root experimental files used.
    snapshot=out/'sources';shutil.copytree(rtl,snapshot)
    bench=Path(__file__).with_name('tb_raw_heads.sv');shutil.copyfile(bench,snapshot/bench.name)
    shutil.copyfile(Path(__file__),snapshot/'run_ppu.py')
    modules=['yolov5nu_raw_class_lut','yolov5nu_dfl_lut','yolov5nu_class_fold_tree',
        'yolov5nu_class_reducer_wide','yolov5nu_class_reducer','yolov5nu_probability_pipeline',
        'yolov5nu_dfl_edge','yolov5nu_dfl_decoder','yolov5nu_bbox_decoder','yolov5nu_topk_nms',
        'ppu_perf_counters','yolov5nu_candidate_buckets','yolov5nu_nms','yolov5nu_candidate_area',
        'yolov5nu_iou_pipeline','yolov5nu_bucket_nms','yolov5nu_bbox_lut',
        'yolov5nu_bbox_pipeline','yolov5nu_postprocessor']
    command=[os.environ.get('VERILATOR','verilator'),'--binary','--timing','--assert','-Wno-fatal',
        '--build-jobs',str(args.jobs),'--Mdir',str(out/'obj'),'--top-module','tb_raw_heads',
        *[str(snapshot/(m+'.sv')) for m in modules],str(snapshot/bench.name)]
    with (out/'compile.log').open('w') as log:
        subprocess.run(command,stdout=log,stderr=subprocess.STDOUT,check=True)
    outputs=[]
    for index,path in enumerate(heads):
        raw=path.read_bytes();memory=out/f'heads{index}.mem';result=out/f'result{index}.txt'
        memory.write_text(''.join(f'{v:02x}\n' for v in raw))
        with (out/f'run{index}.log').open('w') as log:
            subprocess.run([str(out/'obj/Vtb_raw_heads'),'+heads='+str(memory),'+result='+str(result)],
                stdout=log,stderr=subprocess.STDOUT,check=True)
        if 'S1_RAW_HEAD_PPU_PASS' not in (out/f'run{index}.log').read_text():raise ValueError('Missing PPU completion')
        outputs.append(dict(heads=str(path),heads_sha256=sha(path),result_sha256=sha(result),
            result=result.read_text().splitlines(),log=(out/f'run{index}.log').read_text()))
    evidence=dict(status='PASS',actual_candidate_ppu=True,raw_head_bytes=907200,results=outputs,
        source_sha256={str(p.relative_to(out)):sha(p) for p in snapshot.rglob('*') if p.is_file()},
        executable_sha256=sha(out/'obj/Vtb_raw_heads'),compile_command=command,board_validation='NOT_RUN')
    (out/'evidence.json').write_text(json.dumps(evidence,indent=2)+'\n')
    print('S1_NATIVE_PPU_PASS',out,flush=True)


if __name__=='__main__':main()
