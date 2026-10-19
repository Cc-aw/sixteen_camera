#!/usr/bin/env python3
"""Run the same full-size boundary/byte-mask test with two storage models."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess

FEATURE = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--vivado-root', type=Path, default=Path('/mnt/data/Vivado/Vivado/2023.2'))
    args = parser.parse_args()
    out = args.output.resolve(); out.mkdir(parents=True, exist_ok=False)
    store = FEATURE / 'activation_sram/resources/activation_sram_store.sv'
    bench = FEATURE / 'tests/tb_activation_sram_store.sv'
    vendor = args.vivado_root / 'data/verilog/src/unisims/URAM288_BASE.v'
    glbl = args.vivado_root / 'data/verilog/src/glbl.v'
    results = {}
    for name in ('behavioral', 'vendor'):
        command = ['iverilog', '-g2012', '-s', 'tb_activation_sram_store', '-o', str(out / (name + '.vvp'))]
        if name == 'behavioral':
            command += ['-DASRAM_BEHAVIORAL', str(store), str(bench)]
        else:
            command += ['-s', 'glbl', str(store), str(bench), str(vendor), str(glbl)]
        with (out / (name + '_compile.log')).open('w') as log:
            subprocess.run(command, stdout=log, stderr=subprocess.STDOUT, check=True, timeout=120)
        run = subprocess.run(['vvp', str(out / (name + '.vvp'))], capture_output=True, text=True, timeout=120)
        (out / (name + '.log')).write_text(run.stdout + run.stderr)
        if run.returncode or 'ASRAM_STORE_PASS' not in run.stdout:
            raise SystemExit(name + ' storage model failed: ' + run.stdout + run.stderr)
        results[name] = dict(status='PASS', compile_command=command, exit_code=run.returncode,
                             log=str(out / (name + '.log')))
        print(name + ': ' + run.stdout.strip())
    result = dict(status='PASS', models=results, physical_bytes=2359296, ports=2,
                  source_sha256={str(p): hashlib.sha256(p.read_bytes()).hexdigest() for p in (store, bench, vendor, glbl)})
    (out / 'evidence.json').write_text(json.dumps(result, indent=2) + '\n')
    print('ASRAM_STORE_MODELS=PASS')


if __name__ == '__main__':
    main()
