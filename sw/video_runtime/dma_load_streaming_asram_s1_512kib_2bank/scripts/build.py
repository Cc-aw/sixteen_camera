#!/usr/bin/env python3
"""Independent S1 video runtime artifact identity; no board access."""
from pathlib import Path
import hashlib,json,sys
ROOT=Path(__file__).resolve().parents[1]
ELF=ROOT/'build/s1_video_runtime.elf'
BIT=ROOT.parents[2]/'hw/soc/version/dma_load_streaming_asram_s1_512kib_2bank/bitstream/top_wrapper.bit'
BIT_SHA='cb907a77e0c0bf97f5074208956884517d349485003a8d6613ca61b9f7e93a01'
HW_ID='e037701c8d7cfc59'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def sources():
 return {str(p.relative_to(ROOT)):sha(p) for p in sorted(ROOT.rglob('*')) if p.is_file() and p.relative_to(ROOT).parts[0] not in ('build','logs','validation','.git','__pycache__') and p.name!='config.local.mk' and '__pycache__' not in p.parts and p.suffix!='.pyc'}
def identity():
 s=sources();flags=(ROOT/'build/flags').read_text();elf_sha=sha(ELF)
 return dict(schema=1,package='s1_video_runtime',hardware_build_id=HW_ID,bitstream_sha256=BIT_SHA,
  elf='build/s1_video_runtime.elf',elf_sha256=elf_sha,flags=flags,sources=s,
  build_id=hashlib.sha256(json.dumps([s,flags,elf_sha],sort_keys=True).encode()).hexdigest())
def check():
 saved=json.loads((ROOT/'build/manifest.json').read_text());current=identity()
 if saved!=current:raise ValueError('Source/flags/ELF changed; run make all before programming')
 return saved
if __name__=='__main__':
 if sys.argv[1]=='record':(ROOT/'build/manifest.json').write_text(json.dumps(identity(),indent=2)+'\n')
 else:check()
 print('S1RT_BUILD_'+sys.argv[1].upper()+'=PASS board_accessed=0')
