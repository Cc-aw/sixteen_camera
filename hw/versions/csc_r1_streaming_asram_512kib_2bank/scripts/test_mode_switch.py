#!/usr/bin/env python3
"""Isolate real mode-change invalidation at drained native boundaries.

Frames are relabelled into one epoch and the test suppresses DRAIN clearing.
Changing input fixtures at the mode boundary then requires the RTL's mode
invalidation itself. This is a directed test, not a production clear policy.
"""
import argparse
import json
from pathlib import Path
import sys

from candidate_rtl import sha, once
from run_candidate import run

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'analysis'))
from compare_candidate import compare


def test(build,fixture,output,start):
    output.mkdir(parents=True,exist_ok=False)
    identity=json.loads((build/'build_manifest.json').read_text())
    for name,digest in identity['sha256'].items():
        if sha(Path(name))!=digest: raise ValueError('Build input changed: '+name)
    original=build/'csc_gemmini_driver.cpp'
    source=once(original.read_text(),'d.io_dma_load_mode=mode;',
        'd.io_dma_load_mode=(mode+(s.stage>=2?s.stage-2:0))%4;')
    source=once(source,'d.csc_clear=c.funct!=253 || c.frame!=s.frame;',
        'd.csc_clear=c.funct==254; // Test-only isolation of MODE invalidation')
    view=output/'model_view'
    view.mkdir()
    driver=view/'csc_gemmini_driver.cpp'
    driver.write_text(source)
    (view/'obj').symlink_to(build/'obj',target_is_directory=True)
    identity.update(status='C1A_OBSERVATIONAL_DRIVER_ADAPTER',
        original_rtl_build=str(build),rtl_archive_unchanged=True,
        driver_adaptation='Modes change between drained stages; DRAIN/frame clearing suppressed only in this test')
    identity['sha256'].update({str(driver):sha(driver),str(Path(__file__).resolve()):sha(Path(__file__).resolve()),
        str(build/'build_manifest.json'):sha(build/'build_manifest.json')})
    (view/'build_manifest.json').write_text(json.dumps(identity,indent=2)+'\n')
    commands=output/'commands.txt'
    rows=[]
    for line in (fixture/'commands.txt').read_text().splitlines():
        row=list(map(int,line.split()));row[1]=0;rows.append(row)
    commands.write_text(''.join(' '.join(map(str,row))+'\n' for row in rows))
    (output/'test_policy.json').write_text(json.dumps(dict(schema=1,start_mode=start,
        stages=[2,3,4],modes=[(start+i)%4 for i in range(3)],production_policy_changed=False,
        purpose='Mode is the only invalidation across different data at one physical source address'),indent=2)+'\n')
    for enabled,label in ((0,'off'),(1,'on')):
        run(view,commands,fixture/'memory',output/label,[0,1,2],enabled,start,frames=1,last_stage=4)
    results=[]
    for lane in range(3):
        result=compare(output/f'off/lane{lane}/full_lane{lane}.csv.gz',
            output/f'on/lane{lane}/full_lane{lane}.csv.gz',output/f'comparison_lane{lane}')
        if result['candidate']['tiles']!=12 or result['candidate']['skipped']!=9:
            raise ValueError('Mode invalidation failed cold/warm request accounting')
        results.append(result['status'])
    (output/'result.json').write_text(json.dumps(dict(schema=1,status='PASS',lanes=results,
        sha256={str(p):sha(p) for p in [Path(__file__).resolve(),commands,output/'test_policy.json',
            view/'build_manifest.json',fixture/'fixture.json']}),indent=2)+'\n')
    print('CSC_REAL_MODE_SWITCH_INVALIDATION_PASS',start)


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--build',type=Path,required=True)
    parser.add_argument('--fixture',type=Path,required=True)
    parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--start-mode',type=int,choices=(0,2),required=True)
    args=parser.parse_args()
    test(args.build.resolve(),args.fixture.resolve(),args.output.resolve(),args.start_mode)
