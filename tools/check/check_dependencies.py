#!/usr/bin/env python3
"""Check vendored source integrity, firmware dependency closure and tools."""
from pathlib import Path
import argparse
import hashlib
import json
import os
import shutil
import sys

ROOT = Path(__file__).resolve().parents[2]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--sources-only', action='store_true')
    args = parser.parse_args()
    failures = []
    snapshots = []
    for name in ['sw/third_party/sources.lock.json', 'sw/models/yolov5nu/sources.lock.json']:
        snapshots.extend(json.loads((ROOT / name).read_text())['sources'])
    for item in snapshots:
        path = ROOT / item['path']
        if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest() != item['sha256']:
            failures.append(f"Source hash mismatch: {item['path']}")
    count = 0
    # -MMD omits toolchain/system headers. Every listed dependency must be local.
    for depfile in (ROOT / 'build/firmware').rglob('*.d'):
        for word in depfile.read_text().replace('\\\n', ' ').split():
            if word.endswith(':'):
                continue
            path = Path(word)
            if not path.is_absolute():
                path = ROOT / 'sw' / path
            if not path.resolve().is_relative_to(ROOT):
                failures.append(f'External firmware source: {path} ({depfile})')
        count += 1
    print(f"SOURCE_SNAPSHOTS={len(snapshots)} DEPENDENCY_FILES={count}")
    if not args.sources_only:
        prefix = os.environ.get('TOOLCHAIN') or 'riscv64-unknown-elf-'
        commands = ['make', 'cc', 'python3', 'tclsh', 'flock', 'iverilog', 'vvp', 'verilator',
                    prefix + 'gcc', prefix + 'objcopy', prefix + 'objdump', prefix + 'size',
                    os.environ.get('VIVADO_BIN') or 'vivado',
                    os.environ.get('OPENOCD_BIN') or 'openocd',
                    os.environ.get('GDB_BIN') or 'riscv64-unknown-elf-gdb']
        for command in commands:
            path = shutil.which(command)
            print(f"TOOL {command}: {path or 'MISSING'}")
            if not path:
                failures.append(f'Missing tool: {command}')
        try:
            import numpy
            print(f'NUMPY={numpy.__version__}')
        except ImportError:
            failures.append('Missing numpy: see tests/requirements.txt')
    if failures:
        print('\n'.join(failures), file=sys.stderr)
        return 1
    print('DEPENDENCIES=PASS')
    return 0


if __name__ == '__main__':
    sys.exit(main())
