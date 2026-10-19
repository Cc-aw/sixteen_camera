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


def verify_generation_sources(context, feature=FEATURE):
    """Allow new physical constraints without relabeling previously generated RTL.

    The original manifest must remain byte-identical and every generation input
    must still match it. A new/changed Scala, RTL or generator input fails closed.
    """
    expected = context.get('feature_source_origins_sha256')
    current = feature / 'manifests/SOURCE_ORIGINS.json'
    candidates = [current, *sorted((feature / 'manifests/rtl_snapshots').glob('*.sources.json'))]
    matches = [p for p in candidates if not p.is_symlink() and digest(p) == expected]
    if not matches:
        raise SystemExit('ASRAM_AUDIT=FAIL missing immutable generation source manifest')
    snapshot = json.loads(matches[0].read_text())['files']
    prefixes = ('soc_shell/', 'command_frontend/', 'tensor_ingress/',
                'activation_sram/', 'board_rtl/')
    inputs = {'manifests/activation_sram.json', 'scripts/build_soc.py',
              'scripts/address_map.py', 'scripts/check_activation_sram.py',
              'scripts/check_rtl.py', 'scripts/l2_geometry.py'}
    selected = {name for name in snapshot if name.startswith(prefixes) or name in inputs}
    actual = {str(p.relative_to(feature)) for prefix in prefixes
              for p in (feature / prefix).rglob('*') if p.is_file() and '__pycache__' not in p.parts}
    if actual != {name for name in selected if name.startswith(prefixes)}:
        raise SystemExit('ASRAM_AUDIT=FAIL generation input file set changed')
    for name in selected:
        verify(feature / name, snapshot[name]['sha256'])
    return matches[0]


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
    for name in ('soc_shell', 'command_frontend', 'tensor_ingress', 'board_rtl', 'scripts', 'tests', 'activation_sram', 'software', 'constraints'):
        for path in (FEATURE / name).rglob('*'):
            if '__pycache__' in path.parts:
                continue
            if path.is_symlink() or (path.is_file() and str(path.relative_to(FEATURE)) not in origins['files']):
                raise SystemExit('DMA_LOAD_VARIANT_AUDIT=FAIL unexpected=' + str(path))
    subprocess.run([sys.executable, '-B', str(FEATURE / 'scripts/address_map.py'), '--check'], check=True)
    print(f"DMA_LOAD_VARIANT_SOURCES=PASS files={len(origins['files'])} "
          f"base_commit={origins['source_commit']} source_state=working_tree_snapshot", flush=True)
    if args.context:
        context_path = args.context.resolve()
        context = json.loads(context_path.read_text())
        generation_origins = verify_generation_sources(context)
        if (context.get('hardware_variant') != 'activation_sram_512kib_2bank' or
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
        if context.get('activation_sram_enabled'):
            if context.get('activation_sram_manifest_sha256') != digest(FEATURE / 'manifests/activation_sram.json'):
                raise SystemExit('ASRAM address manifest changed since generation')
            subprocess.run([sys.executable, '-B', str(FEATURE / 'scripts/check_activation_sram.py'),
                            '--rtl', str(rtl)], check=True)
        print(f'DMA_LOAD_VARIANT_RTL=PASS files={len(actual)}', flush=True)
        print(f'ASRAM_GENERATION_SOURCES=PASS manifest={generation_origins}', flush=True)
    if args.historical_bitstream:
        bit = artifacts['historical_three_mode_candidate']['bitstream']
        verify(REPO / bit['path'], bit['sha256'])
        print('DMA_LOAD_HISTORICAL_BITSTREAM=PASS modes=3 new_candidate_accepted=0 board_accessed=0')


if __name__ == '__main__':
    main()
