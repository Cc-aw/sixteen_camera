#!/usr/bin/env python3
"""Offline executable/provenance audit; never accesses hardware."""
import json
import os
from pathlib import Path
import re
import subprocess
import sys

from parallel_cache_plan import sha

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT.parents[2]
OUT = Path(os.environ.get('FRONTEND_BUILD', PROJECT / 'build/firmware/first-layer-s2d'))
ELF = OUT / 'yolov5_first_layer_s2d.elf'
CROSS = os.environ.get('CROSS', 'riscv64-unknown-elf-')


def main():
    def run(tool, *args):
        return subprocess.check_output([CROSS + tool, *args, str(ELF)], text=True)
    assert '0x82000000' in run('readelf', '-hW'), 'unexpected entry'
    dis = run('objdump', '-d')
    for op in ('vlseg6e8.v', 'vssseg6e8.v'):
        assert op in dis, ('RVV packing instruction missing', op)
    routes = {op: set() for op in (0x0b, 0x2b, 0x5b, 0x7b)}
    for word in re.findall(r'^\s*[0-9a-f]+:\s+([0-9a-f]{8})\s', dis, re.M):
        ins = int(word, 16)
        if ins & 127 in routes:
            routes[ins & 127].add(ins >> 25)
        if ins & 127 == 0x73:
            assert not 0x7c0 <= ins >> 20 <= 0x7cf, 'old scheduler CSR'
    assert all(routes[op] == {7, 26, 126} for op in (0x0b, 0x2b, 0x5b)), routes
    assert routes[0x7b] == {32 * lane + op for lane in range(3) for op in (0, 1, 2, 3, 5)}, routes
    strings = run('strings')
    for marker in ('S2D1,BUILD', 'scope=first_conv', 'prepacked', 'rvv_online', 'parallel_speedup_x1000=',
                   'serial_gain_x1000=', 'parallel_gain_x1000=', 'full_output_bit_exact=1'):
        assert marker in strings, marker
    trap = dis.split('<trap_entry>:', 1)[1].split('\n\n', 1)[0]
    assert not re.search(r'^\s*[0-9a-f]+:\s+[0-9a-f]+\s+v[a-z0-9]+\b', trap, re.M)
    symbols = run('nm', '-S')
    for name in ('packed', 'outputs', 'gold', 'first_layer_s2d_rvv'):
        assert re.search(r'\b' + name + r'(?:\.[\w.]+)?$', symbols, re.M), name
    for line in run('readelf', '-lW').splitlines():
        if line.strip().startswith('LOAD '):
            f = line.split(); address, size = int(f[3], 16), int(f[5], 16)
            assert 0x82000000 <= address and address + size <= 0xa0000000, line
    files = [ROOT / name for name in (
        'first-layer-s2d.mk', 'src/first_layer_s2d_main.c', 'include/first_layer_s2d.h',
        'scripts/first_layer_s2d_prepare.py', 'scripts/check_first_layer_s2d.py',
        'include/gemmini_frontend.h', 'include/config.h', 'include/platform.h',
        'src/support.c', 'src/irq.c', 'src/start.S', 'src/link.ld')]
    files += [OUT / name for name in ('native/inputs.c', 'native/include/gemmini_params.h',
              'generated/first_layer_s2d_data.inc', 'generated/first_layer_s2d.json')]
    files += [PROJECT / 'hw/manifests/current.json',
              PROJECT / 'sw/models/yolov5nu/frozen/frontend_v33/sources.lock.json', ELF]
    evidence = dict(schema=1, status='OFFLINE_ELF_PASS_BOARD_PENDING',
                    hashes={str(p.relative_to(PROJECT)): sha(p.read_bytes()) for p in files})
    target = OUT / 'elf_audit.json'
    if '--record' in sys.argv:
        target.write_text(json.dumps(evidence, indent=2) + '\n')
    else:
        assert json.loads(target.read_text()) == evidence, 'ELF/source changed since build; rebuild benchmark'
    print('S2D_ELF_AUDIT_PASS rvv=1 serial=1 parallel=3 board_executed=0')


if __name__ == '__main__':
    main()
