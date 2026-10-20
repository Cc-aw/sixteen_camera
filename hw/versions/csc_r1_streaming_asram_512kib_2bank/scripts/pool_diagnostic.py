#!/usr/bin/env python3
"""Isolate frozen stage 75 with an explicit native watchdog plusarg.

This relinks the exact built RTL archive; only the host CLI accepts additional
Verilator plusargs. No RTL assertion or hardware watchdog is removed.
"""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys


def run(build, commands, memory, output, timeout):
    output.mkdir(parents=True, exist_ok=False)
    original = build / 'full_gemmini_driver.cpp'
    source = original.read_text()
    if source.count('if(argc!=7)') != 1:
        raise ValueError('Unexpected pinned driver CLI')
    driver = output / 'plusarg_driver.cpp'
    driver.write_text(source.replace('if(argc!=7)', 'if(argc<7)'))
    subset = output / 'commands.txt'
    rows = []
    for line in commands.read_text().splitlines():
        lane, frame, stage, *_ = map(int, line.split())
        if lane == frame == 0 and stage == 75:
            rows.append(line)
    if len(rows) != 71:
        raise ValueError('Frozen memory stage command count changed')
    subset.write_text('\n'.join(rows) + '\n')
    prefix = Path(sys.executable).resolve().parents[1]
    obj = build / 'obj'
    objects = [obj / 'VFullGemmini__ALL.a', obj / 'verilated.o', obj / 'verilated_timing.o', obj / 'verilated_threads.o']
    executable = output / 'VFullGemminiPlusarg'
    command = [shutil.which('x86_64-conda-linux-gnu-c++') or shutil.which('g++'), '-O2', '-std=c++17', '-fcoroutines',
               '-I' + str(obj), '-I' + str(prefix / 'share/verilator/include'), '-I' + str(prefix / 'share/verilator/include/vltstd'),
               '-I' + str(prefix / 'include'), str(driver), *map(str, objects),
               '-L' + str(prefix / 'lib'), '-Wl,-rpath,' + str(prefix / 'lib'), '-lz', '-pthread', '-latomic', '-o', str(executable)]
    subprocess.run(command, check=True)
    inputs = [original, driver, executable, subset, memory, *objects]
    (output / 'execution_manifest.json').write_text(json.dumps(dict(schema=1, timeout=timeout,
        compile_command=command, all_rtl_assertions_enabled=True,
        sha256={str(p): hashlib.sha256(p.read_bytes()).hexdigest() for p in inputs}), indent=2) + '\n')
    with (output / 'simulation.log').open('w') as log:
        subprocess.run([str(executable), str(subset), str(memory), str(output / 'trace'), '1', '1', '165',
                        '+gemmini_timeout=' + str(timeout)], stdout=log, stderr=subprocess.STDOUT, check=True)
    print('POOL75_NATIVE_ISOLATION_PASS', timeout)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--build', type=Path, required=True)
    parser.add_argument('--commands', type=Path, required=True)
    parser.add_argument('--memory', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--timeout', type=int, choices=(10000, 60000), required=True)
    args = parser.parse_args()
    run(args.build.resolve(), args.commands.resolve(), args.memory.resolve(), args.output.resolve(), args.timeout)
