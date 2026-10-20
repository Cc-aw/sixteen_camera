#!/usr/bin/env python3
"""Run independent functional C0 lanes on separate CPU processes.

The full harness has private deterministic physical-memory services. Independent
processes preserve its per-lane clock/backpressure schedule and physical address
identity; this is not a shared-memory performance experiment.
"""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys

FEATURE = Path(__file__).resolve().parents[1]


def run(build, commands, memory, output, lanes, timeout=60000):
    output.mkdir(parents=True, exist_ok=False)
    manifest = json.loads((build / 'build_manifest.json').read_text())
    for name, digest in manifest['sha256'].items():
        if hashlib.sha256(Path(name).read_bytes()).hexdigest() != digest:
            raise ValueError('C0 build input changed: ' + name)
    source = (build / 'full_gemmini_driver.cpp').read_text()
    replacements = {
        'if(argc!=7)': 'if(argc<7)',
        'unsigned lanes=std::stoul(argv[4])': 'unsigned lane_offset=argc>=8?std::stoul(argv[7]):0; unsigned lanes=std::stoul(argv[4])',
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
            raise ValueError('Driver adapter no longer matches: ' + old)
        source = source.replace(old, new)
    driver = output / 'selected_lane_driver.cpp'
    driver.write_text(source)
    obj = build / 'obj'
    prefix = Path(sys.executable).resolve().parents[1]
    compiler = shutil.which('x86_64-conda-linux-gnu-c++') or shutil.which('g++')
    objects = [obj / 'VFullGemmini__ALL.a', obj / 'verilated.o', obj / 'verilated_timing.o', obj / 'verilated_threads.o']
    executable = output / 'VFullGemminiSelectedLane'
    command = [compiler, '-O2', '-std=c++17', '-fcoroutines', '-I' + str(obj),
               '-I' + str(prefix / 'share/verilator/include'), '-I' + str(prefix / 'share/verilator/include/vltstd'),
               '-I' + str(prefix / 'include'), str(driver), *map(str, objects),
               '-L' + str(prefix / 'lib'), '-Wl,-rpath,' + str(prefix / 'lib'), '-lz', '-pthread', '-latomic', '-o', str(executable)]
    subprocess.run(command, check=True)
    sources = [Path(__file__), driver, executable, commands, memory, build / 'build_manifest.json', *objects]
    (output / 'execution_manifest.json').write_text(json.dumps(dict(schema=1,
        mode='Independent functional lanes; no shared-memory timing/performance model', lanes=lanes,
        native_pipeline_watchdog_timeout=timeout, all_rtl_assertions_enabled=True,
        compile_command=command,
        sha256={str(p): hashlib.sha256(p.read_bytes()).hexdigest() for p in sources}), indent=2) + '\n')
    running = []
    for lane in lanes:
        log = (output / f'lane{lane}.log').open('w')
        p = subprocess.Popen([str(executable), str(commands), str(memory), str(output / f'lane{lane}'), '1', '2', '165', str(lane),
                              '+gemmini_timeout=' + str(timeout)],
                             stdout=log, stderr=subprocess.STDOUT)
        running.append((lane, p, log))
    errors = []
    for lane, process, log in running:
        code = process.wait()
        log.close()
        if code:
            errors.append((lane, code))
    if errors:
        raise RuntimeError('Functional lane failure: ' + str(errors))
    print('INDEPENDENT_FULL_FUNCTIONAL_LANES_COMPLETE', lanes)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--build', type=Path, required=True)
    parser.add_argument('--commands', type=Path, required=True)
    parser.add_argument('--memory', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--lanes', default='0,1,2')
    parser.add_argument('--timeout', type=int, choices=(10000, 60000), default=60000)
    args = parser.parse_args()
    run(args.build.resolve(), args.commands.resolve(), args.memory.resolve(), args.output.resolve(),
        list(map(int, args.lanes.split(','))), args.timeout)
