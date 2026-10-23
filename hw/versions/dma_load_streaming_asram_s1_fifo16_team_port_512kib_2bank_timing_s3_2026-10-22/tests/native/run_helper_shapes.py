#!/usr/bin/env python3
"""Run the real DirectA helper tails against full original-S1 layer outputs.

Source tensors come from native F0 stage0..12, with frozen image025/weights.
Only the isolated layer's number of rows changes; mathematical code is frozen.
"""
import argparse
from concurrent.futures import ThreadPoolExecutor
import json
import os
from pathlib import Path
import shutil
import struct
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'scripts'))
from common import sha

SHAPES=(1,31,32,33,511,512,513,1023,1024,1025)
BASE=0x90000000
OUTPUT=BASE+614400


def verify_build(build):
    manifest=json.loads((build/'build_manifest.json').read_text())
    if manifest['status']!='PASS':raise ValueError('Incomplete native build')
    for name,digest in manifest['sha256'].items():
        if sha(Path(name))!=digest:raise ValueError('Changed native input: '+name)
    executable=build/'obj/VS1TeamReplay'
    if sha(executable)!=manifest['executable_sha256']:raise ValueError('Changed executable')
    return executable


def record(address,data):
    return struct.pack('<QI',address,len(data))+data


def run(executable,folder,cycles=10000000):
    command=[str(executable),str(folder/'table.txt'),str(folder/'memory.bin'),
        str(cycles),'7',str(folder/'summary.txt'),str(folder/'outputs.txt'),'+gemmini_timeout=60000']
    (folder/'command.json').write_text(json.dumps(command,indent=2)+'\n')
    with (folder/'run.log').open('w') as log:
        subprocess.run(command,stdout=log,stderr=subprocess.STDOUT,check=True)
    if 'S1_TEAM_REPLAY_PASS' not in (folder/'summary.txt').read_text():
        raise ValueError('Missing native completion')


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--baseline-build',type=Path,required=True)
    parser.add_argument('--candidate-build',type=Path,required=True)
    parser.add_argument('--workload',type=Path,required=True)
    parser.add_argument('--gold',type=Path,required=True)
    parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args();out=args.output.resolve();workload=args.workload.resolve()
    if ROOT/'build' not in out.parents:raise ValueError('Use a fresh candidate build output')
    original=verify_build(args.baseline_build.resolve())
    candidate=verify_build(args.candidate_build.resolve())
    capture=json.loads((workload/'workload.json').read_text())
    snapshot=workload/capture['source_snapshot']
    for name,digest in capture['sha256'].items():
        if sha(workload/name)!=digest:raise ValueError('Changed capture: '+name)
    for name,digest in {**capture['sources_sha256'],**capture['generated_sha256']}.items():
        if sha(snapshot/name)!=digest:raise ValueError('Changed frozen source: '+name)
    gold=args.gold.resolve().read_bytes()
    if len(gold)!=614400:raise ValueError('Require original complete stage14 gold')
    out.mkdir(parents=True,exist_ok=False)
    shutil.copyfile(Path(__file__),out/'runner.py')
    state=dict(status='RUNNING',source='F0 actual image025 prefix0..12, frozen weights',
        source_workload=str(workload),gold=str(args.gold.resolve()),gold_sha256=sha(args.gold.resolve()),
        original_executable_sha256=sha(original),candidate_executable_sha256=sha(candidate),
        helper_sha256=sha(snapshot/'model/s1_direct_a32.inc'),rows=list(SHAPES),panels=[512,1024])
    (out/'evidence.json').write_text(json.dumps(state,indent=2)+'\n')
    prefix=out/'prefix';prefix.mkdir()
    commands=[line for line in (workload/'table.txt').read_text().splitlines() if int(line.split()[0])<=12]
    (prefix/'table.txt').write_text('\n'.join(commands)+'\n12 255 0 0\n')
    shutil.copyfile(workload/'memory.bin',prefix/'memory.bin')
    (prefix/'outputs.txt').write_text(f'source0 {BASE} 307200\nsource1 {BASE+307200} 307200\n')
    run(original,prefix)
    sources=[(prefix/f'summary.txt.source{i}.bin').read_bytes() for i in range(2)]
    if any(len(p)!=307200 for p in sources):raise ValueError('Incomplete real prefix tensors')
    state['prefix_source_sha256']={str(i):sha(prefix/f'summary.txt.source{i}.bin') for i in range(2)}
    compilers={}
    for panel in (512,1024):
        directory=out/f'panel{panel}';directory.mkdir()
        source=snapshot
        flags=[f for f in capture['compile_flags'] if not f.startswith('-DS1_DIRECT_PANEL_ROWS=')]
        flags.append('-DS1_DIRECT_PANEL_ROWS='+str(panel))
        if panel==512:
            source=directory/'source_snapshot';shutil.copytree(snapshot,source)
            with (directory/'prepare.log').open('w') as log:
                subprocess.run(['python3',str(source/'scripts/prepare_yolo.py')],check=True,
                    env=dict(os.environ,S1_DIRECT_LAYERS='model2',S1_DIRECT_PANEL_ROWS='512',
                        S1_DIRECT_DRAIN_EACH_PANEL='0'),stdout=log,stderr=subprocess.STDOUT)
        text=(source/'scripts/native_capture.c').read_text()
        text=text.replace('last>165','last>19200')
        start=text.index('    for(current_phase=0;current_phase<165')
        end=text.index('    uint64_t cursor=',start)
        text=text[:start]+'''    current_phase=14;
    yolo32_packed_silu_lut(packed_silu_luts[6]);at_drain();
    const struct yolo32_ws_binding *b=&batch_ws_bindings[0][1];
    if(!s1_direct_a32_emit(b->base[0],b->base[1],b->base[4],b->base[6],
        (elem_t *)b->base[8],last,last*16,last*16,
        (uint16_t)(prepared_ws_configs[8][0]>>32),
        (uint16_t)(prepared_ws_configs[2][0]>>32)))return 5;
    at_drain();planning=0;
'''+text[end:]
        harness=directory/'capture.c';harness.write_text(text)
        includes=[source/'src',source/'build/yolo_generated',source/'build/yolo_generated/include',
            source/'include',source/'build/generated',source/'model',source/'model/include']
        command=[os.environ.get('HOST_CC','cc'),*flags,'-DACTIVATION_MEMORY_HOST_TEST',
            *['-I'+str(p) for p in includes],'-include',str(source/'include/config.h'),str(harness),
            str(source/'src/activation_memory.c'),str(source/'model/inputs.c'),'-Wl,--gc-sections',
            '-lm','-o',str(directory/'capture')]
        (directory/'compile_command.json').write_text(json.dumps(command,indent=2)+'\n')
        with (directory/'compile.log').open('w') as log:
            subprocess.run(command,stdout=log,stderr=subprocess.STDOUT,check=True)
        compilers[panel]=directory/'capture'

    def case(item):
        panel,rows=item;folder=out/f'panel{panel}'/f'rows{rows}';folder.mkdir()
        with (folder/'capture.log').open('w') as log:
            subprocess.run([str(compilers[panel]),'0','1','0',str(rows),str(folder/'table.txt'),
                str(folder/'memory.bin')],check=True,stdout=log,stderr=subprocess.STDOUT)
        with (folder/'memory.bin').open('ab') as memory:
            memory.write(record(OUTPUT,bytes([0x55])*(614400+64)))
            memory.write(record(BASE,sources[0]));memory.write(record(BASE+307200,sources[1]))
        (folder/'outputs.txt').write_text(f'result {OUTPUT} {rows*32}\n'
            f'guard_before {OUTPUT-64} 64\nguard_after {OUTPUT+rows*32} 64\n')
        run(candidate,folder,2000000)
        result=(folder/'summary.txt.result.bin').read_bytes()
        if result!=gold[:rows*32]:raise ValueError('Tail numerical mismatch: '+str(item))
        if ((folder/'summary.txt.guard_before.bin').read_bytes()!=sources[1][-64:] or
            (folder/'summary.txt.guard_after.bin').read_bytes()!=bytes([0x55])*64):
            raise ValueError('Tail guard overwritten: '+str(item))
        return dict(panel=panel,rows=rows,bytes=len(result),differing_bytes=0,guards='PASS',
            output_sha256=sha(folder/'summary.txt.result.bin'),
            input_sha256={n:sha(folder/n) for n in ('table.txt','memory.bin','outputs.txt')},
            summary=(folder/'summary.txt').read_text())
    with ThreadPoolExecutor(max_workers=4) as pool:
        results=list(pool.map(case,[(p,n) for p in (512,1024) for n in SHAPES]))
    state.update(status='PASS',results=results,all_tail_guards_checked=True,native_helper_executed=True,
        board_validation='NOT_RUN',full_graph_executed=False)
    (out/'evidence.json').write_text(json.dumps(state,indent=2)+'\n')
    shutil.copyfile(out/'evidence.json',ROOT/'validation/native_helper_shapes.json')
    print('S1_NATIVE_HELPER_SHAPES_PASS cases=20 real_prefix_inputs=1 tails=all guards=all',flush=True)


if __name__=='__main__':main()
