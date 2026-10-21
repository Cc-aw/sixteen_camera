#!/usr/bin/env python3
"""Restore pinned source layers into ignored workspaces without editing a baseline."""
import argparse
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass
import fcntl
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import shutil
import subprocess
import tarfile
import tempfile


def sha(path):
    with Path(path).open('rb') as source:
        return hashlib.file_digest(source, 'sha256').hexdigest() if hasattr(hashlib, 'file_digest') else hashlib.sha256(source.read()).hexdigest()


def digest_map(files):
    return hashlib.sha256(json.dumps(files, sort_keys=True).encode()).hexdigest()


def relative(name):
    path = PurePosixPath(name)
    if not name or path.is_absolute() or '..' in path.parts or '\\' in name or str(path) != name:
        raise ValueError('Unsafe source recipe path: ' + name)
    return Path(*path.parts)


def tree_hashes(root):
    names = []
    def scan(directory):
        folders, files = [], []
        with os.scandir(directory) as entries:
            for entry in entries:
                if entry.is_symlink():
                    raise ValueError('Source symlink refused: ' + entry.path)
                if entry.is_dir(follow_symlinks=False):
                    folders.append(Path(entry.path))
                elif entry.is_file(follow_symlinks=False):
                    files.append(str(Path(entry.path).relative_to(root)))
                else:
                    raise ValueError('Non-regular source entry: ' + entry.path)
        return folders, files
    with ThreadPoolExecutor(max_workers=16) as pool:
        directories = [root] if root.exists() else []
        while directories:
            next_directories = []
            for folders, files in pool.map(scan, directories):
                next_directories.extend(folders)
                names.extend(files)
            directories = next_directories
        names.sort()
        return dict(zip(names, pool.map(lambda name: sha(root / name), names)))


@dataclass
class PreparedSource:
    root: Path
    files: dict
    recipe_sha256: str


def pinned_entries(repo, directory, tree):
    """Use index metadata only when its reconstructed Git tree matches the pin."""
    prefix = directory.rstrip('/') + '/'
    index = subprocess.check_output(['git', '-C', str(repo), 'ls-files', '--stage', '-z', '--', prefix])
    nested = {}
    entries = []
    valid = True
    for record in index.split(b'\0'):
        if not record:
            continue
        metadata, name = record.split(b'\t', 1)
        mode, blob, stage = metadata.decode().split()
        name = name.decode()
        if stage != '0' or not name.startswith(prefix):
            valid = False
            break
        name = name[len(prefix):]
        parts = relative(name).parts
        node = nested
        for part in parts[:-1]:
            node = node.setdefault(part, {})
        node[parts[-1]] = (mode, blob)
        entries.append((name, mode, blob))
    def tree_id(node):
        records = []
        for name, value in sorted(node.items(), key=lambda pair: (pair[0] + ('/' if isinstance(pair[1], dict) else '')).encode()):
            mode, blob = ('40000', tree_id(value)) if isinstance(value, dict) else value
            records.append(mode.encode() + b' ' + name.encode() + b'\0' + bytes.fromhex(blob))
        data = b''.join(records)
        return hashlib.sha1(b'tree ' + str(len(data)).encode() + b'\0' + data).hexdigest()
    if valid and tree_id(nested) == tree:
        return entries
    listing = subprocess.check_output(['git', '-C', str(repo), 'ls-tree', '-rz', tree])
    entries = []
    for record in listing.split(b'\0'):
        if record:
            metadata, name = record.split(b'\t', 1)
            mode, kind, blob = metadata.decode().split()
            if kind != 'blob':
                raise ValueError('Unsupported baseline Git entry')
            entries.append((str(relative(name.decode())), mode, blob))
    return entries


