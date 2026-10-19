#!/usr/bin/env python3
"""Audit feature-local sources; distinguish new candidates from historical hardware."""
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
        raise SystemExit('DMA_LOAD_VARIANT_AUDIT=FAIL file=' + str(path))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--context', type=Path, help='Explicit newly generated four-mode candidate')
    parser.add_argument('--historical-bitstream', action='store_true',
                        help='Hash the old three-mode bitstream; no board access')
    args = parser.parse_args()
    origins_path = FEATURE / 'manifests/SOURCE_ORIGINS.json'
    origins = json.loads(origins_path.read_text())
    artifacts = json.loads((FEATURE / 'manifests/artifacts.json').read_text())
    for relative, entry in origins['files'].items():
        verify(FEATURE / relative, entry['sha256'])
    for name in ('soc_shell', 'command_frontend', 'tensor_ingress', 'board_rtl', 'scripts', 'tests', 'software'):
        for path in (FEATURE / name).rglob('*'):
            if '__pycache__' in path.parts or 'build' in path.relative_to(FEATURE).parts or path.name == 'config.local.mk':
                continue
            if path.is_symlink() or (path.is_file() and str(path.relative_to(FEATURE)) not in origins['files']):
                raise SystemExit('DMA_LOAD_VARIANT_AUDIT=FAIL unexpected=' + str(path))
    print(f"DMA_LOAD_VARIANT_SOURCES=PASS files={len(origins['files'])} "
          f"base_commit={origins['source_commit']} source_state=working_tree_snapshot", flush=True)
    if args.context:
        context_path = args.context.resolve()
        context = json.loads(context_path.read_text())
        for field in ('feature_source_origins', 'feature_generator'):
            verify(context_path.parent / context[field + '_snapshot'], context[field + '_sha256'])
        if (context.get('hardware_variant') != 'dma_load_streaming_512kib_2bank' or
                context.get('feature_source_origins_sha256') != digest(origins_path) or
                context.get('feature_generator_sha256') != digest(FEATURE / 'scripts/build_soc.py') or
                context.get('dma_load_supported_modes') != artifacts['new_generation']['supported_modes'] or
                not context.get('dma_load_runtime_enable') or
                context.get('dma_load_reset_mode') != 'legacy' or
                context.get('l2_banks') != 2 or context.get('l2_capacity_kib') != 512):
            raise SystemExit('DMA_LOAD_VARIANT_AUDIT=FAIL new candidate identity mismatch')
        rtl = context_path.parent / 'gen-collateral'
        for relative, expected in context['final_rtl_sha256'].items():
            verify(rtl / relative, expected)
        actual = {str(p.relative_to(rtl)) for p in rtl.rglob('*') if p.is_file()}
        if actual != set(context['final_rtl_sha256']):
            raise SystemExit('DMA_LOAD_VARIANT_AUDIT=FAIL unexpected generated collateral')
        subprocess.run([sys.executable, '-B', str(FEATURE / 'scripts/check_rtl.py'),
                        str(rtl), '--l2-banks', '2', '--dma-load-runtime'], check=True)
        print(f'DMA_LOAD_VARIANT_RTL=PASS files={len(actual)}', flush=True)
    if args.historical_bitstream:
        bit = artifacts['historical_three_mode_candidate']['bitstream']
        verify(REPO / bit['path'], bit['sha256'])
        print('DMA_LOAD_HISTORICAL_BITSTREAM=PASS modes=3 new_candidate_accepted=0 board_accessed=0')


if __name__ == '__main__':
    main()
