"""Freeze the v26 image/plan identity; no claim about the loaded hardware ID."""
import argparse
import hashlib
import json
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
SOURCE_PATHS = {'Makefile': 'sw/benchmarks/triple_infer/Makefile',
 'README.md': 'sw/models/yolov5nu/src/README.md',
 'analyze_log.py': 'tools/analyze/yolov5nu/analyze_log.py',
 'capacity_log.py': 'tools/analyze/yolov5nu/capacity_log.py',
 'capacity_manifest.py': 'sw/benchmarks/triple_infer/capacity_manifest.py',
 'capacity_observer.c': 'sw/models/yolov5nu/src/capacity_observer.c',
 'capacity_observer.h': 'sw/models/yolov5nu/include/capacity_observer.h',
 'check_log.py': 'tools/analyze/yolov5nu/check_log.py',
 'compare.c': 'sw/benchmarks/triple_infer/compare.c',
 'console.h': 'sw/models/yolov5nu/include/console.h',
 'credit_log.py': 'tools/analyze/yolov5nu/credit_log.py',
 'diagnostic_codegen.py': 'sw/models/yolov5nu/codegen/diagnostic_codegen.py',
 'diagnostic_traffic.py': 'tools/analyze/yolov5nu/diagnostic_traffic.py',
 'diagnostics.c': 'sw/models/yolov5nu/src/diagnostics.c',
 'diagnostics.h': 'sw/models/yolov5nu/include/diagnostics.h',
 'fixed_packets.py': 'sw/models/yolov5nu/codegen/fixed_packets.py',
 'fixed_packets_runtime.inc': 'sw/models/yolov5nu/codegen/fixed_packets_runtime.inc',
 'fixed_plans.py': 'sw/models/yolov5nu/codegen/fixed_plans.py',
 'generate_inputs.py': 'sw/benchmarks/triple_infer/generate_inputs.py',
 'generate_parallel.py': 'sw/models/yolov5nu/codegen/generate_parallel.py',
 'hardware_log.py': 'tools/analyze/yolov5nu/hardware_log.py',
 'import_manifest.json': 'sw/models/yolov5nu/metadata/import_manifest.json',
 'import_v26_manifest.json': 'sw/models/yolov5nu/metadata/import_v26_manifest.json',
 'independent.c': 'sw/models/yolov5nu/src/independent.c',
 'independent.h': 'sw/models/yolov5nu/include/independent.h',
 'linker.ld': 'sw/benchmarks/triple_infer/linker.ld',
 'main.c': 'sw/benchmarks/triple_infer/main.c',
 'memory_kernels.h': 'sw/models/yolov5nu/include/memory_kernels.h',
 'memory_kernels.py': 'sw/models/yolov5nu/codegen/memory_kernels.py',
 'memory_kernels_runtime.inc': 'sw/models/yolov5nu/codegen/memory_kernels_runtime.inc',
 'memory_log.py': 'tools/analyze/yolov5nu/memory_log.py',
 'memory_selftest.inc': 'sw/models/yolov5nu/src/memory_selftest.inc',
 'mmio.h': 'sw/models/yolov5nu/include/mmio.h',
 'model.c': 'sw/models/yolov5nu/src/model.c',
 'packet_dispatch_runtime.inc': 'sw/models/yolov5nu/codegen/packet_dispatch_runtime.inc',
 'platform.h': 'sw/models/yolov5nu/include/platform.h',
 'ppu.c': 'sw/benchmarks/triple_infer/ppu.c',
 'ppu.h': 'sw/models/yolov5nu/include/ppu.h',
 'ppu_early.inc': 'sw/benchmarks/triple_infer/ppu_early.inc',
 'ppu_early_log.py': 'tools/analyze/yolov5nu/ppu_early_log.py',
 'ppu_head_clean.inc': 'sw/benchmarks/triple_infer/ppu_head_clean.inc',
 'ppu_head_log.py': 'tools/analyze/yolov5nu/ppu_head_log.py',
 'prepared_packets.py': 'sw/models/yolov5nu/codegen/prepared_packets.py',
 'prepared_packets_runtime.inc': 'sw/models/yolov5nu/codegen/prepared_packets_runtime.inc',
 'rocc_layers.py': 'tools/analyze/yolov5nu/rocc_layers.py',
 'software_batch.py': 'sw/models/yolov5nu/codegen/software_batch.py',
 'software_batch_log.py': 'tools/analyze/yolov5nu/software_batch_log.py',
 'software_batch_runtime.inc': 'sw/models/yolov5nu/codegen/software_batch_runtime.inc',
 'sources.lock.json': 'sw/models/yolov5nu/sources.lock.json',
 'submit_log.py': 'tools/analyze/yolov5nu/submit_log.py',
 'supply_diag_log.py': 'tools/analyze/yolov5nu/supply_diag_log.py',
 'support.c': 'sw/benchmarks/triple_infer/support.c',
 'task_context_config.h': 'sw/models/yolov5nu/src/task_context_config.h',
 'task_switch.S': 'sw/models/yolov5nu/src/task_switch.S',
 'v26.mk': 'sw/models/yolov5nu/model.mk',
 'wait_reuse.py': 'sw/models/yolov5nu/codegen/wait_reuse.py',
 'wait_reuse_log.py': 'tools/analyze/yolov5nu/wait_reuse_log.py',
 'yolo32.h': 'sw/models/yolov5nu/include/yolo32.h'}

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def generate(build, limit, diagnostic, params, compiler, software_batch=False):
    here=Path(__file__).resolve().parent
    files=['benchmark.elf','fixed_plans.json','memory_kernels.json','inputs_manifest.json']
    result={'schema':1,'firmware':'v28' if software_batch else 'v26','software_batch':int(software_batch),'images':['025','036','142'],
        'executor':'coroutine','credit_cap':4,'credit_limit':limit,'submit_burst':1,
        'quantum_cycles':20000,'capacity_diag':diagnostic,'diagnostic_build':diagnostic,
        'resize_rows':0,'postprocess':'hardware','ppu_strategy':'A','scale':'fp16',
        'hardware_identity':'ABI audited; not a fingerprint of the loaded bitstream',
        'compiler':compiler,'compiler_version':subprocess.check_output([compiler,'--version'],text=True).splitlines()[0],
        'artifacts':{name:digest(build/name) for name in files},'params_sha256':digest(params),
        'sources':{name:digest(ROOT / SOURCE_PATHS[name]) for name in ['main.c','model.c','independent.c','independent.h',
            'capacity_observer.c','capacity_observer.h','fixed_packets_runtime.inc','Makefile']}}
    if software_batch:
        for name in ['software_batch.py','software_batch_runtime.inc','generate_parallel.py','prepared_packets.py','prepared_packets_runtime.inc','yolo32.h','packet_dispatch_runtime.inc','download.sh']:
            result['sources'][name]=digest(ROOT / SOURCE_PATHS[name])
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