def git_sources(repo, base, destination):
    commit = base['commit']
    directory = str(relative(base['directory']))
    if len(commit) != 40 or any(c not in '0123456789abcdef' for c in commit):
        raise ValueError('Source baseline must name a full Git commit')
    actual = subprocess.check_output(['git', '-C', str(repo), 'rev-parse', commit + ':' + directory], text=True).strip()
    if actual != base['tree']:
        raise ValueError('Pinned baseline Git tree mismatch')
    # A verified local copy avoids thousands of serial loose-object reads on
    # network filesystems. Check every byte against the pinned Git blob IDs;
    # dirty/missing files fall back to exporting the committed objects.
    entries = pinned_entries(repo, directory, actual)
    for name, mode, blob in entries:
        if mode not in ('100644', '100755'):
            raise ValueError('Only regular baseline files are supported')
    def copy_verified(entry):
        name, mode, blob = entry
        target = destination / name
        if target.is_file():
            existing = target.read_bytes()
            if hashlib.sha1(b'blob ' + str(len(existing)).encode() + b'\0' + existing).hexdigest() == blob:
                return
        path = repo / directory / name
        if path.is_symlink():
            raise ValueError('Baseline worktree symlink')
        data = path.read_bytes()
        if hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest() != blob:
            raise ValueError('Baseline worktree blob differs from the pinned commit')
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
        target.chmod(0o755 if mode == '100755' else 0o644)
    try:
        with ThreadPoolExecutor(max_workers=16) as pool:
            list(pool.map(copy_verified, entries))
        return
    except (OSError, ValueError):
        for child in destination.iterdir():
            if child.is_dir():
                shutil.rmtree(child)
            else:
                child.unlink()
    process = subprocess.Popen(['git', '-C', str(repo), 'archive', actual], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    try:
        with tarfile.open(fileobj=process.stdout, mode='r|') as archive:
            for item in archive:
                name = item.name.rstrip('/')
                target = destination / relative(name)
                if item.isdir():
                    target.mkdir(parents=True, exist_ok=True)
                elif item.isfile():
                    target.parent.mkdir(parents=True, exist_ok=True)
                    with archive.extractfile(item) as source, target.open('wb') as output:
                        shutil.copyfileobj(source, output)
                    target.chmod(item.mode & 0o777)
                else:
                    raise ValueError('Only regular baseline files/directories are supported: ' + item.name)
        # tarfile may stop at the first EOF block. Drain archive padding before
        # waiting for Git, otherwise a small stdout pipe can keep Git blocked.
        while process.stdout.read(1024 * 1024):
            pass
        error = process.stderr.read().decode(errors='replace')
        if process.wait() != 0:
            raise ValueError('Cannot export pinned baseline: ' + error)
    finally:
        process.stdout.close()
        process.stderr.close()
        if process.poll() is None:
            process.terminate()
        process.wait()


def baseline_inventory(version, base):
    if 'files_sha256' in base:
        return dict(base['files_sha256'])
    inventory = base['inventory']
    path = version / relative(inventory['file'])
    if sha(path) != inventory['sha256']:
        raise ValueError('Pinned baseline inventory changed')
    data = json.loads(path.read_text())[inventory['key']]
    prefix = inventory['prefix']
    return {name[len(prefix):]: value for name, value in data.items() if name.startswith(prefix)}


def prepare(version, repo=None, chain=()):
    version = Path(version).resolve()
    repo = Path(repo).resolve() if repo is not None else version.parents[3]
    if version in chain:
        raise ValueError('Cyclic source recipe dependency')
    if not version.is_relative_to(repo):
        raise ValueError('Source version must be inside the repository')
    manifest = version / 'manifests/SOURCE_OVERLAY.json'
    recipe = json.loads(manifest.read_text())
    if recipe['schema'] != 1:
        raise ValueError('Unsupported source recipe schema')
    base = recipe['base']
    parent = None
    if base['kind'] == 'version':
        parent_version = repo / relative(base['directory'])
        if sha(parent_version / 'manifests/SOURCE_OVERLAY.json') != base['manifest_sha256']:
            raise ValueError('Pinned parent source recipe changed')
        parent = prepare(parent_version, repo, chain + (version,))
        files = dict(parent.files)
    elif base['kind'] == 'git':
        files = baseline_inventory(version, base)
    else:
        raise ValueError('Unsupported source baseline kind')
    for name in files:
        relative(name)
    inputs = {'manifest': sha(manifest), 'engine': sha(Path(__file__))}
    if parent is not None:
        inputs['parent'] = parent.recipe_sha256
    for item in recipe['patches'] + list(recipe['overlay'].values()):
        path = version / relative(item['file'])
        if sha(path) != item['sha256']:
            raise ValueError('Source patch/overlay changed: ' + item['file'])
        inputs[item['file']] = item['sha256']
    for name, change in recipe['changes'].items():
        relative(name)
        if files.get(name) != change['before']:
            raise ValueError('Patch preimage mismatch: ' + name)
        if change['after'] is None:
            files.pop(name)
        else:
            files[name] = change['after']
    if digest_map(files) != recipe['effective_tree_sha256']:
        raise ValueError('Source recipe inventory mismatch')
    key = digest_map(inputs)
    cache = version / 'build/source_overlay'
    cache.mkdir(parents=True, exist_ok=True)
    destination = cache / key
    with (cache / '.lock').open('a') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        if destination.exists():
            marker = json.loads((destination / 'complete.json').read_text())
            if marker != {'recipe_sha256': key, 'effective_tree_sha256': digest_map(files)} or tree_hashes(destination / 'chipyard') != files:
                raise ValueError('Prepared source cache changed; remove this cache and reconstruct: ' + str(destination))
            return PreparedSource(destination / 'chipyard', files, key)
        with tempfile.TemporaryDirectory(prefix='.prepare-', dir=cache) as temporary:
            stage = Path(temporary) / 'ready'
            source = stage / 'chipyard'
            source.mkdir(parents=True)
            if parent is None:
                git_sources(repo, base, source)
                if tree_hashes(source) != baseline_inventory(version, base):
                    raise ValueError('Exported baseline differs from the pinned inventory')
            else:
                def copy_parent(name):
                    target = source / name
                    target.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(parent.root / name, target)
                with ThreadPoolExecutor(max_workers=16) as pool:
                    list(pool.map(copy_parent, sorted(parent.files)))
            for name, change in recipe['changes'].items():
                path = source / relative(name)
                before = sha(path) if path.exists() else None
                if before != change['before']:
                    raise ValueError('Materialized patch preimage mismatch: ' + name)
            for item in recipe['patches']:
                subprocess.run(['patch', '--batch', '--forward', '--fuzz=0', '-p1', '-d', str(source),
                                '-i', str(version / relative(item['file']))], check=True,
                               stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            for name, item in recipe['overlay'].items():
                target = source / relative(name)
                if target.exists() or recipe['changes'][name]['before'] is not None:
                    raise ValueError('Overlay is reserved for new source files: ' + name)
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(version / relative(item['file']), target)
            if tree_hashes(source) != files:
                raise ValueError('Patched sources differ from the expected complete source tree')
            (stage / 'complete.json').write_text(json.dumps(dict(recipe_sha256=key,
                effective_tree_sha256=digest_map(files)), indent=2) + '\n')
            stage.rename(destination)
    return PreparedSource(destination / 'chipyard', files, key)


def input_changes(before, after):
    return {name: dict(before=before.get(name), after=after.get(name))
            for name in sorted(before.keys() | after.keys()) if before.get(name) != after.get(name)}


def verify_recorded_artifact(version, context_path, current_inputs, prepared):
    """Accept an unchanged pre-migration artifact only with its explicit migration record."""
    migration = json.loads((version / 'manifests/SOURCE_LAYOUT_MIGRATION.json').read_text())
    entry = migration['artifacts'].get(sha(context_path))
    if entry is None:
        raise ValueError('Generated output is not recorded by this source-layout migration')
    context = json.loads(context_path.read_text())
    if (entry['hardware_build_id'] != context['dma_load_build_id'] or
            entry['effective_tree_sha256'] != digest_map(prepared.files)):
        raise ValueError('Recorded artifact/source tree mismatch')
    old = entry['original_build_inputs_sha256']
    if context.get('build_inputs_sha256', old) != old:
        raise ValueError('Recorded original build closure mismatch')
    delta = input_changes(old, current_inputs)
    allowed = ('scripts/', 'patches/', 'overlay/')
    for name in delta:
        if not (name.startswith(allowed) or name in ('Makefile', 'manifests/SOURCE_OVERLAY.json', 'tools/build/source_overlay.py')):
            raise ValueError('Non-recipe input changed for the recorded artifact: ' + name)
    if delta != entry['recipe_changes']:
        raise ValueError('Source reconstruction recipe differs from the recorded migration')
    return context['source_identity_sha256']


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--version', type=Path, required=True)
    args = parser.parse_args()
    result = prepare(args.version)
    print('SOURCE_OVERLAY=PASS files=' + str(len(result.files)) + ' source=' + str(result.root))


if __name__ == '__main__':
    main()
