#!/usr/bin/env python3
"""Materialize compact RTL fixture inputs from this package's locked model."""
import hashlib
import json
from pathlib import Path
import shutil

ROOT=Path(__file__).resolve().parents[1]
MODEL=ROOT/'model'
OUT=ROOT/'build/sim_inputs'


def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()


def main():
    lock=json.loads((MODEL/'sources.lock.json').read_text())
    for item in lock['sources']:
        if sha(ROOT/item['path'])!=item['sha256']:raise ValueError('Frozen model changed: '+item['path'])
    native=OUT/'native';native.mkdir(parents=True,exist_ok=True)
    files={}
    for source in MODEL.rglob('*'):
        if not source.is_file():continue
        target=native/source.relative_to(MODEL);target.parent.mkdir(parents=True,exist_ok=True)
        if not target.exists() or sha(target)!=sha(source):shutil.copyfile(source,target)
        files[str(source.relative_to(ROOT))]=sha(source)
    generated=OUT/'generated';generated.mkdir(exist_ok=True)
    for name in ('first_layer_s2d.json','first_layer_s2d_data.inc'):
        shutil.copyfile(MODEL/name,generated/name)
    (OUT/'inputs.json').write_text(json.dumps(dict(status='LOCAL_MODEL_FIXTURES_PASS',sources=files),indent=2)+'\n')
    print('LOCAL_MODEL_FIXTURES_PASS path='+str(OUT))


if __name__=='__main__':main()
