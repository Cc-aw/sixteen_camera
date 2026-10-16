#!/usr/bin/env python3
"""Run real RTL regressions and retain commands, fingerprints and failures."""
import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
OUT = ROOT / 'build/reports/head_l2_urgent'
SEEDS = (151034, 151035, 151036, 151037, 151038)


def fingerprint():
    paths = [ROOT / 'hw/rtl/ai/postprocess/axi4_head_uram_router_v3.sv',
             ROOT / 'hw/rtl/memory/postprocess_memory_bridge_v3.sv',
             ROOT / 'hw/manifests/current.json']
    paths += list((ROOT / 'hw/soc/source/shell/memory_parallel_v3').rglob('*.scala'))
    paths += list(HERE.glob('*.*')) + list((ROOT / 'tests/rtl/scala').glob('*.scala'))
    return hashlib.sha256(b''.join(str(p.relative_to(ROOT)).encode() + p.read_bytes()
                                  for p in sorted(paths) if p.is_file())).hexdigest()


class Runner:
    def __init__(self, suite):
        OUT.mkdir(parents=True, exist_ok=True)
        (OUT / 'logs').mkdir(exist_ok=True)
        self.path = OUT / f'{suite}_results.json'
        self.results = []
        self.source = fingerprint()

    def record(self, name, command, status, code, log, reason):
        self.results.append(dict(name=name, command=command, status=status,
                                 exit_code=code, log=str(log), reason=reason,
                                 source_fingerprint=self.source))
        self.path.write_text(json.dumps(self.results, indent=2) + '\n')
        (OUT / (self.path.stem + '.txt')).write_text(''.join(
            f"{r['name']}={r['status']} command={r['command']} log={r['log']} {r['reason']}\n"
            for r in self.results))
        print(f'{name}={status}', flush=True)
        return status == 'PASS'

    def run(self, name, cmd, marker=None, cwd=ROOT):
        log = OUT / 'logs' / (name + '.log')
        command = shlex.join(map(str, cmd))
        if not shutil.which(str(cmd[0])):
            return self.record(name, command, 'BLOCKED', None, log, 'Required executable unavailable')
        with log.open('w') as output:
            result = subprocess.run(list(map(str, cmd)), cwd=cwd, stdout=output, stderr=subprocess.STDOUT)
        body = log.read_text(errors='replace')
        status = 'PASS' if result.returncode == 0 else 'FAIL'
        reason = ''
        if status == 'PASS' and (re.search(r'\b(?:SKIP|BLOCKED)\b', body) or (marker and marker not in body)):
            status = 'BLOCKED'
            reason = 'Subtest skipped/blocked or required completion marker absent'
        return self.record(name, command, status, result.returncode, log, reason)


def head(r):
    verilator = os.environ.get('HEAD_VERILATOR', shutil.which('verilator') or 'verilator')
    common = [ROOT / 'hw/rtl/interfaces/axi4_if.sv', ROOT / 'hw/rtl/ai/postprocess/head_uram_store.sv',
              ROOT / 'hw/rtl/ai/postprocess/axi4_head_uram_router_v3.sv']
    comparisons = []
    for width, legacy in ((512, False), (256, False), (512, True)):
        name = f'head_{width}_' + ('legacy' if legacy else 'decoupled')
        dest = ROOT / 'build/sim/head_l2_urgent' / name
        dest.mkdir(parents=True, exist_ok=True)
        top = 'tb_head_router_ordering'
        cmd = [verilator, '--binary', '--timing', '--assert', '-Wno-fatal', '-j', '4',
               '--top-module', top, f'-GDATA_WIDTH={width}', f'-GREAD_DECOUPLE={int(not legacy)}',
               '--Mdir', dest, *common, HERE / (top + '.sv')]
        if not r.run(name + '_compile', cmd):
            continue
        for seed in (SEEDS if not legacy else SEEDS[:1]):
            r.run(name + f'_seed{seed}', [dest / ('V' + top), f'+SEED={seed}', '+REQUESTS=10000'], 'HEAD_READ_PASS')
        if width == 512:
            progress_name = name + '_progress'
            r.run(progress_name, [dest / ('V' + top), '+PROGRESS_ONLY'], 'HEAD_PROGRESS')
            body = (OUT / 'logs' / (progress_name + '.log')).read_text()
            match = re.search(r'HEAD_PROGRESS decouple=(\d+) head_completed_while_id0_live=(\d+)', body)
            if match:
                comparisons.append(dict(read_decouple=int(match[1]), head_completed_while_id0_live=int(match[2])))
    (OUT / 'head_progress_comparison.json').write_text(json.dumps(comparisons, indent=2) + '\n')
    # Reuse all existing error/write/shadow checks against the production v3
    # router. Keep the original bench and legacy timing checks in their suite.
    original = ROOT / 'tests/rtl/benches/ppu/tb_axi4_head_uram_router.sv'
    adapted = ROOT / 'build/sim/head_l2_urgent/tb_v3_compat.sv'
    adapted.parent.mkdir(parents=True, exist_ok=True)
    adapted.write_text(original.read_text().replace('    axi4_head_uram_router #(', '    axi4_head_uram_router_v3 #(')
                       .replace('.SHADOW_DDR(TEST_SHADOW_DDR)', ".SHADOW_DDR(TEST_SHADOW_DDR), .READ_DECOUPLE(1'b1)"))
    for shadow in (0, 1):
        name = f'head_v3_compat_shadow{shadow}'
        dest = ROOT / 'build/sim/head_l2_urgent' / name
        dest.mkdir(parents=True, exist_ok=True)
        if r.run(name + '_compile', [verilator, '--binary', '--timing', '--assert', '-Wno-fatal', '-j', '4',
                 '--top-module', 'tb_axi4_head_uram_router', f'-GTEST_SHADOW_DDR={shadow}',
                 '--Mdir', dest, *common, adapted]):
            r.run(name, [dest / 'Vtb_axi4_head_uram_router'], 'PASS')


