"""Local identities and bounded parallel file operations for this hardware version."""
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
import os
from pathlib import Path
import shutil

ROOT = Path(__file__).resolve().parents[1]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def baseline():
    return json.loads((ROOT / 'manifests/BASELINE.json').read_text())


def hashes(base, names):
    names = sorted(names)
    with ThreadPoolExecutor(max_workers=16) as pool:
        return dict(zip(names, pool.map(lambda name: sha(base / name), names)))


def scala_hashes(source):
    names = [str(p.relative_to(source)) for folder in ('generators', 'fpga/src')
             for p in (source / folder).rglob('*.scala') if 'target' not in p.parts]
    return hashes(source, names)


def identity(sources):
    original = baseline()['baseline_context']
    inputs = dict(config=original['config'], activation_sram_enabled=True,
                  dma_load_streaming_enable=True, effective_scala=sources,
                  build_sbt_sha256=sha(ROOT / 'source/chipyard/build.sbt'),
                  command_fifo_depth=16, command_fetch_entries=4,
                  command_physical_max_get_bytes=64)
    return hashlib.sha256(json.dumps(inputs, sort_keys=True).encode()).hexdigest()


def copy_tree(source, destination):
    """Copy inputs, never share writable build caches with the source project."""
    destination.mkdir(parents=True, exist_ok=False)
    files = []
    for directory, folders, names in os.walk(source):
        relative = Path(directory).relative_to(source)
        for name in folders:
            (destination / relative / name).mkdir(exist_ok=True)
        files.extend((Path(directory) / name, destination / relative / name) for name in names
                     if name not in ('sbt.boot.lock', 'update.log') and not name.endswith('.lock'))
    with ThreadPoolExecutor(max_workers=16) as pool:
        list(pool.map(lambda pair: shutil.copyfile(*pair), files))


def new_output(path):
    path = path.resolve()
    if path != ROOT / 'generated' and (ROOT / 'build') not in path.parents:
        raise ValueError('Use generated/ or a new directory below this version build/')
    if path.exists():
        raise ValueError('Output exists; choose a new directory: ' + str(path))
    return path
