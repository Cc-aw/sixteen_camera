#!/usr/bin/env python3
"""Bind the imported V34 diagnostic to frozen V33 plans and local hardware."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT.parents[2]
OUT = PROJECT / 'build/firmware/frontend-v34'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def snapshot():
    product_path = PROJECT / 'hw/manifests/current.json'
    product = json.loads(product_path.read_text())
    lock = PROJECT / 'sw/models/yolov5nu/frozen/frontend_v33/sources.lock.json'
    files = [p for folder in ('src', 'include', 'scripts') for p in (ROOT / folder).rglob('*')
             if p.is_file() and '__pycache__' not in p.parts]
    files += [ROOT / 'v34.mk', ROOT / 'download-v34.sh', ROOT / 'IMPORT_V34.json', PROJECT / 'Makefile']
    files += [lock, product_path, PROJECT / product['generation_context']]
    files += [PROJECT / p for p in product['parameter_headers']]
    files += list((PROJECT / 'tests/model/frontend_v34').glob('*.py'))
    for item in json.loads(lock.read_text())['sources']:
        source = PROJECT / item['path']
        staged = OUT / 'native' / item['snapshot']
        if sha(source) != item['sha256'] or sha(staged) != item['sha256']:
            raise ValueError('Frozen/staged input mismatch: ' + item['snapshot'])
        files += [source, staged]
    files += [p for p in (OUT / 'generated').rglob('*') if p.is_file()]
    files += [OUT / ('yolov5_frontend_boundary_diag_12.' + ext) for ext in ('elf', 'map', 'dis')]
    files += [OUT / 'boundary_plan.txt', PROJECT / 'build/firmware/frontend/native_plan.txt']
    if (OUT / 'boundary_plan.txt').read_bytes() != files[-1].read_bytes():
        raise ValueError('V34 plan differs from frozen V33 oracle')
    cross = os.environ.get('CROSS') or os.environ.get('TOOLCHAIN') or 'riscv64-unknown-elf-'
    compiler = subprocess.check_output([cross + 'gcc', '--version'], text=True).splitlines()[0]
    for p in files:
        if not p.resolve().is_relative_to(PROJECT):
            raise ValueError('Nonlocal build input: ' + str(p))
    return dict(schema=1, firmware='YOLO32_FRONTEND/v34', profile='reference',
                soc_config=product['soc_config'], compiler=compiler, board_tested=False,
                plan='frozen V33: 18 tables checked by native plan validator',
                timing='13 observed HOST/tail intervals per frame; not per-layer hardware timestamps',
                memory_abis=['1.0', '1.1', '1.2'],
                files={str(p.relative_to(PROJECT)): sha(p) for p in sorted(set(files))})


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    current = snapshot()
    path = OUT / 'v34_manifest.json'
    if args.check:
        saved = json.loads(path.read_text())
        if saved != current:
            changed = [k for k in saved['files'].keys() | current['files'].keys()
                       if saved['files'].get(k) != current['files'].get(k)]
            raise ValueError('V34 artifact/hardware changed; rebuild: ' + ', '.join(sorted(changed)))
    else:
        path.write_text(json.dumps(current, indent=2) + '\n')
    print('V34_MANIFEST=PASS profile=reference board_accessed=0')


if __name__ == '__main__':
    main()