def l2(r, workspace):
    if not workspace:
        r.record('l2_capacity', 'make test-l2-secondary-capacity SOC_WORKSPACE=<rebuilt>',
                 'BLOCKED', None, '', 'Set SOC_WORKSPACE to the regenerated private workspace')
        return
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%d_%H%M%S_%f')
    dest = ROOT / 'build/sim/head_l2_urgent' / f'l2_{stamp}_{os.getpid()}'
    r.run('l2_capacity_coherence', [sys.executable, ROOT / 'tests/rtl/run_v3_timing_repair_tests.py',
          '--workspace', workspace, '--output', dest, '--targets', 'pool', 'cache'], 'V3_TIMING_REPAIR_TESTS=PASS')
    log = dest / 'RegisteredListBufferTest/console.log'
    if log.exists():
        matches = [dict(entries=int(e), seed=int(s), peak=int(p)) for e, s, p in re.findall(
            r'entries=(\d+) queues=102 seed=(\d+).*?peak=(\d+)', log.read_text())]
        (OUT / 'l2_capacity_comparison.json').write_text(json.dumps(matches, indent=2) + '\n')


def integration(r, workspace):
    for target in ('test-memory-v3', 'test-cache', 'test-ppu', 'test-tensor-ingress',
                   'test-v3-timing-repair', 'test-frontend', 'test-v33', 'check-deps'):
        r.run(target, ['make', target, f'SOC_WORKSPACE={workspace or ""}'])


def offline_checks(r):
    product = json.loads((ROOT / 'hw/manifests/current.json').read_text())
    r.run('structure', [sys.executable, ROOT / 'tools/check/check_triple32_v3_tensor.py',
                       ROOT / product['collateral_directory']], 'TRIPLE32_V3_TENSOR_STRUCTURE=PASS')
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%d_%H%M%S_%f')
    dest = OUT / ('head_ooc_' + stamp)
    dest.mkdir(parents=True)
    vivado = os.environ.get('VIVADO_BIN', shutil.which('vivado') or 'vivado')
    if r.run('head-ooc', [vivado, '-mode', 'batch', '-source', HERE / 'head_ooc.tcl',
                         '-log', dest / 'vivado.log', '-journal', dest / 'vivado.jou'],
             'synth_design completed successfully', cwd=dest):
        status = dest / 'status.txt'
        if not status.is_file() or 'HEAD_OOC=PASS URAM=192' not in status.read_text():
            r.record('head-ooc', 'check synthesized Head UltraRAM count', 'FAIL', 1,
                     status, 'Missing 192-URAM synthesis acceptance record')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--suite', choices=('head', 'l2', 'integration', 'all'), default='all')
    parser.add_argument('--workspace', default=os.environ.get('SOC_WORKSPACE'))
    args = parser.parse_args()
    r = Runner(args.suite)
    if args.suite in ('head', 'all'): head(r)
    if args.suite in ('l2', 'all'): l2(r, args.workspace)
    if args.suite in ('integration', 'all'): integration(r, args.workspace)
    if args.suite == 'all': offline_checks(r)
    results = []
    for path in OUT.glob('*_results.json'):
        if path.name != 'validation_results.json': results.extend(json.loads(path.read_text()))
    (OUT / 'validation_results.json').write_text(json.dumps(results, indent=2) + '\n')
    (OUT / 'validation_summary.txt').write_text(''.join(f"{v['name']}={v['status']} log={v['log']}\n" for v in results))
    return 0 if r.results and all(v['status'] == 'PASS' for v in r.results) else 1


if __name__ == '__main__':
    sys.exit(main())
