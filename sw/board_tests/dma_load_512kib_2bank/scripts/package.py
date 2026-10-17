#!/usr/bin/env python3
"""Local source identity, hardware binding and ELF/dependency audit."""
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
ELFS = {'first': 'yolov5_dma_load_first.elf', 'model': 'yolov5_dma_load_model.elf'}


def sha(path):
    digest = hashlib.sha256()
    with Path(path).open('rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(block)
    return digest.hexdigest()


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
        if relative.parts[0] in ('build', 'logs') or '__pycache__' in relative.parts:
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
    context = ROOT / 'hardware/GENERATION_CONTEXT.json'
    if sha(local(target['bitstream'])) != target['bitstream_sha256']:
        raise ValueError('Local bitstream does not match the DMA candidate')
    if sha(context) != target['generation_context_sha256']:
        raise ValueError('Hardware generation context changed')
    data = json.loads(context.read_text())
    if (data['dma_load_build_id'] != target['hardware_build_id'] or
            data['l2_banks'] != 2 or data['l2_capacity_kib'] != 512 or
            not data['dma_load_runtime_enable'] or data['dma_load_control_version'] != 1):
        raise ValueError('Expected runtime DMA / 512 KiB / two-bank hardware')
    lock = json.loads((ROOT / 'model/sources.lock.json').read_text())
    for item in lock['sources']:
        if sha(local(item['path'])) != item['sha256']:
            raise ValueError('Frozen local model changed: ' + item['path'])
    origins = json.loads((ROOT / 'SOURCE_ORIGINS.json').read_text())
    for item in origins['files']:
        if item['local_path'].startswith(('model/', 'hardware/')):
            if sha(local(item['local_path'])) != item['original_sha256']:
                raise ValueError('Copied input changed: ' + item['local_path'])
    return target


def identity():
    target = inputs()
    cross = os.environ.get('CROSS', 'riscv64-unknown-elf-')
    compiler = subprocess.check_output([cross + 'gcc', '--version'], text=True).splitlines()[0]
    config = dict(compiler=compiler, sources=sources(), flags=os.environ.get('DMA_CFLAGS', ''),
                  architecture=os.environ.get('DMA_ARCH', ''))
    build_id = hashlib.sha256(json.dumps(config, sort_keys=True).encode()).hexdigest()
    return target, config, build_id


def prepare():
    target, config, build_id = identity()
    directory = BUILD / 'generated'
    directory.mkdir(parents=True, exist_ok=True)
    headers = {'board_identity.h': '#define DMA_BOARD_BUILD_ID "' + build_id + '"\n',
               'dma_load_identity.h': '#define DMA_LOAD_EXPECTED_BUILD_ID UINT64_C(0x' +
               target['hardware_build_id'] + ')\n'}
    for name, text in headers.items():
        path = directory / name
        if not path.exists() or path.read_text() != text:
            path.write_text(text)
    write_json(BUILD / 'prepared_identity.json', dict(build_id=build_id, config=config))
    print('DMA_BOARD_PREPARE=PASS build_id=' + build_id + ' board_accessed=0')


def generated():
    return {str(p.relative_to(ROOT)): sha(p) for p in sorted((BUILD / 'generated').rglob('*'))
            if p.is_file()}


def dependency_audit():
    count = 0
    for dep in (BUILD / 'obj').glob('*.d'):
        body = dep.read_text().replace('$(ROOT)', str(ROOT)).replace('\\\n', '')
        first = body.split('\n', 1)[0].split(':', 1)[1]
        for name in shlex.split(first):
            path = Path(name).resolve()
            if not path.is_relative_to(ROOT):
                raise ValueError('ELF reads another project directory: ' + str(path))
            count += 1
    if not count:
        raise ValueError('No compiler dependency evidence')
    return count


def audit_elf(path, kind, target, build_id, cross):
    data = path.read_bytes()
    prefix = b'DMALF1' if kind == 'first' else b'DMAL1'
    for marker in (b'BUILD', b'RESULT', b'COUNTERS', b'SUMMARY', b'PASS'):
        record_prefix = b'S2D1' if kind == 'first' and marker == b'RESULT' else prefix
        if record_prefix + b',' + marker not in data:
            raise ValueError('Missing ELF marker: ' + str(marker))
    suite=b'suite=short_first_ablation' if kind=='first' else b'suite=short_ablation'
    if suite not in data or b'spad_assembled' not in data:
        raise ValueError('ELF lacks the short-suite/fourth-mode contract')
    if build_id.encode() not in data or int(target['hardware_build_id'], 16).to_bytes(8, 'little') not in data:
        raise ValueError('ELF software/hardware identity mismatch')
    if kind == 'model' and any(marker not in data for marker in
            (b'ppu_run_overflow', b'ppu_result_metadata_or_error', b'DMAL1,BATCH_BEGIN', b'ppu_runs=monotonic',
             b'failure_diagnostics=1', b'DMAL1,CHECK_FAILED', b'ATSOFT1,PPU_DIFF')):
        raise ValueError('ELF lacks monotonic numbering, PPU validation or failure diagnostics')
    dis = subprocess.check_output([cross + 'objdump', '-d', str(path)], text=True)
    words = [int(word, 16) for word in re.findall(r'^\s*[0-9a-f]+:\s+([0-9a-f]{8})\s', dis, re.M)]
    control = {word >> 25 for word in words if word & 127 == 0x7b}
    if not {9, 41, 73} <= control:
        raise ValueError('Missing runtime mode setters on all three lanes')
    if any(word & 127 == 0x73 and 0x7c0 <= word >> 20 <= 0x7cf for word in words):
        raise ValueError('Legacy scheduler CSR in ELF')
    trap = dis.split('<trap_entry>:', 1)[1].split('\n\n', 1)[0]
    if re.search(r'^\s*[0-9a-f]+:\s+[0-9a-f]+\s+v[a-z0-9]+\b', trap, re.M):
        raise ValueError('IRQ handler changes RVV registers')
    if '0x82000000' not in subprocess.check_output([cross + 'readelf', '-hW', str(path)], text=True):
        raise ValueError('Unexpected ELF entry')
    for line in subprocess.check_output([cross + 'readelf', '-lW', str(path)], text=True).splitlines():
        if line.strip().startswith('LOAD '):
            fields = line.split(); address, size = int(fields[3], 16), int(fields[5], 16)
            if not 0x82000000 <= address <= address + size <= 0xa0000000:
                raise ValueError('ELF outside DDR test allocation')
    path.with_suffix('.dis').write_text(dis)


def record():
    target, config, build_id = identity()
    if json.loads((BUILD / 'prepared_identity.json').read_text())['build_id'] != build_id:
        raise ValueError('Sources changed during build; rebuild')
    cross = os.environ.get('CROSS', 'riscv64-unknown-elf-')
    artifacts = {}
    for kind, name in ELFS.items():
        path = BUILD / name
        audit_elf(path, kind, target, build_id, cross)
        artifacts[kind] = dict(path=str(path.relative_to(ROOT)), sha256=sha(path), bytes=path.stat().st_size,
                               disassembly_sha256=sha(path.with_suffix('.dis')))
    count = dependency_audit()
    for dep in (BUILD / 'obj').glob('*.d'):
        dep.write_text(dep.read_text().replace(str(ROOT) + '/', '$(ROOT)/'))
    compat = BUILD / 'program/libdigilent_ipc_compat.so'
    host_artifacts = {'digilent_ipc_compat': dict(path=str(compat.relative_to(ROOT)), sha256=sha(compat))}
    write_json(BUILD / 'manifest.json', dict(schema=1, build_id=build_id,
               sources=config['sources'], compiler=config['compiler'], artifacts=artifacts,
               host_artifacts=host_artifacts,
               generated=generated(), target=target, dependency_entries=count,
               board_accessed=False, board_validation='NOT_RUN', performance='NOT_MEASURED'))
    print('DMA_BOARD_BUILD=PASS self_contained=1 tests=2 board_accessed=0')


def check():
    target = inputs()
    manifest = json.loads((BUILD / 'manifest.json').read_text())
    if sources() != manifest['sources'] or target != manifest['target'] or generated() != manifest['generated']:
        raise ValueError('Local inputs changed; run make all')
    for artifact in list(manifest['artifacts'].values()) + list(manifest['host_artifacts'].values()):
        if sha(local(artifact['path'])) != artifact['sha256']:
            raise ValueError('Build artifact changed: ' + artifact['path'])
    print('DMA_BOARD_AUDIT=PASS self_contained=1 board_accessed=0')
    return manifest


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=('prepare', 'record', 'check'))
    args = parser.parse_args()
    {'prepare': prepare, 'record': record, 'check': check}[args.action]()


if __name__ == '__main__':
    main()
