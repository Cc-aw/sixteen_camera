#!/usr/bin/env python3
"""Run the imported batch4 regression against the generated production RTL."""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess

from common import ROOT, sha


def ports(path):
    header = re.sub(r'//[^\n]*', '', path.read_text().split(');', 1)[0])
    return re.findall(r'^\s*(input|output)\s+(\[[^]]+\]\s*)?(\w+)\s*[,\n]', header, re.M)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--jobs', type=int, default=4)
    args = parser.parse_args()
    out = args.output.resolve()
    if ROOT / 'build' not in out.parents or out.exists() or args.jobs < 1:
        raise ValueError('Use a new output below this version build/ and positive jobs')
    out.mkdir(parents=True)
    rtl = ROOT / 'generated/gen-collateral'
    wrappers = []
    for native, alias in (('CommandFrontendEngine', 'BatchEngine'),
                          ('CommandFrontendMemoryMux', 'BatchMemory')):
        ps = ports(rtl / (native + '.sv'))
        declarations = [f'{d} wire {w} {n.removeprefix("io_")}' for d, w, n in ps]
        bindings = [f'.{n}({n.removeprefix("io_")})' for _, _, n in ps]
        wrappers.append(f'module {alias}(\n' + ',\n'.join(declarations) + ');\n' +
                        native + ' native_dut(' + ','.join(bindings) + ');\nendmodule\n')
    (out / 'wrappers.sv').write_text('\n'.join(wrappers))
    context = json.loads((rtl.parent / 'GENERATION_CONTEXT.json').read_text())
    results = {}
    for name in ('batch',):
        sources = [rtl / 'CommandFrontendEngine.sv', rtl / 'CommandFrontendMemoryMux.sv',
                   out / 'wrappers.sv', ROOT / f'tests/batch4/tb_{name}.sv']
        subprocess.run([os.environ.get('VERILATOR', 'verilator'), '--binary', '--timing', '--assert',
                        '-Wno-fatal', '-j', str(args.jobs), '--top-module', 'tb_' + name,
                        '--Mdir', str(out / (name + '_obj')),
                        *map(str, sources)], check=True)
        completed = subprocess.run([str(out / (name + '_obj') / ('Vtb_' + name))],
                                   stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        (out / (name + '.log')).write_text(completed.stdout)
        print(completed.stdout, flush=True)
        completed.check_returncode()
        marker = 'BATCH4_PASS'
        if marker not in completed.stdout:
            raise ValueError('Simulation did not reach ' + marker)
        results[name] = dict(status='PASS', log_sha256=sha(out / (name + '.log')))
    report = dict(status='S1_BATCH4_FRONTEND_PASS', hardware_build_id=context['dma_load_build_id'],
                  production_rtl=True, simulations=results, board_validation='NOT_RUN')
    (out / 'evidence.json').write_text(json.dumps(report, indent=2) + '\n')
    print(report['status'])


if __name__ == '__main__':
    main()
