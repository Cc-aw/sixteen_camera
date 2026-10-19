#!/usr/bin/env python3
"""Record local source bytes with both immutable merge parents."""
import hashlib
import json
from pathlib import Path
import subprocess

FEATURE = Path(__file__).resolve().parents[1]
ROOT = FEATURE.parents[2]
PARENTS = [FEATURE.parent / 'activation_sram_512kib_2bank',
           FEATURE.parent / 'dma_load_streaming_512kib_2bank']


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    files = {}
    for path in sorted(FEATURE.rglob('*')):
        relative = str(path.relative_to(FEATURE))
        if (not path.is_file() or '__pycache__' in path.parts or
                relative.startswith('validation/') or 'build' in path.relative_to(FEATURE).parts or
                path.name == 'config.local.mk' or relative == 'manifests/SOURCE_ORIGINS.json'):
            continue
        if path.is_symlink():
            raise SystemExit('Source symlink refused: ' + relative)
        candidates = [p / relative for p in PARENTS if (p / relative).is_file()]
        exact = [p for p in candidates if sha(p) == sha(path)]
        source = (exact or candidates or [None])[0]
        entry = dict(sha256=sha(path), kind='new_file')
        if source is not None:
            entry.update(source=str(source.relative_to(ROOT)), source_sha256=sha(source),
                         kind='exact_copy' if exact else 'merged_or_adapted')
        entry['parent_versions'] = [{ 'path': str(p.relative_to(ROOT)), 'sha256': sha(p)} for p in candidates]
        files[relative] = entry
    record = dict(schema=3, hardware_variant=FEATURE.name,
                  source_commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
                  source_state='merged_from_two_frozen_parents',
                  parents=[dict(directory=str(p.relative_to(ROOT)),
                                source_origins_sha256=sha(p/'manifests/SOURCE_ORIGINS.json')) for p in PARENTS],
                  files=files)
    (FEATURE/'manifests/SOURCE_ORIGINS.json').write_text(json.dumps(record,indent=2)+'\n')
    print('STREAM_ASRAM_SOURCE_ORIGINS=PASS files='+str(len(files)))


if __name__ == '__main__':
    main()
