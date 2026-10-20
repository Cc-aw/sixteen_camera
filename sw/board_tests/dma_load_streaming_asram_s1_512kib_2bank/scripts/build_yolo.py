#!/usr/bin/env python3
"""Audit the local full-graph DDR/ASRAM inference ELFs and generated inputs."""
import argparse
import json
import os
from pathlib import Path
import re
import shlex
import subprocess

from build import ROOT, BUILD, check as base_check, sha, write

ELFS = {'model': 'yolov5_asram_model.elf', 'diagnostic': 'yolov5_asram_diagnostic.elf'}


def generated():
    return {str(p.relative_to(ROOT)): sha(p) for p in sorted((BUILD/'yolo_generated').rglob('*')) if p.is_file()}


def record():
    base = base_check()
    cross = os.environ.get('CROSS', 'riscv64-unknown-elf-')
    artifacts = {}
    for kind, name in ELFS.items():
        path = BUILD/name
        data = path.read_bytes()
        for marker in (b'ASRY1,BUILD', b'ASRY1,PROFILE', b'ASRY1,BATCH_BEGIN', b'ASRY1,RESULT',
                       b'ASRY1,ASRAM', b'ASRY1,DMA', b'ASRY1,SUMMARY', b'ASRY1,PASS',
                       b'activation_memory_commit', b'storage_plan_math_changed', b'local_arena_not_used',
                       b'ppu_run_overflow', b'ATSOFT1,PPU_DIFF', base['build_id'].encode(),
                       int(base['config']['target']['hardware_build_id'],16).to_bytes(8,'little')):
            if marker not in data: raise ValueError('Missing YOLO identity/coverage marker: '+repr(marker))
        if kind=='diagnostic' and any(x not in data for x in
                (b'ASRY1,RAW_CHECK', b'raw_pad_mismatch', b'raw_head_mismatch')):
            raise ValueError('Missing raw tensor/Head diagnostic')
        dis = subprocess.check_output([cross+'objdump','-d',str(path)],text=True)
        path.with_suffix('.dis').write_text(dis)
        words = [int(x,16) for x in re.findall(r'^\s*[0-9a-f]+:\s+([0-9a-f]{8})\s',dis,re.M)]
        controls = {word>>25 for word in words if word&127==0x7b}
        if not {3,9,35,41,67,73}<=controls: raise ValueError('Missing three-lane identity/mode commands')
        if any(w&127==0x73 and 0x7c0<=w>>20<=0x7cf for w in words): raise ValueError('Legacy scheduling CSR')
        for opcode in (0x0b,0x2b,0x5b):
            if not {0,2,3,8,15}<={w>>25 for w in words if w&127==opcode}:
                raise ValueError('Missing native inference commands')
        trap=dis.split('<trap_entry>:',1)[1].split('\n\n',1)[0]
        if re.search(r'^\s*[0-9a-f]+:\s+[0-9a-f]+\s+v[a-z0-9]+\b',trap,re.M):
            raise ValueError('IRQ changes RVV state')
        if '0x82000000' not in subprocess.check_output([cross+'readelf','-hW',str(path)],text=True):
            raise ValueError('Wrong YOLO entry')
        segments=[]
        for line in subprocess.check_output([cross+'readelf','-lW',str(path)],text=True).splitlines():
            if line.strip().startswith('LOAD '):
                f=line.split();address,size=int(f[3],16),int(f[5],16)
                if not 0x82000000<=address<=address+size<=0xa0000000:
                    raise ValueError('YOLO ELF outside private DDR allocation')
                segments.append(dict(address=address,memory_bytes=size,file_bytes=int(f[4],16)))
        if not all(x in dis for x in ('vsetvli','vle8.v','vse8.v','pmpaddr1','fence')):
            raise ValueError('Missing RVV/PMP/completion code')
        artifacts[kind]=dict(path=str(path.relative_to(ROOT)),sha256=sha(path),bytes=path.stat().st_size,
                             load_segments=segments,disassembly_sha256=sha(path.with_suffix('.dis')))
    dependencies=0
    for path in (BUILD/'yolo_obj').glob('*.d'):
        body=path.read_text().replace('\\\n','').split('\n',1)[0].split(':',1)[1]
        for name in shlex.split(body):
            if not Path(name).resolve().is_relative_to(ROOT):raise ValueError('YOLO build reads another feature')
            dependencies+=1
    if not dependencies:raise ValueError('Missing YOLO compiler dependencies')
    write(BUILD/'yolo_manifest.json',dict(schema=1,build_id=base['build_id'],config=base['config'],
          artifacts=artifacts,generated=generated(),dependency_entries=dependencies,
          board_validation='NOT_RUN',performance='NOT_MEASURED'))
    print('YOLO_ASRAM_ELF_AUDIT=PASS self_contained=1 elfs=2 board_accessed=0')


def check():
    base=base_check();manifest=json.loads((BUILD/'yolo_manifest.json').read_text())
    if manifest['build_id']!=base['build_id'] or manifest['generated']!=generated():
        raise ValueError('Stale YOLO build; run make all')
    for artifact in manifest['artifacts'].values():
        if sha(ROOT/artifact['path'])!=artifact['sha256']:raise ValueError('YOLO ELF changed')
    print('YOLO_ASRAM_AUDIT=PASS board_accessed=0')
    return manifest


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('action',choices=('record','check'))
    {'record':record,'check':check}[p.parse_args().action]()
