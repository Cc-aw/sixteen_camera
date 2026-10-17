#!/usr/bin/env python3
"""Bind the private original-layout diagnostic ELF to its actual candidate."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import re

ROOT = Path(__file__).resolve().parents[4]
FRONTEND = ROOT / 'sw/benchmarks/frontend'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--context', type=Path, required=True)
    modes = parser.add_mutually_exclusive_group(required=True)
    for option in ('prepare', 'record', 'check'):
        modes.add_argument('--' + option, action='store_true')
    args = parser.parse_args()
    context_path = args.context.resolve()
    context = json.loads(context_path.read_text())
    assert context.get('dma_load_runtime_enable') and context['l2_banks'] == 2
    assert context['l2_capacity_kib'] == 512 and context['dma_load_control_version'] == 1
    build_id = context['dma_load_build_id']
    assert len(build_id) == 16 and int(build_id, 16)
    out = Path(os.environ.get('FRONTEND_BUILD', ROOT/'build/firmware/dma-load-2bank')).resolve()
    if args.prepare:
        (out/'generated/dma_load_identity.h').write_text(
            '#define DMA_LOAD_EXPECTED_BUILD_ID UINT64_C(0x' + build_id + ')\n')
        return
    elf = out/'yolov5_dma_load_model.elf'
    dis = out/'yolov5_dma_load_model.dis'
    data = elf.read_bytes()
    assert data[:4] == b'\x7fELF'
    for marker in (b'DMAL1,BUILD', b'DMAL1,RESULT', b'DMAL1,COUNTERS', b'DMAL1,SUMMARY', b'DMAL1,PASS'):
        assert marker in data, marker
    assert int(build_id, 16).to_bytes(8, 'little') in data
    cross = os.environ.get('CROSS', 'riscv64-unknown-elf-')
    header = subprocess.check_output([cross+'readelf','-h',elf], text=True)
    assert '0x82000000' in header
    first = out/'yolov5_dma_load_first.elf'
    assert b'DMALF1,PASS' in first.read_bytes()
    assert int(build_id,16).to_bytes(8,'little') in first.read_bytes()
    for name in (dis,out/'yolov5_dma_load_first.dis'):
        instructions=[int(word,16) for word in re.findall(r'^\s*[0-9a-f]+:\s+([0-9a-f]{8})\s',name.read_text(),re.M)]
        control={word>>25 for word in instructions if word&127==0x7b}
        assert {9,41,73} <= control, 'Missing real runtime mode setters'
    files = [elf, dis, context_path, out/'generated/dma_load_identity.h',
             out/'yolov5_dma_load_first.elf', out/'yolov5_dma_load_first.dis',
             FRONTEND/'src/dma_load_first_main.c', FRONTEND/'src/first_layer_s2d_main.c',
             FRONTEND/'src/dma_load_model_main.c', FRONTEND/'src/boundary_main.c',
             FRONTEND/'src/memory_diag.inc', FRONTEND/'include/gemmini_frontend.h',
             FRONTEND/'dma-load.mk', Path(__file__).resolve()]
    files += list((out/'generated').glob('*'))
    report = dict(status='ELF_AUDIT_PASS', hardware_executed=False, build_id=build_id,
                  l2_kib=512, l2_banks=2, sha256={str(p):sha(p) for p in set(files) if p.is_file()})
    manifest = out/'dma_load_manifest.json'
    if args.check:
        assert report == json.loads(manifest.read_text()), 'Stale DMA diagnostic'
    else:
        manifest.write_text(json.dumps(report,indent=2)+'\n')
    print('DMA_LOAD_ELF_AUDIT_PASS build_id=' + build_id)


if __name__ == '__main__':
    main()
