#!/usr/bin/env python3
"""Replay identical checked Get workloads on actual generated L2 bank RTL."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent


def sha(data):
    return hashlib.sha256(data).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    product = json.loads((ROOT / 'hw/manifests/current.json').read_text())
    parser.add_argument('--rtl', type=Path, default=ROOT / product['collateral_directory'])
    parser.add_argument('--output', required=True, type=Path)
    parser.add_argument('--verilator', default=os.environ.get('HEAD_VERILATOR', shutil.which('verilator') or 'verilator'))
    parser.add_argument('--count', type=int, default=512)
    parser.add_argument('--clean-ack-delay', type=int, choices=(0, 1), default=0,
                        help='0: local clean ReleaseAck as in CacheCork; 1: delayed-ACK stress endpoint')
    parser.add_argument('--seeds', type=int, nargs='+', default=[151034, 151035, 151036])
    parser.add_argument('--reuse', action='store_true', help='Reuse only an exactly matching compiled source snapshot')
    args = parser.parse_args()
    rtl = args.rtl.resolve()
    out = args.output.resolve()
    out.mkdir(parents=True, exist_ok=True)
    text = (rtl / 'InclusiveCacheBankScheduler.sv').read_text()
    header = text[text.index('module InclusiveCacheBankScheduler('):]
    header = header[:header.index(');')]
    ports = re.findall(r'^  (input|output)\s+(\[[^\]]+\])?\s*(\w+)\s*[,\t]', header, re.M)
    assert ports and any(name == 'io_in_a_valid' for _, _, name in ports)
    width = next(width for _, width, name in ports if name == 'io_in_a_bits_source')
    bits = int(re.search(r'\[(\d+):0\]', width)[1]) + 1
    bench = f'`timescale 1ns/1ps\nmodule tb_l2_performance;\nlocalparam SOURCE_BITS={bits};\n'
    for direction, width, name in ports:
        bench += f'logic {width or ""} {name}' + ("='0" if direction == 'input' else '') + ';\n'
    bench += 'always #5 clock=~clock;\ninitial reset=1;\nInclusiveCacheBankScheduler dut(\n'
    bench += ',\n'.join(f'.{name}({name})' for _, _, name in ports) + '\n);\n'
    eligible = re.findall(r'wire\s+(_mshr_request_T_\d+)\s*= _mshrs_\d+_io_schedule_valid', text)
    if re.search(r'wire\s+\[33:0\]\s+mshr_request\s*=', text):
        bench += 'wire bench_eligible = |dut.mshr_request;\n'
    else:
        assert len(eligible) == 34, len(eligible)
        bench += 'wire bench_eligible = ' + ' | '.join('dut.' + name for name in eligible) + ';\n'
    bench += '`include "l2_workload.svh"\nendmodule\n'
    target = out / 'tb_l2_performance.sv'
    workload_hash = sha((HERE / 'l2_workload.svh').read_bytes())
    sources = {path.name: sha(path.read_bytes()) for path in sorted(rtl.iterdir())
               if path.suffix in ('.sv', '.v')}
    identity = dict(rtl_sha256=sources, bench_sha256=sha(bench.encode()), workload_sha256=workload_hash)
    compiled = out / 'compiled_sources.json'
    if args.reuse:
        assert compiled.is_file() and json.loads(compiled.read_text()) == identity, 'Compiled sources changed'
    else:
        compiled.unlink(missing_ok=True)
        target.write_text(bench)
        cmd = [args.verilator, '--binary', '--timing', '--assert', '-Wno-fatal', '-j', '4',
               '--top-module', 'tb_l2_performance', '--Mdir', out / 'obj', '-I' + str(HERE),
               '-y', rtl, target, *sorted(rtl.glob('*.top.mems.v'))]
        with (out / 'compile.log').open('w') as log:
            subprocess.run(list(map(str, cmd)), stdout=log, stderr=subprocess.STDOUT, check=True)
        compiled.write_text(json.dumps(identity, indent=2) + '\n')
    results = []
    configurations = [(1, 32, False, args.seeds[0]), (24, 32, False, args.seeds[0])]
    configurations += [(window, 64, True, seed) for window in (24, 96) for seed in args.seeds]
    for window, delay, stalls, seed in configurations:
        cmd = [out / 'obj/Vtb_l2_performance', f'+WINDOW={window}', f'+DELAY={delay}',
               f'+COUNT={args.count}', f'+SEED={seed}', f'+CLEAN_ACK_DELAY={args.clean_ack_delay}'] + (['+STALLS'] if stalls else [])
        result = subprocess.run(list(map(str, cmd)), stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT, text=True)
        log = out / f'count{args.count}_window{window}_delay{delay}_stalls{int(stalls)}_seed{seed}.log'
        log.write_text(result.stdout)
        assert result.returncode == 0 and 'L2_PERF_SCOREBOARD=PASS' in result.stdout, str(log)
        for line in result.stdout.splitlines():
            if line.startswith('L2_PERF '):
                results.append({key: int(value) for key, value in re.findall(r'(\w+)=(\d+)', line)})
    report = dict(rtl=str(rtl), source_bits=bits, workload_sha256=workload_hash,
                  binary_sha256=sha((out / 'obj/Vtb_l2_performance').read_bytes()),
                  compiled_sources_sha256=sha(compiled.read_bytes()), results=results,
                  clean_ack_delay=args.clean_ack_delay,
                  scope='One actual production bank; synthetic Get traffic, not a V33 or board model')
    result_path = out / f'results_count{args.count}.json'
    result_path.write_text(json.dumps(report, indent=2) + '\n')
    (out / 'results.json').write_text(result_path.read_text())
    print(f'L2_PERFORMANCE_SCOREBOARD=PASS scenarios={len(results)} requests_per_scenario={args.count} report={result_path}')


if __name__ == '__main__':
    main()
