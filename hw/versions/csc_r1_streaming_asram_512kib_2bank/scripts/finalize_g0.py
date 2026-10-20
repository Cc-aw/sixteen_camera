#!/usr/bin/env python3
"""Wait for complete functional lanes, audit them, then publish the G0 gate.

Every subordinate tool performs real work and refuses existing output. Failed
or incomplete lane logs never become an accepted result.
"""
import argparse
from pathlib import Path
import re
import subprocess
import sys
import time

FEATURE = Path(__file__).resolve().parents[1]


def finalize(run, execution, workload, rtl_build, calibration):
    source = run / execution
    while True:
        complete = True
        for lane in range(3):
            path = source / f'lane{lane}.log'
            text = path.read_text() if path.exists() else ''
            if re.search(r'%Error|Assertion failed|Aborting', text):
                raise ValueError('Native functional lane failed: ' + str(lane))
            complete &= bool(re.search(rf'^FULL_GEMMINI_RTL_PASS lane={lane} ', text, re.M))
        if complete:
            break
        time.sleep(2)
    def execute(script, arguments, log):
        with (run / log).open('x') as handle:
            subprocess.run([sys.executable, '-B', str(FEATURE / script), *map(str, arguments)],
                           stdout=handle, stderr=subprocess.STDOUT, check=True)
    execute('scripts/assemble_functional.py', ['--source', source, '--output', run / 'parallel_traces'], 'assemble_functional.log')
    print('FULL_LANES_COMPLETE_STARTING_PHYSICAL_AUDITS', flush=True)
    jobs = []
    for name, trace, log, lanes in (
        ('single_residency', source / 'lane0', source / 'lane0.log', 1),
        ('parallel_residency', run / 'parallel_traces', run / 'parallel_traces/simulation.log', 3),
    ):
        handle = (run / (name + '.log')).open('x')
        command = [sys.executable, '-B', str(FEATURE / 'analysis/analyze_full.py'),
                   '--trace', str(trace), '--log', str(log), '--workload', str(run / workload / 'workload.json'),
                   '--output', str(run / name), '--lanes', str(lanes), '--zero-owners']
        jobs.append((subprocess.Popen(command, stdout=handle, stderr=subprocess.STDOUT), handle))
    for process, handle in jobs:
        code = process.wait()
        handle.close()
        if code:
            raise RuntimeError('Physical lifecycle audit failed: ' + str(code))
    print('PHYSICAL_AUDITS_COMPLETE_STARTING_INDEPENDENT_ELISION', flush=True)
    execute('analysis/validate_elision.py', ['--summary', run / 'parallel_residency/opportunity_summary.json',
            '--qualified', run / 'parallel_residency/qualified_loads.csv',
            '--output', run / 'parallel_residency/elision_model.json'], 'elision_model.log')
    execute('scripts/decide_full.py', ['--run', run, '--workload', workload, '--rtl-build', rtl_build,
            '--calibration', calibration], 'decision_full.log')
    print('G0_AUDITS_AND_DECISION_COMPLETE', flush=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--run', type=Path, required=True)
    parser.add_argument('--execution', default='full_network_parallel')
    parser.add_argument('--workload', default='whole_workload')
    parser.add_argument('--rtl-build', default='full_rtl')
    parser.add_argument('--calibration', default='calibration_full')
    args = parser.parse_args()
    finalize(args.run.resolve(), args.execution, args.workload, args.rtl_build, args.calibration)
