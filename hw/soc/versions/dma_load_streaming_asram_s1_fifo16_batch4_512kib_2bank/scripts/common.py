"""Local identities and bounded parallel file operations for this hardware version."""
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
import os
from pathlib import Path
import shutil
import sys
from functools import lru_cache

ROOT = Path(__file__).resolve().parents[1]
REPO = ROOT.parents[3]
sys.path.insert(0, str(REPO / 'tools/build'))
from source_overlay import prepare as prepare_sources, verify_recorded_artifact


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def baseline():
    return json.loads((ROOT / 'manifests/BASELINE.json').read_text())


def hashes(base, names):
    names = sorted(names)
    with ThreadPoolExecutor(max_workers=16) as pool:
        return dict(zip(names, pool.map(lambda name: sha(base / name), names)))


def scala_hashes(source):
    if source == source_root():
        return {name: value for name, value in prepared_sources().files.items()
                if name.endswith('.scala') and name.startswith(('generators/', 'fpga/src/')) and 'target' not in Path(name).parts}
    # Prune SBT outputs before traversal: they can contain far more files
    # than the source tree. Still detect added Scala sources in new folders.
    def scan(directory):
        folders, found = [], []
        with os.scandir(directory) as entries:
            for entry in entries:
                if entry.is_dir(follow_symlinks=False):
                    if entry.name != 'target':
                        folders.append(Path(entry.path))
                elif entry.name.endswith('.scala') and entry.is_file():
                    found.append(str(Path(entry.path).relative_to(source)))
        return folders, found
    names = []
    with ThreadPoolExecutor(max_workers=16) as pool:
        directories = [source / folder for folder in ('generators', 'fpga/src')]
        while directories:
            next_directories = []
            for folders, found in pool.map(scan, directories):
                next_directories.extend(folders)
                names.extend(found)
            directories = next_directories
    return hashes(source, names)


def identity(sources):
    original = baseline()['baseline_context']
    inputs = dict(config=original['config'], activation_sram_enabled=True,
                  dma_load_streaming_enable=True, effective_scala=sources,
                  build_sbt_sha256=sha(source_root() / 'build.sbt'),
                  command_fifo_depth=16, command_fetch_entries=4,
                  command_physical_max_get_bytes=64, build_inputs_sha256=build_inputs(),
                  source_recipe_sha256=prepared_sources().recipe_sha256)
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

@lru_cache(maxsize=1)
def prepared_sources():
    return prepare_sources(ROOT)


def source_root():
    return prepared_sources().root


def build_inputs():
    """Hash effective sources under stable logical names, plus the actual recipe."""
    result = {'source/chipyard/' + name: value for name, value in prepared_sources().files.items()}
    names = []
    for folder in ('source', 'board', 'scripts', 'tests/abi', 'manifests/donor', 'patches', 'overlay'):
        for directory, folders, files in os.walk(ROOT / folder):
            if Path(directory) == ROOT / 'source':
                folders[:] = [name for name in folders if name != 'chipyard']
            folders[:] = [name for name in folders if name != '__pycache__']
            names.extend(str((Path(directory) / name).relative_to(ROOT)) for name in files if not name.endswith('.pyc'))
    for name in ('Makefile', 'config.example.mk', 'manifests/BASELINE.json',
                 'manifests/TEAM_SOURCE.json', 'manifests/SOFTWARE_SOURCES.json', 'manifests/SOURCE_OVERLAY.json'):
        if (ROOT / name).is_file():
            names.append(name)
    result.update(hashes(ROOT, names))
    result['tools/build/source_overlay.py'] = sha(REPO / 'tools/build/source_overlay.py')
    return result


def audit_identity(context_path, sources):
    context = json.loads(context_path.read_text())
    current = build_inputs()
    digest = identity(sources)
    if context['source_identity_sha256'] == digest:
        if context.get('build_inputs_sha256') != current:
            raise ValueError('Generated build closure differs from the current source recipe')
        return digest
    return verify_recorded_artifact(ROOT, context_path, current, prepared_sources())
