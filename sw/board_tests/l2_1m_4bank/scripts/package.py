#!/usr/bin/env python3
"""Build identity and ELF/dependency auditing confined to this package."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shlex
import subprocess

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / 'build'
ELFS = {'smoke': 'l2_smoke.elf', 'reference': 'yolov5_reference.elf', 'diagnostic': 'yolov5_diagnostic.elf'}


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def write_json(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2) + '\n')


def local(path):
    path = Path(path)
    if not path.is_absolute():
        path = ROOT / path
    if not path.resolve().is_relative_to(ROOT):
        raise ValueError('Package-external file refused: ' + str(path))
    return path


def sources():
    result = {}
    for path in sorted(ROOT.rglob('*')):
        relative = path.relative_to(ROOT)
        if relative.parts[0] in ('build', 'logs', 'validation') or '__pycache__' in relative.parts:
            continue
        if relative.name == 'config.local.mk' or path.suffix in ('.bit', '.pyc'):
            continue
        if path.is_symlink():
            raise ValueError('Symlinks are not permitted: ' + str(relative))
        if path.is_file():
            result[str(relative)] = sha(path)
    return result


def inputs():
    target = json.loads((ROOT / 'hardware/target.json').read_text())
    bit = local(target['bitstream'])
    if sha(bit) != target['bitstream_sha256']:
        raise ValueError('Copied bitstream differs from the four-bank target')
    if sha(ROOT / 'hardware/GENERATION_CONTEXT.json') != target['generation_context_sha256']:
        raise ValueError('Hardware generation context changed')
    lock = json.loads((ROOT / 'model/sources.lock.json').read_text())
    for item in lock['sources']:
        if sha(local(item['path'])) != item['sha256']:
            raise ValueError('Frozen local model changed: ' + item['path'])
    origins = json.loads((ROOT / 'SOURCE_ORIGINS.json').read_text())
    for item in origins['files']:
        name = item['local_path']
        if name.startswith(('reference/', 'include/', 'hardware/', 'model/')):
            if sha(local(name)) != item['original_sha256']:
                raise ValueError('Copied reference input changed: ' + name)
    return target


def identity():
    target = inputs()
    cross = os.environ.get('CROSS', 'riscv64-unknown-elf-')
    compiler = subprocess.check_output([cross + 'gcc', '--version'], text=True).splitlines()[0]
    config = {'compiler': compiler, 'sources': sources(), 'flags': os.environ.get('L2_CFLAGS', ''),
              'architecture': os.environ.get('L2_ARCH', ''), 'compile_directory': str(ROOT)}
    build_id = hashlib.sha256(json.dumps(config, sort_keys=True).encode()).hexdigest()
    return target, config, build_id


def prepare():
    target, config, build_id = identity()
    directory = BUILD / 'generated'
    directory.mkdir(parents=True, exist_ok=True)
    text = '#define L2_BUILD_ID "' + build_id + '"\n#define L2_SOURCE_REVISION "' + target['source_revision'] + '"\n'
    header = directory / 'build_id.h'
    if not header.exists() or header.read_text() != text:
        header.write_text(text)
    write_json(BUILD / 'prepared_identity.json', dict(build_id=build_id, config=config))
    print('L2_BOARD_PREPARE=PASS build_id=' + build_id + ' board_accessed=0')


def dependency_audit(cross):
    toolchain = Path(subprocess.check_output([cross + 'gcc', '-print-libgcc-file-name'], text=True).strip()).resolve().parents[3]
    count = 0
    for dep in (BUILD / 'obj').glob('*.d'):
        body = dep.read_text().replace('$(ROOT)', str(ROOT)).replace('\\\n', '')
        first = body.split('\n', 1)[0].split(':', 1)[1]
        for name in shlex.split(first):
            path = Path(name).resolve()
            if not path.is_relative_to(ROOT) and not path.is_relative_to(toolchain):
                raise ValueError('ELF reads another project directory: ' + str(path))
            count += 1
    if not count:
        raise ValueError('No compiler dependency evidence')
    return count


def record():
    target, config, build_id = identity()
    prepared = json.loads((BUILD / 'prepared_identity.json').read_text())
    if prepared['build_id'] != build_id:
        raise ValueError('Sources changed during build; rebuild')
    cross = os.environ.get('CROSS', 'riscv64-unknown-elf-')
    for mode, validator in [('reference', 'check_elf.py'), ('diagnostic', 'check_boundary_elf.py')]:
        command = ['python3', str(ROOT / 'scripts' / validator), str(BUILD / ELFS[mode]), '--three-way']
        if mode == 'diagnostic':
            command.append('--diagnostic')
        subprocess.run(command, check=True)
    artifacts = {}
    for mode, name in ELFS.items():
        path = BUILD / name
        dis = subprocess.check_output([cross + 'objdump', '-d', str(path)], text=True)
        (path.with_suffix('.dis')).write_text(dis)
        strings = subprocess.check_output([cross + 'strings', str(path)], text=True)
        if 'test=' + mode + ',build_id=' + build_id not in strings:
            raise ValueError('ELF identity mismatch: ' + mode)
        for line in subprocess.check_output([cross + 'readelf', '-lW', str(path)], text=True).splitlines():
            if line.strip().startswith('LOAD '):
                fields = line.split(); address, size = int(fields[3], 16), int(fields[5], 16)
                if not 0x82000000 <= address <= address + size <= 0xa0000000:
                    raise ValueError('ELF outside DDR test allocation')
        if mode == 'smoke':
            routes = [int(word, 16) & 127 for word in re.findall(r'^\s*[0-9a-f]+:\s+([0-9a-f]{8})\s', dis, re.M)]
            if any(op in (0x0b, 0x2b, 0x5b, 0x7b) for op in routes):
                raise ValueError('CPU smoke test unexpectedly issues RoCC commands')
            trap = dis.split('<trap_entry>:', 1)[1].split('\n\n', 1)[0]
            if re.search(r'^\s*[0-9a-f]+:\s+[0-9a-f]+\s+v[a-z0-9]+\b', trap, re.M):
                raise ValueError('Smoke IRQ changes RVV registers')
        artifacts[mode] = dict(path='build/' + name, sha256=sha(path), bytes=path.stat().st_size,
                               disassembly_sha256=sha(path.with_suffix('.dis')))
    dependencies = dependency_audit(cross)
    for dep in (BUILD / 'obj').glob('*.d'):
        dep.write_text(dep.read_text().replace(str(ROOT) + '/', '$(ROOT)/'))
    manifest = dict(schema=1, build_id=build_id, source_revision=target['source_revision'],
                    sources=config['sources'], compiler=config['compiler'], artifacts=artifacts,
                    target=target, dependency_entries=dependencies,
                    board_accessed=False, board_validation='NOT_RUN', performance='NOT_MEASURED')
    compat = BUILD / 'program/libdigilent_ipc_compat.so'
    manifest['host_artifacts'] = {'digilent_ipc_compat': dict(path=str(compat.relative_to(ROOT)), sha256=sha(compat))}
    write_json(BUILD / 'manifest.json', manifest)
    print('L2_BOARD_BUILD=PASS self_contained=1 tests=3 board_accessed=0')


def check():
    target = inputs()
    manifest = json.loads((BUILD / 'manifest.json').read_text())
    if sources() != manifest['sources'] or target != manifest['target']:
        raise ValueError('Local inputs changed; run make all')
    for artifact in list(manifest['artifacts'].values()) + list(manifest.get('host_artifacts', {}).values()):
        if sha(local(artifact['path'])) != artifact['sha256']:
            raise ValueError('ELF changed: ' + artifact['path'])
    print('L2_BOARD_AUDIT=PASS self_contained=1 board_accessed=0')
    return manifest


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=('prepare', 'record', 'check'))
    args = parser.parse_args()
    {'prepare': prepare, 'record': record, 'check': check}[args.action]()


if __name__ == '__main__':
    main()
