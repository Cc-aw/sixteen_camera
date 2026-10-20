#!/usr/bin/env python3
"""Run real C1a functional lanes with checked, immutable build inputs.

Separate host processes preserve physical lane addresses and the original
lane-specific backpressure seed. They do not model shared-memory contention.
"""
import argparse
import json
from pathlib import Path
import shutil
import subprocess
import sys

from candidate_rtl import sha, once


def run(build, commands, memory, output, lanes, enabled, mode, frames=2, last_stage=165):
    manifest = json.loads((build / 'build_manifest.json').read_text())
    for name, digest in manifest['sha256'].items():
        if sha(Path(name)) != digest:
            raise ValueError('Build input changed: ' + name)
    output.mkdir(parents=True, exist_ok=False)
    source = (build / 'csc_gemmini_driver.cpp').read_text()
    replacements = {
        'unsigned lanes=std::stoul(argv[4])': 'unsigned lane_offset=std::stoul(argv[9]); unsigned lanes=std::stoul(argv[4])',
        'if(lane<lanes && command.frame<frames && command.stage<=last_stage)state[lane]':
            'if(lane>=lane_offset && lane<lane_offset+lanes && command.frame<frames && command.stage<=last_stage)state[lane-lane_offset]',
        'std::to_string(i)': 'std::to_string(i+lane_offset)',
        'cycle%11!=i;': 'cycle%11!=i+lane_offset;',
        'cycle,i,s.frame': 'cycle,i+lane_offset,s.frame',
        '<<i<<': '<<i+lane_offset<<',
        'flush_metrics(s,i,': 'flush_metrics(s,i+lane_offset,',
    }
    for old, new in replacements.items():
        if old not in source:
            raise ValueError('Driver adapter changed: ' + old)
        source = source.replace(old, new)
    driver = output / 'selected_lane_driver.cpp'
    driver.write_text(source)
    obj = build / 'obj'
    prefix = Path(sys.executable).resolve().parents[1]
    compiler = shutil.which('x86_64-conda-linux-gnu-c++') or shutil.which('g++')
    objects = [obj / 'VFullGemmini__ALL.a', obj / 'verilated.o', obj / 'verilated_timing.o', obj / 'verilated_threads.o']
    executable = output / 'VFullGemminiSelectedLane'
    compile_command = [compiler, '-O2', '-std=c++17', '-fcoroutines', '-I' + str(obj),
                       '-I' + str(prefix / 'share/verilator/include'), '-I' + str(prefix / 'share/verilator/include/vltstd'),
                       '-I' + str(prefix / 'include'), str(driver), *map(str, objects),
                       '-L' + str(prefix / 'lib'), '-Wl,-rpath,' + str(prefix / 'lib'), '-lz', '-pthread', '-latomic', '-o', str(executable)]
    subprocess.run(compile_command, check=True)
    sources = [Path(__file__).resolve(), driver, executable, commands, build / 'build_manifest.json', *objects]
    sources += sorted(memory.iterdir()) if memory.is_dir() else [memory]
    execution = dict(schema=1, csc_enabled=bool(enabled), dma_load_mode=mode,
                     mode='Independent functional lanes, deterministic private physical-memory services',
                     full_system_performance_model=False, lanes=lanes, frames=frames, last_stage=last_stage,
                     all_rtl_assertions_enabled=True, native_pipeline_watchdog_timeout=60000,
                     compile_command=compile_command, sha256={str(p): sha(p) for p in sources})
    (output / 'execution_manifest.json').write_text(json.dumps(execution, indent=2) + '\n')
    running = []
    for lane in lanes:
        log = (output / f'lane{lane}.log').open('w')
        command = [str(executable), str(commands), str(memory), str(output / f'lane{lane}'), '1',
                   str(frames), str(last_stage), str(enabled), str(mode), str(lane), '+gemmini_timeout=60000']
        process = subprocess.Popen(command, stdout=log, stderr=subprocess.STDOUT)
        running.append((lane, process, log, command))
    results = []
    for lane, process, log, command in running:
        code = process.wait()
        log.close()
        results.append(dict(lane=lane, returncode=code, command=command))
    for name, digest in execution['sha256'].items():
        if sha(Path(name)) != digest:
            raise ValueError('Execution input changed during simulation: ' + name)
    status = 'PASS' if all(r['returncode'] == 0 for r in results) else 'FAIL'
    (output / 'execution_result.json').write_text(json.dumps(dict(status=status, lanes=results), indent=2) + '\n')
    if status != 'PASS':
        raise RuntimeError('C1a functional failure: ' + str(results))
    print('CSC_C1A_FUNCTIONAL_LANES_PASS', lanes, 'enabled', enabled, 'mode', mode)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--build', type=Path, required=True)
    parser.add_argument('--commands', type=Path, required=True)
    parser.add_argument('--memory', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--lanes', default='0,1,2')
    parser.add_argument('--enabled', type=int, choices=(0, 1), required=True)
    parser.add_argument('--mode', type=int, choices=(0, 1, 2, 3), default=2)
    parser.add_argument('--frames', type=int, choices=(1, 2, 3), default=2)
    parser.add_argument('--last-stage', type=int, default=165)
    args = parser.parse_args()
    lanes = list(map(int, args.lanes.split(',')))
    if not lanes or len(set(lanes)) != len(lanes) or any(lane not in range(3) for lane in lanes):
        parser.error('lanes must be distinct physical lanes 0,1,2')
    run(args.build.resolve(), args.commands.resolve(), args.memory.resolve(), args.output.resolve(), lanes,
        args.enabled, args.mode, args.frames, args.last_stage)
