#!/usr/bin/env python3
"""Compare actual-router legacy/H1 DDR latency and check every response."""
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


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--router', type=Path, default=ROOT / 'hw/rtl/ai/postprocess/axi4_head_uram_router_v3.sv')
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--verilator', default=os.environ.get('HEAD_VERILATOR', shutil.which('verilator') or 'verilator'))
    parser.add_argument('--extra-latency', type=int, default=2,
                        help='Expected H1 isolated-read latency over legacy (3 for f0da4cc)')
    args = parser.parse_args()
    out = args.output.resolve()
    out.mkdir(parents=True, exist_ok=True)
    source = ROOT / 'tests/rtl/head_l2_urgent/tb_head_router_ordering.sv'
    bench = source.read_text()
    supports_h1 = bool(re.search(r'parameter\s+bit\s+READ_DECOUPLE', args.router.read_text()))
    if not supports_h1:
        bench = bench.replace(',\n        .SLOT_BYTES(4096),.READ_DECOUPLE(READ_DECOUPLE)', ',\n        .SLOT_BYTES(4096)')
        bench = bench.replace(',.READ_DECOUPLE(READ_DECOUPLE)', '')
        bench = bench.replace('dut.head_active', "(dut.read_state == 3'd2)")
    anchor = '    integer start_completed, start_addresses, old_local_early;'
    assert bench.count(anchor) == 1
    bench = bench.replace(anchor, '`include "head_probe_state.svh"\n' + anchor)
    condition = 'allow_return[pick] && dw[pick]>dr[pick]'
    assert bench.count(condition) == 1
    bench = bench.replace(condition, condition + ' && probe_cycle-probe_issue[pick][dr[pick]%64]>=probe_delay')
    anchor = '        for(integer b=0;b<6;b++) for(integer w=0;w<WORDS;w++) write_word'
    assert bench.count(anchor) == 1
    bench = bench.replace(anchor, '`include "head_probe_workload.svh"\n' + anchor)
    target = out / 'tb_ddr_probe.sv'
    target.write_text(bench)
    results = []
    for decouple in ((0, 1) if supports_h1 else (0,)):
        dest = out / f'obj_{decouple}'
        cmd = [args.verilator, '--binary', '--timing', '--assert', '-Wno-fatal', '-j', '4',
               '--top-module', 'tb_head_router_ordering', f'-GREAD_DECOUPLE={decouple}',
               '--Mdir', dest, '-I' + str(HERE), ROOT / 'hw/rtl/interfaces/axi4_if.sv',
               ROOT / 'hw/rtl/ai/postprocess/head_uram_store.sv', args.router.resolve(), target]
        with (out / f'compile_{decouple}.log').open('w') as log:
            subprocess.run(list(map(str, cmd)), stdout=log, stderr=subprocess.STDOUT, check=True)
        for delay in (0, 16, 64):
            cmd = [dest / 'Vtb_head_router_ordering', '+DDR_PROBE', f'+DELAY={delay}']
            result = subprocess.run(list(map(str, cmd)), stdout=subprocess.PIPE,
                                    stderr=subprocess.STDOUT, text=True)
            log = out / f'run_{decouple}_{delay}.log'
            log.write_text(result.stdout)
            print(result.stdout, end='', flush=True)
            assert result.returncode == 0 and 'DDR_PROBE_SCOREBOARD=PASS' in result.stdout, str(log)
            latency = re.search(r'min_latency=(\d+) max_latency=(\d+)', result.stdout)
            expected = delay + 1 + (args.extra_latency if decouple else 0)
            assert latency and tuple(map(int, latency.groups())) == (expected, expected)
            results.append(dict(read_decouple=decouple, delay=delay, output=result.stdout))
    report = dict(note='Synthetic router-only endpoint; no L2/Gemmini/board model.',
                  router_sha256=hashlib.sha256(args.router.read_bytes()).hexdigest(),
                  expected_extra_latency=args.extra_latency if supports_h1 else 0,
                  head_implementation='H1_SWITCHABLE' if supports_h1 else 'S1_LEGACY', results=results)
    (out / 'results.json').write_text(json.dumps(report, indent=2) + '\n')
    print('HEAD_PERFORMANCE_REGRESSION=PASS')


if __name__ == '__main__':
    main()
