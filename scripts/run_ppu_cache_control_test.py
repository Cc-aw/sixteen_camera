#!/usr/bin/env python3
from pathlib import Path
import os,re,subprocess
root=Path(__file__).resolve().parents[1]
config=re.search(r'^\s*(tsmc\S+Config)\s*$',(root/'build/soc_manifest.tcl').read_text(),re.M)[1]
src=root/'generated/soc'/config/'gen-collateral'
out=Path(os.environ.get('PPU_TEST_CACHE',str(root/'build/ppu_phase2/cache')))/'publication/cache_control'
out.mkdir(parents=True,exist_ok=True)
files=[]
def dependencies(name):
    path=src/(name+'.sv')
    if path in files:return
    files.append(path)
    for child in re.findall(r'^  (\w+) \w+ \(',path.read_text(),re.M):dependencies(child)
dependencies('InclusiveCacheControl')
subprocess.run(['verilator','--binary','--build-jobs','8','--timing','-Wno-fatal','--top-module','tb_ppu_cache_control_completion','--Mdir',str(out),
    str(root/'rtl/interfaces/axi4_if.sv'),str(root/'rtl/ai/postprocess/ppu_cache_publish_engine.sv'),
    *map(str,files),str(root/'sim/tb_ppu_cache_control_completion.sv')],check=True)
subprocess.run([str(out/'Vtb_ppu_cache_control_completion')],check=True)
