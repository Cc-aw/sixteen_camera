#!/usr/bin/env python3
"""Record this development version's bytes and its immutable parent provenance."""
import hashlib
import json
from pathlib import Path
import subprocess

FEATURE = Path(__file__).resolve().parents[1]
ROOT = FEATURE.parents[2]
PARENT = FEATURE.parent / 'dma_load_512kib_2bank'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    subprocess.run(['python3', '-B', str(PARENT / 'scripts/audit.py')], check=True)
    files = {}
    for path in sorted(FEATURE.rglob('*')):
        relative = str(path.relative_to(FEATURE))
        if (not path.is_file() or '__pycache__' in path.parts or relative.startswith('validation/') or 'build' in path.relative_to(FEATURE).parts or path.name == 'config.local.mk' or
                relative == 'manifests/SOURCE_ORIGINS.json'):
            continue
        if path.is_symlink():
            raise SystemExit('Source snapshots must be actual files: ' + relative)
        old = PARENT / relative
        if not old.is_file() and relative.startswith('software/'):
            old = ROOT / 'sw/board_tests/dma_load_512kib_2bank' / relative.removeprefix('software/')
        entry = dict(sha256=sha(path), kind='new_file')
        if old.is_file():
            entry.update(source=str(old.relative_to(ROOT)), source_sha256=sha(old),
                         kind='exact_copy' if sha(path) == sha(old) else 'modified_from_parent')
        files[relative] = entry
    record = dict(schema=2, hardware_variant='dma_load_streaming_512kib_2bank',
                  source_commit='42a2e5c', source_state='development_from_frozen_parent',
                  parent_directory=str(PARENT.relative_to(ROOT)),
                  parent_origins_sha256=sha(PARENT / 'manifests/SOURCE_ORIGINS.json'), files=files)
    (FEATURE / 'manifests/SOURCE_ORIGINS.json').write_text(json.dumps(record, indent=2) + '\n')
    print('STREAMING_SOURCE_ORIGINS_RECORDED files=' + str(len(files)))


if __name__ == '__main__':
    main()
