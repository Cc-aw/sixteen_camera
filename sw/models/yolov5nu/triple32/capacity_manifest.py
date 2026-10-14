"""Freeze the v26 image/plan identity; no claim about the loaded hardware ID."""
import argparse
import hashlib
import json
import subprocess
from pathlib import Path


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def generate(build, limit, diagnostic, params, compiler, software_batch=False):
    here=Path(__file__).resolve().parent
    files=['yolo32.elf','fixed_plans.json','memory_kernels.json','inputs_manifest.json']
    result={'schema':1,'firmware':'v28' if software_batch else 'v26','software_batch':int(software_batch),'images':['025','036','142'],
        'executor':'coroutine','credit_cap':4,'credit_limit':limit,'submit_burst':1,
        'quantum_cycles':20000,'capacity_diag':diagnostic,'diagnostic_build':diagnostic,
        'resize_rows':0,'postprocess':'hardware','ppu_strategy':'A','scale':'fp16',
        'hardware_identity':'ABI audited; not a fingerprint of the loaded bitstream',
        'compiler':compiler,'compiler_version':subprocess.check_output([compiler,'--version'],text=True).splitlines()[0],
        'artifacts':{name:digest(build/name) for name in files},'params_sha256':digest(params),
        'sources':{name:digest(here/name) for name in ['main.c','model.c','independent.c','independent.h',
            'capacity_observer.c','capacity_observer.h','fixed_packets_runtime.inc','Makefile']}}
    if software_batch:
        for name in ['software_batch.py','software_batch_runtime.inc','generate_parallel.py','prepared_packets.py','prepared_packets_runtime.inc','yolo32.h','packet_dispatch_runtime.inc','download.sh']:
            result['sources'][name]=digest(here/name)
        result['scheduling']='supply'
        result['continuation']='dynamic'
        result['supply_policy']={'revision':1,'probe_cycles':4096,'fair_cycles':20000,
            'max_eligible_cycles':80000,'cpu_stage_fallback':False,
            'busy_snapshot':'selection only; never admission/completion'}
    (build/'capacity_manifest.json').write_text(json.dumps(result,indent=2)+'\n')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('build',type=Path)
    p.add_argument('--software-batch',action='store_true')
    p.add_argument('--limit',type=int,choices=(3,4),required=True)
    p.add_argument('--diagnostic',type=int,choices=(0,1),required=True)
    p.add_argument('--params',type=Path,required=True);p.add_argument('--compiler',required=True);a=p.parse_args()
    generate(a.build,a.limit,a.diagnostic,a.params,a.compiler,a.software_batch)
