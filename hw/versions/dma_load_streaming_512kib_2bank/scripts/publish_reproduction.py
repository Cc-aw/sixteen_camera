#!/usr/bin/env python3
"""Publish regenerated, byte-identical collateral at its tested source paths."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--tested', type=Path, required=True)
    parser.add_argument('--reproduced', type=Path, required=True)
    parser.add_argument('--record', type=Path, required=True)
    args = parser.parse_args()
    tested, reproduced = args.tested.resolve(), args.reproduced.resolve()
    if tested == reproduced or args.record.exists():
        raise ValueError('Use separate generation directories and a new record')
    old_path, new_path = [p/'GENERATION_CONTEXT.json' for p in (tested, reproduced)]
    old, new = [json.loads(p.read_text()) for p in (old_path, new_path)]
    for name in ('hardware_variant', 'config', 'dma_load_build_id', 'source_identity_sha256',
                 'effective_scala', 'build_sbt_sha256', 'dma_load_streaming_enable',
                 'dma_load_pipeline_version', 'dma_load_cross_command_write_combining_enable'):
        if old[name] != new[name]:
            raise ValueError('Generation identity differs: ' + name)
    if set(old['final_rtl_sha256']) != set(new['final_rtl_sha256']):
        raise ValueError('Generated collateral file set differs')
    identical = {}
    for name, expected in old['final_rtl_sha256'].items():
        a, b = [p/'gen-collateral'/name for p in (tested, reproduced)]
        if sha(a) != expected or sha(b) != new['final_rtl_sha256'][name]:
            raise ValueError('Generation artifact changed: ' + name)
        # Metadata embeds output paths; every hardware/header byte must match.
        if a.suffix.lower() in ('.sv', '.v', '.vh', '.svh', '.h', '.vhd', '.vhdl'):
            if sha(a) != sha(b):
                raise ValueError('Tested hardware differs: ' + name)
            identical[name] = expected
    if not identical:
        raise ValueError('No hardware artifacts compared')
    for field in ('feature_source_origins', 'feature_generator'):
        snapshot = reproduced/new[field+'_snapshot']
        if sha(snapshot) != new[field+'_sha256']:
            raise ValueError('Regeneration provenance archive differs')
    args.record.parent.mkdir(parents=True, exist_ok=True)
    archive = args.record.with_suffix('.initial_context.json')
    if archive.exists():
        raise ValueError('Initial context archive already exists')
    shutil.copy2(old_path, archive)
    record = dict(status='BYTE_IDENTICAL_HARDWARE_REPRODUCTION_PASS',
                  tested=str(tested), reproduced=str(reproduced),
                  build_id=new['dma_load_build_id'], initial_context_sha256=sha(old_path),
                  regenerated_context_sha256=sha(new_path), initial_context_archive=str(archive),
                  identical_hardware_sha256=identical,
                  rationale='Final tooling/source manifest regenerated the same hardware; simulations retain their original byte-identical source paths')
    for name in new['final_rtl_sha256']:
        shutil.copy2(reproduced/'gen-collateral'/name, tested/'gen-collateral'/name)
    for field in ('feature_source_origins', 'feature_generator'):
        name = new[field+'_snapshot']
        shutil.copy2(reproduced/name, tested/name)
    shutil.copy2(new_path, old_path)
    args.record.write_text(json.dumps(record, indent=2)+'\n')
    print('BYTE_IDENTICAL_HARDWARE_REPRODUCTION_PASS files=' + str(len(identical)))


if __name__ == '__main__':
    main()
