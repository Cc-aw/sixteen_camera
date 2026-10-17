#!/usr/bin/env python3
"""Validate a private DMA candidate and expose its exact RTL source closure."""
import argparse
import hashlib
import json
from pathlib import Path
import re
from l2_geometry import L2Geometry


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def validate(context_path):
    context_path = Path(context_path).resolve()
    c = json.loads(context_path.read_text())
    if not (c.get('dma_load_runtime_enable') and c['l2_banks'] == 2 and
            c['l2_capacity_kib'] == 512 and c['dma_load_control_version'] == 1 and
            c['dma_load_reset_mode'] == 'legacy' and int(c['dma_load_build_id'], 16)):
        raise ValueError('Expected 512KiB/two-bank runtime DMA candidate')
    rtl = context_path.parent / 'gen-collateral'
    for name, expected in c['final_rtl_sha256'].items():
        if sha(rtl/name) != expected:
            raise ValueError('Candidate RTL changed: ' + name)
    metadata = list(context_path.parent.glob('*.l2.json'))
    if len(metadata) != 1:
        raise ValueError('Missing candidate L2 metadata')
    geometry = L2Geometry.from_metadata(metadata[0])
    if geometry.banks != 2 or geometry.capacity_bytes != 524288:
        raise ValueError('Candidate L2 metadata is not 512KiB/two-bank')
    for name in ('DmaLoadGroup.sv', 'DmaLoadRowAssembler.sv', 'StreamReader.sv'):
        if not (rtl/name).is_file():
            raise ValueError('Missing runtime DMA module: ' + name)
    return c, rtl


def closure(rtl, tops):
    mapping, bodies = {}, {}
    for p in Path(rtl).rglob('*'):
        if p.suffix not in ('.v', '.sv'):
            continue
        body = p.read_text()
        bodies[p] = body
        for name in re.findall(r'^module\s+(\w+)', body, re.M):
            mapping[name] = p
    seen = set()

    def visit(name):
        p = mapping[name]
        if p in seen:
            return
        seen.add(p)
        for dep in re.findall(r'^\s+(\w+)\s+(?:#\s*\(|\w+\s*\()', bodies[p], re.M):
            if dep in mapping:
                visit(dep)
    for top in tops:
        visit(top)
    return sorted(seen)


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--context', type=Path, required=True)
    p.add_argument('--tcl', action='store_true')
    args = p.parse_args()
    c, rtl = validate(args.context)
    if args.tcl:
        # Tcl list quoting; each key/value pair is one line.
        values = dict(hardware_alias='dma_load_512kib_2bank', soc_config=c['config'],
                      collateral_directory=str(rtl))
        for k, v in values.items():
            if any(x in v for x in '{}\n\r'):
                raise ValueError('Unsupported Tcl path')
            print(k, '{'+v+'}')
    else:
        print('DMA_LOAD_CANDIDATE_PASS build_id='+c['dma_load_build_id']+' rtl='+str(rtl))


if __name__ == '__main__':
    main()
