#!/usr/bin/env python3
"""Explicitly lock local build inputs; generated evidence and tool outputs are excluded."""
import hashlib
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def files():
    result={}
    for p in sorted(ROOT.rglob('*')):
        relative=p.relative_to(ROOT)
        if relative.parts[0] in ('build','validation','bitstream','.Xil') or '__pycache__' in relative.parts:
            continue
        if relative in (Path('vivado.jou'), Path('vivado.log')):continue
        if p.name=='config.local.mk' or relative==Path('manifests/LOCAL_FILES.json'):continue
        if p.is_symlink():raise ValueError('Source symlink: '+str(relative))
        if p.is_file():result[str(relative)]=hashlib.sha256(p.read_bytes()).hexdigest()
    return result

if __name__=='__main__':
    result=files()
    (ROOT/'manifests/LOCAL_FILES.json').write_text(json.dumps(dict(schema=1,files=result),indent=2)+'\n')
    print('S1_LOCAL_SOURCE_LOCK files='+str(len(result)))
