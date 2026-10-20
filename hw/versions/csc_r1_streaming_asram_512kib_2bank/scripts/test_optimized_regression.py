#!/usr/bin/env python3
"""Revalidate the Store-wait optimization against immutable G0/G1 evidence.

All runs use complete Gemmini RTL and deterministic private memory services.
The archived C0 numerical references are reused; disabled event/cycle identity
is checked again with this build. These cycles do not establish G2 throughput.
"""
import argparse
import json
from pathlib import Path
import subprocess
import sys

from candidate_rtl import sha

FEATURE = Path(__file__).resolve().parents[1]


def run(build, prior, g0, output, suite):
    records = []

    def step(name, script, *args):
        command = [sys.executable, '-B', str(FEATURE / script), *map(str, args)]
        log = output / (name + '.log')
        if log.exists():
            raise ValueError('Refusing to overwrite: ' + str(log))
        print('CSC_OPT_STEP', name, flush=True)
        with log.open('w') as stream:
            result = subprocess.run(command, stdout=stream, stderr=subprocess.STDOUT)
        records.append(dict(name=name, command=command, returncode=result.returncode,
                            log=str(log), log_sha256=sha(log)))
        if result.returncode:
            raise RuntimeError('Regression failed: ' + str(log))

    def simulate(name, fixture, enabled, mode=2, lanes='0,1,2', frames=3, acc=False):
        step(name, 'scripts/run_accumulator.py' if acc else 'scripts/run_candidate.py',
             '--build', build, '--commands', fixture / 'commands.txt',
             '--memory', fixture / 'memory', '--output', output / name,
             '--lanes', lanes, '--enabled', enabled, '--mode', mode, '--frames', frames)

    def compare(name, baseline, candidate, lane):
        step(name, 'analysis/compare_candidate.py', '--baseline', baseline,
             '--candidate', candidate, '--output', output / name)

    def trace(directory, lane):
        return directory / f'lane{lane}/full_lane{lane}.csv.gz'

    def require_counts(path, tiles, skips):
        result = json.loads(path.read_text())
        if result['status'] != 'PASS' or result['candidate']['tiles'] != tiles or \
                result['candidate']['skipped'] != skips or result['candidate']['completions'] != skips:
            raise ValueError('Unexpected coverage: ' + str(path))

    result_path = output / (suite + '_result.json')
    if result_path.exists():
        raise ValueError('Suite already finalized')
    status = 'FAIL'
    try:
        if suite == 'smoke':
            simulate('fullsize_on', prior / 'fullsize_fixtures', 1, lanes='0', frames=1, acc=True)
            compare('fullsize_comparison', trace(prior / 'acc_fullsize_off', 0),
                    trace(output / 'fullsize_on', 0), 0)
            step('fullsize_acc_comparison', 'analysis/compare_accumulator.py',
                 '--baseline', prior / 'acc_fullsize_off', '--candidate', output / 'fullsize_on',
                 '--output', output / 'fullsize_acc_comparison.json')
        elif suite == 'regression':
            simulate('compact_off', g0 / 'calibration_serial_complete', 0, lanes='0')
            step('disabled_identity', 'analysis/compare_disabled.py',
                 '--baseline', trace(prior / 'compact_final_off', 0),
                 '--candidate', trace(output / 'compact_off', 0),
                 '--output', output / 'disabled_identity.json')
            for mode in range(4):
                name = f'mode{mode}_on'
                simulate(name, prior / 'directed_fixture_03', 1, mode)
                for lane in range(3):
                    case = f'mode{mode}_comparison_lane{lane}'
                    compare(case, trace(prior / f'directed_mode{mode}_off', lane),
                            trace(output / name, lane), lane)
                    require_counts(output / case / 'comparison.json', 12, 9)
            simulate('config_hazard_on', prior / 'config_hazard_fixture', 1)
            for lane in range(3):
                case = f'config_hazard_comparison_lane{lane}'
                compare(case, trace(prior / 'config_hazard_off', lane),
                        trace(output / 'config_hazard_on', lane), lane)
                require_counts(output / case / 'comparison.json', 12, 3)
            for enabled in (0, 1):
                simulate(f'store_hazard_{enabled}', output / 'store_hazard_fixture', enabled)
            for lane in range(3):
                case = f'store_hazard_comparison_lane{lane}'
                compare(case, trace(output / 'store_hazard_0', lane),
                        trace(output / 'store_hazard_1', lane), lane)
                require_counts(output / case / 'comparison.json', 12, 0)
                step(f'store_hazard_identity_lane{lane}', 'analysis/compare_disabled.py',
                     '--baseline', trace(output / 'store_hazard_0', lane),
                     '--candidate', trace(output / 'store_hazard_1', lane),
                     '--output', output / f'store_hazard_identity_lane{lane}.json')
            simulate('directed_acc_on', prior / 'directed_fixture_03', 1, acc=True)
            step('directed_acc_comparison', 'analysis/compare_accumulator.py',
                 '--baseline', prior / 'acc_directed_02_off', '--candidate', output / 'directed_acc_on',
                 '--output', output / 'directed_acc_comparison.json')
            for start in (0, 2):
                step(f'mode_switch_{start}', 'scripts/test_mode_switch.py', '--build', build,
                     '--fixture', prior / 'directed_fixture_03', '--output', output / f'mode_switch_{start}',
                     '--start-mode', start)
            for kind in ('denied', 'corrupt'):
                step('fault_' + kind, 'scripts/test_candidate_faults.py', '--build', build,
                     '--commands', prior / 'directed_fixture_03/commands.txt',
                     '--memory', prior / 'directed_fixture_03/memory',
                     '--output', output / ('fault_' + kind), '--kind', kind)
                compare('fault_' + kind + '_comparison', trace(prior / 'directed_mode2_off', 0),
                        output / ('fault_' + kind) / 'simulation/recovered_lane0.csv.gz', 0)
        elif suite == 'network':
            step('network_on', 'scripts/run_candidate.py', '--build', build,
                 '--commands', g0 / 'workload_05/native_commands.txt',
                 '--memory', g0 / 'functional_memory.bin', '--output', output / 'network_on',
                 '--lanes', '0,1,2', '--enabled', 1, '--mode', 2, '--frames', 1)
            for lane in range(3):
                step(f'network_comparison_lane{lane}', 'scripts/g1_reference.py', 'compare',
                     '--reference', prior / f'reference_lane{lane}',
                     '--candidate', trace(output / 'network_on', lane),
                     '--output', output / f'network_comparison_lane{lane}')
                step(f'transactions_lane{lane}', 'analysis/g1_transactions.py',
                     '--trace', trace(output / 'network_on', lane),
                     '--workload', g0 / 'workload_05/workload.json',
                     '--output', output / f'transactions_lane{lane}', '--lane', lane)
        status = 'PASS'
    except Exception:
        status = 'FAIL'
        raise
    finally:
        result_path.write_text(json.dumps(dict(schema=1, status=status, suite=suite,
            full_system_performance_model=False, steps=records,
            sha256={str(p): sha(p) for p in [Path(__file__).resolve(), build / 'build_manifest.json']}),
            indent=2) + '\n')
    print('CSC_OPT_SUITE_PASS', suite, flush=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ('build', 'prior', 'g0', 'output'):
        parser.add_argument('--' + name, type=Path, required=True)
    parser.add_argument('--suite', choices=('smoke', 'regression', 'network'), required=True)
    args = parser.parse_args()
    run(args.build.resolve(), args.prior.resolve(), args.g0.resolve(), args.output.resolve(), args.suite)
