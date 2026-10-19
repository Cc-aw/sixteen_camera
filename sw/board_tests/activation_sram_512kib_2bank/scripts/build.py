#!/usr/bin/env python3
"""Self-contained ASRAM board ELF source identity and artifact audit."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shlex
import subprocess

ROOT=Path(__file__).resolve().parents[1]
BUILD=ROOT/'build'
ELF=BUILD/'activation_sram_test.elf'


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def write(path,data):
    path.parent.mkdir(parents=True,exist_ok=True)
    text=json.dumps(data,indent=2)+'\n'
    if not path.exists() or path.read_text()!=text:path.write_text(text)


def sources():
    result={}
    for p in sorted(ROOT.rglob('*')):
        if p.relative_to(ROOT).parts[0] in ('build','logs','validation') or '__pycache__' in p.parts:
            continue
        if p.name=='config.local.mk' or p.suffix=='.pyc':continue
        if p.is_symlink():raise ValueError('Source symlink refused: '+str(p))
        if p.is_file():result[str(p.relative_to(ROOT))]=sha(p)
    return result



def identity():
    target=json.loads((ROOT/'hardware/target.json').read_text())
    if (target['clock_hz']!=100000000 or target['asram_bases']!=[0x20000000,0x20400000,0x20800000] or
        target['physical_bytes_per_bank']!=0x240000 or target['logical_arena_bytes']!=0x21d680 or
        target['control_base']!=0x20c00000 or target['dma_modes']!=
        ['legacy','read_coalesced','read_assembled','spad_assembled'] or
        not re.fullmatch('[0-9a-f]{64}',target['bitstream_sha256'])):
        raise ValueError('Wrong ASRAM hardware geometry/capability')
    build_id=target['hardware_build_id']
    if not re.fullmatch('[0-9a-f]{16}',build_id) or not int(build_id,16):raise ValueError('Bad hardware ID')
    cross=os.environ.get('CROSS','riscv64-unknown-elf-')
    compiler=subprocess.check_output([cross+'gcc','--version'],text=True).splitlines()[0]
    config=dict(target=target,sources=sources(),compiler=compiler,
        arch=os.environ.get('ASRAM_ARCH',''),flags=os.environ.get('ASRAM_FLAGS',''),
        yolo_flags=os.environ.get('YOLO_FLAGS',''))
    digest=hashlib.sha256(json.dumps(config,sort_keys=True).encode()).hexdigest()
    return config,digest


def prepare():
    config,digest=identity()
    directory=BUILD/'generated';directory.mkdir(parents=True,exist_ok=True)
    text='#ifndef ASRAM_BUILD_CONFIG_H\n#define ASRAM_BUILD_CONFIG_H\n#include <stdint.h>\n'
    text+='#define EXPECTED_HW_ID UINT64_C(0x'+config['target']['hardware_build_id']+')\n'
    text+='#define EXPECTED_HW_ID_TEXT "'+config['target']['hardware_build_id']+'"\n'
    text+='#define PACKAGE_ID "'+digest+'"\n#endif\n'
    header=directory/'build_config.h'
    if not header.exists() or header.read_text()!=text:header.write_text(text)
    write(BUILD/'prepared.json',dict(build_id=digest,config=config))
    print('ASRAM_PREPARE=PASS build_id='+digest)


def audit(config,digest):
    cross=os.environ.get('CROSS','riscv64-unknown-elf-')
    data=ELF.read_bytes()
    if data[:4]!=b'\x7fELF' or digest.encode() not in data:raise ValueError('Wrong ELF identity')
    for marker in (b'ASRAM1,BUILD',b'ASRAM1,DMA',b'ASRAM1,PARALLEL',b'ASRAM1,PASS',b'ASRAM1,HOLE',b'cpu_holes'):
        if marker not in data:raise ValueError('Missing ELF marker')
    if int(config['target']['hardware_build_id'],16).to_bytes(8,'little') not in data:
        raise ValueError('Missing hardware identity check')
    header=subprocess.check_output([cross+'readelf','-hW',str(ELF)],text=True)
    if '0x82000000' not in header:raise ValueError('Wrong entry')
    loads=[]
    for line in subprocess.check_output([cross+'readelf','-lW',str(ELF)],text=True).splitlines():
        if line.strip().startswith('LOAD '):
            f=line.split();address,size=int(f[3],16),int(f[5],16)
            if not 0x82000000<=address<=address+size<=0x82080000:raise ValueError('ELF exceeds private 512 KiB allocation')
            loads.append(dict(address=address,memory_bytes=size,file_bytes=int(f[4],16)))
    dis=subprocess.check_output([cross+'objdump','-d',str(ELF)],text=True)
    (BUILD/'activation_sram_test.dis').write_text(dis)
    words=[int(w,16) for w in re.findall(r'^\s*[0-9a-f]+:\s+([0-9a-f]{8})\s',dis,re.M)]
    for opcode in (0x0b,0x2b,0x5b):
        functions={w>>25 for w in words if w&127==opcode}
        if not {0,2,3}<=functions:raise ValueError('Missing native commands for lane')
    controls={w>>25 for w in words if w&127==0x7b}
    if not {3,9,35,41,67,73}<=controls:raise ValueError('Missing lane identity/mode controls')
    for marker in ('vsetvli','vle8.v','vse8.v','mret','pmpaddr1'):
        if marker not in dis:raise ValueError('Missing RVV/PMP/trap evidence: '+marker)
    if any(w&127==0x73 and 0x7c0<=w>>20<=0x7cf for w in words):raise ValueError('Unexpected legacy scheduler CSR')
    dependencies=0
    for path in (BUILD/'obj').glob('*.d'):
        first=path.read_text().replace('\\\n','').split('\n',1)[0].split(':',1)[1]
        for name in shlex.split(first):
            if not Path(name).resolve().is_relative_to(ROOT):raise ValueError('Build reads another feature directory')
            dependencies+=1
    if not dependencies:raise ValueError('Missing compiler dependency evidence')
    subprocess.run([cross+'objcopy','-O','binary',str(ELF),str(BUILD/'activation_sram_test.bin')],check=True)
    return dict(load_segments=loads,dependency_entries=dependencies,
        elf_bytes=ELF.stat().st_size,payload_bytes=(BUILD/'activation_sram_test.bin').stat().st_size)


def record():
    prepared=json.loads((BUILD/'prepared.json').read_text());config,digest=identity()
    if prepared!=dict(config=config,build_id=digest):raise ValueError('Sources changed during build')
    details=audit(config,digest)
    write(BUILD/'manifest.json',dict(schema=1,build_id=digest,config=config,**details,
        elf_sha256=sha(ELF),generated_sha256=sha(BUILD/'generated/build_config.h'),
        board_accessed=False,board_validation='NOT_RUN'))
    print('ASRAM_ELF_AUDIT=PASS '+json.dumps(details))


def check():
    m=json.loads((BUILD/'manifest.json').read_text())
    if m['config']['sources']!=sources() or m['elf_sha256']!=sha(ELF):
        raise ValueError('Stale ELF or sources; run make all')
    if m['generated_sha256']!=sha(BUILD/'generated/build_config.h'):raise ValueError('Generated configuration changed')
    if os.environ.get('YOLO_FLAGS') is not None and m['config'].get('yolo_flags')!=os.environ['YOLO_FLAGS']:
        raise ValueError('YOLO build options changed; run make all')
    print('ASRAM_AUDIT=PASS board_accessed=0')
    return m


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action',choices=('prepare','record','check'))
    args=parser.parse_args()
    {'prepare':prepare,'record':record,'check':check}[args.action]()
