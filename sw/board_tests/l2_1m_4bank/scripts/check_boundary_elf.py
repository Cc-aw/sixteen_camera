#!/usr/bin/env python3
"""Check the loaded executable's hardware ABI without touching the board."""
from pathlib import Path
import re
import subprocess
import sys
import os
root=Path(__file__).resolve().parents[1]
args=sys.argv[1:]
require_three_way='--three-way' in args
require_diag='--diagnostic' in args
args=[a for a in args if a not in ('--three-way','--diagnostic')]
assert len(args)<=1,'Usage: check_elf.py [ELF] [--three-way] [--diagnostic]'
elf=Path(args[0]) if args else root/'build/yolov5_three_way_12.elf'
cross=os.environ.get('CROSS') or os.environ.get('TOOLCHAIN') or 'riscv64-unknown-elf-'
def run(tool,*args):return subprocess.check_output([cross+tool,*args,str(elf)],text=True)
assert '0x82000000' in run('readelf','-hW')
dis=run('objdump','-d');routes={op:set() for op in (0x0b,0x2b,0x5b,0x7b)}
for word in re.findall(r'^\s*[0-9a-f]+:\s+([0-9a-f]{8})\s',dis,re.M):
    ins=int(word,16);op=ins&127
    if op in routes:routes[op].add(ins>>25)
    if op==0x73:assert not 0x7c0<=ins>>20<=0x7cf,'old Gemmini scheduler CSR remains'
boundary=b'schema=2,version=34,diagnostics=2,' in elf.read_bytes()
expected=set(range(22))|{26}
if boundary:
    for op in (0x0b,0x2b,0x5b):assert routes[op]==expected|{126},routes
else:
    assert routes[0x0b]==expected,routes
    assert not routes[0x2b] and not routes[0x5b],routes
assert routes[0x7b]=={lane*32+op for lane in range(3) for op in (0,1,2,3,4,5)}|{99},routes
symbols=run('nm','-S')
strings=run('strings')
diag=2 if boundary else int('version=33,diagnostics=1,' in strings)
if boundary:
    assert 'YOLO32_FRONTEND,BUILD,schema=2,version=34,diagnostics=2,' in strings
    for marker in ('ATSOFT1,BOUNDARY,executor=','ATSOFT1,MEM_BLOCK,id=','ATSOFT1,GEM_COUNTER,executor=','ALL_DIAGNOSTICS_COMPLETE'):
        assert marker in strings,marker
else:
    assert 'YOLO32_FRONTEND,BUILD,schema=1,version=33,' in strings,'local frontend identity missing'
    assert ('version=33,diagnostics=0,' in strings)!=bool(diag),'ambiguous diagnostic identity'
if require_diag:assert diag,'This is not the diagnostic ELF'
assert not any(s in strings for s in (',ms=',',serial_ms=',',parallel_ms=')),'timing units must be cycles'
modes=3 if 'frontend_scaling_x1000=' in strings else 2
if require_three_way:assert modes==3,'This is not the three-way comparison ELF'
if modes==3:
    for marker in ('frontend_serial','direct_to_single_x1000=','direct_to_parallel_x1000=',
                   'ATSOFT1,PASS,modes=3','ATSOFT1,MODE,executor='):
        assert marker in strings,('missing three-way report',marker)
    size=re.search(r'^\w+\s+(\w+)\s+[bB]\s+output$',symbols,re.M)
    assert size and int(size[1],16)==3*12*164,'Three modes must retain 12 complete PPU results each'
for name in ('yolo32_task_switch','yolo32_independent_step','decode_all_compute','decode_nms_from_candidates','stage4_class_heads_i8','stage4_dfl_heads_i8'):
    assert not re.search(r'\b'+name+r'\b',symbols),name
for name in ('memory_pad_input','ai_ppu_publication_publish','ai_ppu_queue_submit','ai_head_slot_acquire'):
    assert re.search(r'\b'+name+r'(?:\.[\w.]+)?$',symbols,re.M),('missing native work',name)
for name in ('main','text'):
    code='\n'.join(re.findall(r'<'+name+r'(?:\.part\.\d+)?>:\n(.*?)(?=\n\n|\Z)',dis,re.S))
    assert code and re.search(r'\blui\s+\w+,0x10020\b',code),('UART',name)
    assert not re.search(r'\blui\s+\w+,0x64000\b',code),('old UART',name)
trap=dis.split('<trap_entry>:',1)[1].split('\n\n',1)[0]
assert not re.search(r'^\s*[0-9a-f]+:\s+[0-9a-f]+\s+v[a-z0-9]+\b',trap,re.M),'IRQ touches RVV'
for line in run('readelf','-lW').splitlines():
    if line.strip().startswith('LOAD '):
        f=line.split();addr=int(f[3],16);n=int(f[5],16)
        assert 0x82000000<=addr and addr+n<=0xa0000000,(addr,n)
print(f'ATSOFT1,ELF_CHECK_PASS,modes={modes},diagnostics={diag},model=v32,dim=32,scale=fp16,entry=0x82000000,direct=custom0,frontend=custom3,ppu=hardware,old_csrs=0,irq_preserves_rvv=1,hardware_accessed=0')
