#!/usr/bin/env python3
"""Local micro-ELF parameters, source identity and artifact audit."""
import argparse
import hashlib
import json
import math
import os
from pathlib import Path
import re
import shlex
import struct
import subprocess

ROOT=Path(__file__).resolve().parents[1]
BUILD=ROOT/'build'
ELF=BUILD/'dma_spad_micro.elf'


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


def parameters():
    result={}
    for key,default in dict(C=12,N=32,P=2,STRIDE=64,OFFSET=0,OPS=32,SAMPLES=12,WARMUPS=3,LANE=0).items():
        result[key.lower()]=int(os.environ.get('MICRO_'+key,default))
    c,n,p,stride=result['c'],result['n'],result['p'],result['stride']
    if not (1<=c<32 and 1<=n<=32 and 1<=p<=32 and c*p<=32):
        raise ValueError('Require 1<=C<32, 1<=N<=32, 1<=P and C*P<=32')
    if not c<stride<=4096:raise ValueError('STRIDE must exceed C for the strided comparison')
    if not 0<=result['offset']<64 or not 0<=result['lane']<3:raise ValueError('OFFSET or LANE out of range')
    if not 1<=result['ops']<=256 or not 1<=result['samples']<=1000 or not 0<=result['warmups']<=16:
        raise ValueError('OPS/SAMPLES/WARMUPS out of range')
    value=float(os.environ.get('MICRO_SCALE','1'))
    if not math.isfinite(value):raise ValueError('SCALE must be finite')
    try:packed=struct.pack('<e',value)
    except (OverflowError,struct.error):raise ValueError('SCALE outside finite FP16 range') from None
    effective=struct.unpack('<e',packed)[0]
    if not math.isfinite(effective):raise ValueError('SCALE rounds to nonfinite FP16')
    result.update(scale_requested=value,scale_effective=effective,scale_bits=int.from_bytes(packed,'little'))
    return result


def identity():
    case=parameters()
    target=json.loads((ROOT/'hardware/target.json').read_text())
    build_id=target['hardware_build_id']
    if not re.fullmatch('[0-9a-f]{16}',build_id) or not int(build_id,16):raise ValueError('Bad hardware ID')
    cross=os.environ.get('CROSS','riscv64-unknown-elf-')
    compiler=subprocess.check_output([cross+'gcc','--version'],text=True).splitlines()[0]
    config=dict(case=case,target=target,sources=sources(),compiler=compiler,
        arch=os.environ.get('MICRO_ARCH',''),flags=os.environ.get('MICRO_FLAGS',''))
    digest=hashlib.sha256(json.dumps(config,sort_keys=True).encode()).hexdigest()
    return config,digest


def prepare():
    config,digest=identity();case=config['case'];target=config['target']
    directory=BUILD/'generated';directory.mkdir(parents=True,exist_ok=True)
    macros={k.upper():v for k,v in case.items() if isinstance(v,int)}
    macros.update(SOURCE_BYTES=case['offset']+(case['n']-1)*case['stride']+case['c'],
        OUTPUT_BYTES=(case['n']+case['p']+1)*32,CLOCK_HZ=target['clock_hz'])
    text='#ifndef MICRO_CASE_CONFIG_H\n#define MICRO_CASE_CONFIG_H\n#include <stdint.h>\n'
    text+=''.join(f'#define MICRO_{k} {v}U\n' for k,v in macros.items())
    text+='#define MICRO_EXPECTED_HW_ID UINT64_C(0x'+target['hardware_build_id']+')\n'
    text+='#define MICRO_BUILD_ID "'+digest+'"\n#endif\n'
    header=directory/'case_config.h'
    if not header.exists() or header.read_text()!=text:header.write_text(text)
    write(BUILD/'prepared.json',dict(build_id=digest,config=config))
    print('MICRO_PREPARE=PASS build_id='+digest)


def audit(config,digest):
    cross=os.environ.get('CROSS','riscv64-unknown-elf-')
    data=ELF.read_bytes()
    if data[:4]!=b'\x7fELF' or digest.encode() not in data:raise ValueError('Wrong ELF identity')
    for marker in (b'SPADM1,BUILD',b'SPADM1,RESULT',b'SPADM1,SUMMARY',b'SPADM1,PASS',b'cpu_issue_to_idle'):
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
    (BUILD/'dma_spad_micro.dis').write_text(dis)
    words=[int(w,16) for w in re.findall(r'^\s*[0-9a-f]+:\s+([0-9a-f]{8})\s',dis,re.M)]
    opcode=(0x0b,0x2b,0x5b)[config['case']['lane']]
    functions={w>>25 for w in words if w&127==opcode}
    controls={w>>25 for w in words if w&127==0x7b}
    if not {0,2,3,126}<=functions or not {config['case']['lane']*32+3,config['case']['lane']*32+9}<=controls:
        raise ValueError('Missing config/mvin/mvout/counters/mode controls')
    if any(w&127==0x73 and 0x7c0<=w>>20<=0x7cf for w in words):raise ValueError('Unexpected legacy scheduler CSR')
    dependencies=0
    for path in (BUILD/'obj').glob('*.d'):
        first=path.read_text().replace('\\\n','').split('\n',1)[0].split(':',1)[1]
        for name in shlex.split(first):
            if not Path(name).resolve().is_relative_to(ROOT):raise ValueError('Build reads another feature directory')
            dependencies+=1
    if not dependencies:raise ValueError('Missing compiler dependency evidence')
    subprocess.run([cross+'objcopy','-O','binary',str(ELF),str(BUILD/'dma_spad_micro.bin')],check=True)
    return dict(load_segments=loads,dependency_entries=dependencies,
        elf_bytes=ELF.stat().st_size,payload_bytes=(BUILD/'dma_spad_micro.bin').stat().st_size)


def record():
    prepared=json.loads((BUILD/'prepared.json').read_text());config,digest=identity()
    if prepared!=dict(config=config,build_id=digest):raise ValueError('Sources changed during build')
    details=audit(config,digest)
    write(BUILD/'manifest.json',dict(schema=1,build_id=digest,config=config,**details,
        elf_sha256=sha(ELF),generated_sha256=sha(BUILD/'generated/case_config.h'),
        board_accessed=False,board_validation='NOT_RUN'))
    print('MICRO_ELF_AUDIT=PASS '+json.dumps(details))


def check(verify_parameters=False):
    m=json.loads((BUILD/'manifest.json').read_text())
    if m['config']['sources']!=sources() or m['elf_sha256']!=sha(ELF):
        raise ValueError('Stale ELF or sources; run make all')
    if m['generated_sha256']!=sha(BUILD/'generated/case_config.h'):raise ValueError('Generated configuration changed')
    if verify_parameters and any(k.startswith('MICRO_') for k in os.environ):
        if parameters()!=m['config']['case']:
            raise ValueError('Requested parameters differ from ELF; rebuild or pass the same parameters')
    print('MICRO_AUDIT=PASS board_accessed=0')
    return m


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action',choices=('prepare','record','check'))
    args=parser.parse_args()
    {'prepare':prepare,'record':record,'check':lambda:check(verify_parameters=True)}[args.action]()
