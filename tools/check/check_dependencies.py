#!/usr/bin/env python3
"""Audit the default S1 source snapshots, local firmware dependencies and tools."""
import argparse
import json
import os
import shutil
import subprocess
import sys
from current_product import ROOT, local_path, product, sha


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--sources-only', action='store_true')
    args = parser.parse_args()
    p = product()
    hw = local_path(p['hardware_directory'])
    sw = local_path(p['software_directory'])
    subprocess.run([sys.executable, '-B', str(hw / 'scripts/audit.py')], check=True)
    lock = json.loads((sw / 'model/sources.lock.json').read_text())['sources']
    for item in lock:
        path = sw / item['path']
        if not path.is_file() or sha(path) != item['sha256']:
            raise ValueError('Frozen software source mismatch: ' + item['path'])
    count = 0
    # Only target firmware objects belong to this closure. Host/Verilator
    # regression caches elsewhere in build/ legitimately use installed tools.
    for depfile in (local_path(p['video_build']) / 'obj').rglob('*.d'):
        for word in depfile.read_text().replace('\\\n', ' ').split():
            if word.endswith(':'):
                continue
            path = (sw / word).resolve()
            if ROOT not in path.parents or not path.is_file():
                raise ValueError('Nonlocal or missing firmware dependency: ' + str(path))
        count += 1
    print('FROZEN_MODEL_SOURCES=%d DEPENDENCY_FILES=%d' % (len(lock), count))
    if not args.sources_only:
        prefix = os.environ.get('CROSS') or os.environ.get('TOOLCHAIN') or 'riscv64-unknown-elf-'
        commands = ['make', 'cc', 'python3', 'tclsh', 'iverilog', 'vvp', 'verilator',
                    prefix + 'gcc', prefix + 'size', os.environ.get('VIVADO_BIN') or 'vivado',
                    os.environ.get('OPENOCD_BIN') or 'openocd',
                    os.environ.get('GDB_BIN') or 'riscv64-unknown-elf-gdb']
        for command in commands:
            if not shutil.which(command):
                raise ValueError('Missing tool: ' + command)
        import numpy
        print('NUMPY=' + numpy.__version__)
    print('DEPENDENCIES=PASS board_accessed=0')


if __name__ == '__main__':
    main()
