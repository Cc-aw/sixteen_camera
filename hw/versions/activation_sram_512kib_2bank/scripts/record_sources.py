#!/usr/bin/env python3
"""Explicitly refresh this private version's reviewable source provenance."""
import datetime
import hashlib
import json
from pathlib import Path
import subprocess

FEATURE = Path(__file__).resolve().parents[1]
BASE = FEATURE.parent / 'dma_load_512kib_2bank'
REPO = FEATURE.parents[2]


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    files = {}
    for path in sorted(FEATURE.rglob('*')):
        if not path.is_file() or '__pycache__' in path.parts:
            continue
        relative = str(path.relative_to(FEATURE))
        if relative in ('manifests/SOURCE_ORIGINS.json', 'validation/status.json', 'manifests/artifacts.json'):
            continue
        if path.is_symlink():
            raise SystemExit('Feature source must not be a symlink: ' + relative)
        source = BASE / relative
        entry = dict(sha256=digest(path), kind='new_file')
        if source.is_file():
            entry.update(source=str(source.relative_to(REPO)), source_sha256=digest(source),
                         kind='exact_copy' if digest(path) == digest(source) else 'asram_derived')
        files[relative] = entry
    result = dict(schema=1, recorded_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
                  hardware_variant='activation_sram_512kib_2bank',
                  source_commit=subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=REPO, text=True).strip(),
                  source_state='actual_working_tree_snapshot',
                  base_version=str(BASE.relative_to(REPO)),
                  base_source_origins_sha256=digest(FEATURE / 'manifests/BASE_SOURCE_ORIGINS.json'),
                  mutable_records=['validation/status.json', 'manifests/artifacts.json'],
                  files=files)
    (FEATURE / 'manifests/SOURCE_ORIGINS.json').write_text(json.dumps(result, indent=2) + '\n')
    print(f'ASRAM_SOURCE_PROVENANCE_RECORDED files={len(files)}')


if __name__ == '__main__':
    main()
