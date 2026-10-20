#!/usr/bin/env python3
"""Explicitly lock local build inputs; generated evidence and tool outputs are excluded."""
import hashlib
import json
import os
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def files():
    paths=[]
    # Prune generated workspaces before walking them. Filtering rglob results
    # afterwards still traverses every Vivado/IP cache and private Scala copy.
    for directory, folders, names in os.walk(ROOT):
        parent=Path(directory)
        folders[:]=[name for name in folders if name!='__pycache__' and
                    not (parent==ROOT and name in ('build','validation','bitstream','.Xil'))]
        for name in folders+names:
            p=parent/name
            relative=p.relative_to(ROOT)
            if relative in (Path('vivado.jou'), Path('vivado.log')):continue
            if p.name=='config.local.mk' or relative==Path('manifests/LOCAL_FILES.json'):continue
            paths.append(p)
    def inspect(p):
        relative=p.relative_to(ROOT)
        if p.is_symlink():raise ValueError('Source symlink: '+str(relative))
        if p.is_file():return str(relative),hashlib.sha256(p.read_bytes()).hexdigest()
        return None
    # Read-only checks are independent; bound concurrent reads on slow mounts.
    with ThreadPoolExecutor(max_workers=16) as pool:
        result=dict(item for item in pool.map(inspect,paths) if item is not None)
    return dict(sorted(result.items()))

if __name__=='__main__':
    result=files()
    (ROOT/'manifests/LOCAL_FILES.json').write_text(json.dumps(dict(schema=1,files=result),indent=2)+'\n')
    print('S1_LOCAL_SOURCE_LOCK files='+str(len(result)))
