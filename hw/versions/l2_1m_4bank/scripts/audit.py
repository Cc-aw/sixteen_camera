#!/usr/bin/env python3
"""Audit the frozen feature inputs and the identity of existing local artifacts."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys

FEATURE = Path(__file__).resolve().parents[1]
REPO = FEATURE.parents[2]


def digest(path):
    result = hashlib.sha256()
    with path.open('rb') as source:
        for block in iter(lambda: source.read(1024 * 1024), b''):
            result.update(block)
    return result.hexdigest()


def verify(path, expected):
    if path.is_symlink() or not path.is_file() or digest(path) != expected:
        raise SystemExit('L2_VARIANT_AUDIT=FAIL file=' + str(path))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--rtl', action='store_true', help='Check the recorded shared RTL export')
    parser.add_argument('--bitstream', action='store_true', help='Hash the existing local .bit; no board access')
    args = parser.parse_args()
    origins = json.loads((FEATURE / 'manifests/SOURCE_ORIGINS.json').read_text())
    artifacts = json.loads((FEATURE / 'manifests/artifacts.json').read_text())
    for relative, entry in origins['files'].items():
        verify(FEATURE / relative, entry['sha256'])
    # A later DMA experiment added beside the snapshots must not silently enter
    # the generator's recursive source overlays.
    for name in ('soc_shell', 'command_frontend', 'tensor_ingress', 'board_rtl'):
        for path in (FEATURE / name).rglob('*'):
            if '__pycache__' in path.parts:
                continue
            if path.is_symlink() or (path.is_file() and str(path.relative_to(FEATURE)) not in origins['files']):
                raise SystemExit('L2_VARIANT_AUDIT=FAIL unexpected=' + str(path))
    print(f"L2_VARIANT_SOURCES=PASS files={len(origins['files'])} commit={origins['source_commit']}", flush=True)
    if args.rtl:
        context_path = REPO / artifacts['generated_soc']['context']
        verify(context_path, artifacts['generated_soc']['context_sha256'])
        context = json.loads(context_path.read_text())
        rtl = context_path.parent / 'gen-collateral'
        for relative, expected in context['final_rtl_sha256'].items():
            verify(rtl / relative, expected)
        actual = {str(p.relative_to(rtl)) for p in rtl.rglob('*') if p.is_file()}
        if actual != set(context['final_rtl_sha256']):
            raise SystemExit('L2_VARIANT_AUDIT=FAIL unexpected generated collateral')
        subprocess.run([sys.executable, '-B', str(FEATURE / 'scripts/check_rtl.py'), str(rtl), '--l2-banks', '4'], check=True)
        print(f"L2_VARIANT_RTL=PASS files={len(actual)}", flush=True)
    if args.bitstream:
        bit = artifacts['candidate_bitstream']
        verify(REPO / bit['path'], bit['sha256'])
        print('L2_VARIANT_BITSTREAM=PASS board_accessed=0', flush=True)


if __name__ == '__main__':
    main()
