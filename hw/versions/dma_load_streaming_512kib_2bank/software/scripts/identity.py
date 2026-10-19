#!/usr/bin/env python3
"""Build/audit diagnostics for an explicit four-mode candidate before bitstream creation."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
OUT = Path(os.environ.get('FRONTEND_BUILD', ROOT / 'build')).resolve()


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--context', type=Path, required=True)
    modes = parser.add_mutually_exclusive_group(required=True)
    for name in ('prepare', 'record', 'check'):
        modes.add_argument('--' + name, action='store_true')
    args = parser.parse_args()
    context_path = args.context.resolve()
    context = json.loads(context_path.read_text())
    if (not context.get('dma_load_streaming_enable') or len(context['dma_load_supported_modes']) != 4 or
            context['l2_banks'] != 2 or context['l2_capacity_kib'] != 512):
        raise ValueError('Expected the new four-mode streaming candidate')
    sources = [p for directory in ('src', 'include', 'model', 'scripts', 'hardware')
               for p in (ROOT / directory).rglob('*') if p.is_file() and '__pycache__' not in p.parts]
    sources += [ROOT / 'Makefile', ROOT / 'config.example.mk']
    for channel in range(3):
        headers = list((context_path.parent / 'gen-collateral/include').glob(f'*custom{channel}_xcvu13p.h'))
        if len(headers) != 1 or sha(headers[0]) != sha(ROOT / f'hardware/gemmini_params_custom{channel}.h'):
            raise ValueError('Diagnostic parameter header differs from generated hardware')
    identity = dict(sources={str(p.relative_to(ROOT)): sha(p) for p in sources},
                    hardware_build_id=context['dma_load_build_id'], flags=os.environ.get('DMA_CFLAGS', ''),
                    arch=os.environ.get('DMA_ARCH', ''), compiler=subprocess.check_output(
                        [os.environ.get('CROSS', 'riscv64-unknown-elf-') + 'gcc', '--version'], text=True).splitlines()[0])
    software_id = hashlib.sha256(json.dumps(identity, sort_keys=True).encode()).hexdigest()
    if args.prepare:
        (OUT / 'generated').mkdir(parents=True, exist_ok=True)
        (OUT / 'generated/board_identity.h').write_text('#define DMA_BOARD_BUILD_ID "' + software_id + '"\n')
        (OUT / 'generated/dma_load_identity.h').write_text(
            '#define DMA_LOAD_EXPECTED_BUILD_ID UINT64_C(0x' + context['dma_load_build_id'] + ')\n')
        return
    for name, marker in [('first', b'DMALF1,PASS'), ('model', b'DMAL1,PASS')]:
        elf = OUT / f'yolov5_dma_load_{name}.elf'
        data = elf.read_bytes()
        if (data[:4] != b'\x7fELF' or marker not in data or software_id.encode() not in data or
                int(context['dma_load_build_id'], 16).to_bytes(8, 'little') not in data or b'schema=2' not in data):
            raise ValueError('Wrong four-mode short-suite ELF identity: ' + name)
        dis = (OUT / f'yolov5_dma_load_{name}.dis').read_text()
        words = [int(w, 16) for w in re.findall(r'^\s*[0-9a-f]+:\s+([0-9a-f]{8})\s', dis, re.M)]
        setters = {word >> 25 for word in words if word & 127 == 0x7b}
        if not {9, 41, 73} <= setters:
            raise ValueError('Missing real lane mode setters')
    files = sources + [context_path] + list((OUT / 'generated').rglob('*'))
    files += [OUT / ('yolov5_dma_load_' + name + suffix) for name in ('first', 'model') for suffix in ('.elf', '.dis')]
    report = dict(status='ELF_AUDIT_PASS', hardware_executed=False, build_id=context['dma_load_build_id'],
                  software_build_id=software_id, l2_kib=512, l2_banks=2, modes=4, schema=2,
                  sha256={str(p.resolve()): sha(p) for p in files if p.is_file()})
    manifest = OUT / 'dma_load_manifest.json'
    if args.check:
        if json.loads(manifest.read_text()) != report:
            raise ValueError('Stale diagnostic manifest')
    else:
        manifest.write_text(json.dumps(report, indent=2) + '\n')
    print('STREAMING_ELF_AUDIT_PASS build_id=' + context['dma_load_build_id'])


if __name__ == '__main__':
    main()
