#!/usr/bin/env python3
"""Replay a frozen L2 binary with measured Head latency added to memory delay.

This is a calibrated delay model, not an integrated AXI/Head simulation.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--compiled', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--count', type=int, default=4096)
    parser.add_argument('--extra-latency', type=int, required=True)
    args = parser.parse_args()
    assert args.extra_latency >= 0
    compiled = args.compiled.resolve()
    source_report = compiled / f'results_count{args.count}.json'
    base = json.loads(source_report.read_text())
    assert base['clean_ack_delay'] == 0
    identity = compiled / 'compiled_sources.json'
    assert sha(identity) == base['compiled_sources_sha256']
    binary = compiled / 'obj/Vtb_l2_performance'
    binary_hash = sha(binary)
    if 'binary_sha256' in base:
        assert binary_hash == base['binary_sha256']
    out = args.output.resolve()
    out.mkdir(parents=True, exist_ok=True)
    rows = []
    configurations = sorted({(x['window'], x['delay'], x['stalls'], x['seed']) for x in base['results']})
    for window, delay, stalls, seed in configurations:
        actual_delay = delay + args.extra_latency
        # The bench mixes delay into its measured-phase RNG seed. Undo that
        # change so the ready trace remains identical to the base scenario.
        actual_seed = seed ^ ((delay ^ actual_delay) << 8)
        for case in range(4):
            assert actual_seed ^ case ^ (actual_delay << 8) == seed ^ case ^ (delay << 8)
        command = [str(binary), f'+WINDOW={window}', f'+DELAY={actual_delay}',
                   f'+COUNT={args.count}', f'+SEED={actual_seed}', '+CLEAN_ACK_DELAY=0']
        if stalls:
            command += ['+STALLS']
        result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        log = out / f'count{args.count}_window{window}_delay{delay}_stalls{stalls}_seed{seed}.log'
        log.write_text(result.stdout)
        assert result.returncode == 0 and 'L2_PERF_SCOREBOARD=PASS' in result.stdout, str(log)
        found = []
        for line in result.stdout.splitlines():
            if line.startswith('L2_PERF '):
                row = {k: int(v) for k, v in re.findall(r'(\w+)=(\d+)', line)}
                assert row['delay'] == actual_delay and row['seed'] == actual_seed
                row.update(delay=delay, seed=seed, effective_memory_delay=actual_delay,
                           effective_seed=actual_seed, extra_memory_latency=args.extra_latency)
                found.append(row)
        assert len(found) == 4
        rows += found
    assert sha(binary) == binary_hash, 'Frozen simulation executable changed'
    shutil.copyfile(identity, out / identity.name)
    report = dict(results=rows, clean_ack_delay=0, extra_memory_latency=args.extra_latency,
                  workload_sha256=base['workload_sha256'], binary_sha256=binary_hash,
                  compiled_sources_sha256=sha(identity), base_results_sha256=sha(source_report),
                  scope='Actual L2 RTL with calibrated extra memory delay; delay/seed identify the base trace.',
                  limitations='No integrated AXI/Head, DDR controller, global Head credits, or V33 execution model.')
    target = out / f'results_count{args.count}.json'
    target.write_text(json.dumps(report, indent=2) + '\n')
    print(f'HEAD_LATENCY_BUDGET=PASS scenarios={len(rows)} extra={args.extra_latency} report={target}')


if __name__ == '__main__':
    main()
