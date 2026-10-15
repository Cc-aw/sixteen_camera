#!/usr/bin/env python3
"""Bind V33 executables to local inputs and the current hardware export."""
import argparse
import hashlib
import json
import os
import subprocess
from prepare import ROOT, PROJECT, OUT, LOCK


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def snapshot():
    product_path = PROJECT / 'hw/manifests/current.json'
    product = json.loads(product_path.read_text())
    files = [p for folder in ('src', 'include', 'scripts') for p in (ROOT / folder).rglob('*')
             if p.is_file() and '__pycache__' not in p.parts]
    files += [ROOT / n for n in ('Makefile', 'download.sh', 'IMPORT_MANIFEST.json', 'upstream_lock.json')]
    files += [LOCK, product_path, PROJECT / product['generation_context']]
    files += [PROJECT / p for p in product['parameter_headers']]
    for item in json.loads(LOCK.read_text())['sources']:
        source = PROJECT / item['path']
        staged = OUT / 'native' / item['snapshot']
        if digest(source) != item['sha256'] or digest(staged) != item['sha256']:
            raise ValueError('Frozen/staged V33 input mismatch: ' + item['snapshot'])
        files += [source, staged]
    files += [p for p in (OUT / 'generated').rglob('*') if p.is_file()]
    files += [OUT / n for n in ('config.stamp', 'yolov5_three_way_12.elf', 'yolov5_frontend_diag_12.elf')]
    # Both build outputs and inputs are contained in this checkout.
    for path in files:
        if not path.resolve().is_relative_to(PROJECT):
            raise ValueError('Nonlocal V33 input/output: ' + str(path))
    cross = os.environ.get('CROSS') or os.environ.get('TOOLCHAIN') or 'riscv64-unknown-elf-'
    compiler_version = subprocess.check_output([cross + 'gcc', '--version'], text=True).splitlines()[0]
    return dict(schema=1, firmware='YOLO32_FRONTEND/v33', soc_config=product['soc_config'],
                compiler=cross + 'gcc', compiler_version=compiler_version,
                frames_per_mode=12, modes=['direct_serial', 'frontend_serial', 'frontend_parallel'],
                command_table=dict(entries=10870, raw=10478, drain=380, host=12),
                runtime_adapted=False, board_tested=False,
                files={str(p.relative_to(PROJECT)): digest(p) for p in sorted(set(files))})


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    current = snapshot()
    path = OUT / 'frontend_manifest.json'
    if args.check:
        saved = json.loads(path.read_text())
        if current != saved:
            changed = sorted(k for k in current['files'].keys() | saved['files'].keys()
                             if current['files'].get(k) != saved['files'].get(k))
            raise ValueError('V33 artifact/input mismatch: ' + ', '.join(changed))
    else:
        path.write_text(json.dumps(current, indent=2) + '\n')
    print('V33_MANIFEST=PASS files=' + str(len(current['files'])) + ' board_accessed=0')


if __name__ == '__main__':
    main()
