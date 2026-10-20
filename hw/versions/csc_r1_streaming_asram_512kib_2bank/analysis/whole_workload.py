#!/usr/bin/env python3
"""Capture all frozen native Conv/WS packets with explicit address relocation.

This executes the frozen C packet submitters and specialized WS stage code.
HOST stages are boundaries, not fabricated CPU execution or numeric outputs.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shlex
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[4]
MODEL = ROOT / 'sw/board_tests/dma_load_streaming_asram_512kib_2bank/model'
sys.path.insert(0, str(ROOT / 'sw/models/yolov5nu/codegen'))
from fixed_plans import function, graph_stages
from fixed_packets import macro


def capture(model, out):
    out.mkdir(parents=True, exist_ok=False)
    lock = json.loads((model / 'sources.lock.json').read_text())
    for item in lock['sources']:
        if hashlib.sha256((model.parent / item['path']).read_bytes()).hexdigest() != item['sha256']:
            raise ValueError('Frozen model changed: ' + item['path'])
    frozen = json.loads((model / 'fixed_plans.json').read_text())
    text = (model / 'parallel_model.inc').read_text()
    stages = graph_stages(text)
    pre = r'''
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
#include <stdbool.h>
#include <string.h>
typedef int8_t elem_t;
typedef int32_t acc_t;
static unsigned current_lane,current_frame,current_stage,gemmini_pool_active_worker;
static int parallel_collecting=0,yolo32_independent_enabled=0;
static uint64_t read_cycle(void){return 0;}
static void record(unsigned f,uint64_t a,uint64_t b){
 printf("%u %u %u %u %llu %llu\n",current_lane,current_frame,current_stage,f,
        (unsigned long long)a,(unsigned long long)b);
}
#define ROCC_INSTRUCTION_RS1_RS2(op,a,b,f) record(f,(uint64_t)(a),(uint64_t)(b))
#define YOLO32_EMIT_FIXED(op,f,a,b) record(f,(uint64_t)(a),(uint64_t)(b))
#define GEMMINI_POOL_COMMAND_RETURN_HOOK(f) ((void)0)
#define gemmini_fence() record(255,0,0)
static void yolo32_fail(const char *s){fprintf(stderr,"%s\n",s);abort();}
static void yolo32_independent_conv_more(unsigned x){(void)x;}
static void yolo32_independent_arm_tail_wait(unsigned x){(void)x;}
static elem_t *activation_arena,*conv_input_scratch,*conv_output_scratch;
struct yolov5nu_worker_context { const elem_t *input; };
static struct yolov5nu_worker_context worker_contexts[3];
static uint32_t batch_binding_generation[3];
static uint64_t batch_bind_once_cycles,batch_bind_cycles[3];
static void select_worker_memory(unsigned w){
 activation_arena=(elem_t *)(uintptr_t)(0x20000000ULL+w*0x400000ULL);
 conv_input_scratch=(elem_t *)(uintptr_t)(0x98000000ULL+w*0x1000000ULL);
 conv_output_scratch=conv_input_scratch+0x200000;
}
'''
    aliases = re.findall(r'^#define tensor_\d+ \(activation_arena \+ \d+\)', text, re.M)
    pre += '\n'.join(aliases) + '\n'
    h = (model / 'include/gemmini.h').read_text()
    pre += f'#include "{model / "include/gemmini_params.h"}"\n'
    pre += f'#include "{ROOT / "sw/third_party/gemmini/include/gemmini_float16.h"}"\n'
    pre += '\n'.join(line for line in h.splitlines() if re.match(r'#define (k_\w+|CONFIG_\w+|NO_ACTIVATION) \d+$', line)) + '\n'
    for name in ('scale_t_to_scale_t_bits', 'acc_scale_t_to_acc_scale_t_bits'):
        pre += function(h, 'static ' + ('scale_t_bits' if name == 'scale_t_to_scale_t_bits' else 'acc_scale_t_bits') + ' ' + name + '(') + '\n'
    for name in ('gemmini_extended_mvin', 'gemmini_extended_mvout', 'gemmini_extended4_config_ld',
                 'gemmini_extended5_config_ld', 'gemmini_extended_config_st'):
        pre += macro(h, name) + '\n'
    start = h.index('#ifdef GEMMINI_LEGACY_2BIT_ACTIVATION_ABI', h.index('// config'))
    pre += h[start:h.index('\n#endif', start) + len('\n#endif')] + '\n'
    # Per-symbol DDR locations are synthetic relocation, not a firmware linker
    # map. Stable 64-byte alignment preserves per-symbol native offsets and
    # known arena aliases. Values are never dereferenced by the packet recorder.
    params = next(model.glob('*profile_params.h')).read_text()
    addresses, cursor = {}, 0x80000000
    for kind, name, count in re.findall(r'static const (elem_t|acc_t) (yolov5nu_conv\d+_(?:weights|bias))\[(\d+)\]', params):
        cursor = (cursor + 63) & ~63
        addresses[name] = dict(base=cursor, bytes=int(count) * (4 if kind == 'acc_t' else 1), kind=kind)
        pre += f'#define {name} ((const {kind} *)(uintptr_t)UINT64_C({cursor}))\n'
        cursor += addresses[name]['bytes']
    for name, offset in re.findall(r'^#define raw_(class\d|dfl\d).*?tensor_(\d+)\)', text, re.M | re.S):
        pre += f'#define raw_{name} tensor_{offset}\n'
    # Use explicit output-only head relocation; no head output is a later input.
    for name, offset in [('dfl0', 0), ('class0', 0x100000), ('dfl1', 0x200000),
                         ('class1', 0x300000), ('dfl2', 0x400000), ('class2', 0x500000)]:
        pre += f'#undef raw_{name}\n#define raw_{name} ((elem_t *)(uintptr_t)(0xa0000000ULL+worker*0x1000000ULL+{offset}))\n'
    conv = (model / 'fixed_conv_packets.inc').read_text()
    prepared = (model / 'prepared_packets.inc').read_text()
    pre += conv[:conv.index('/* Original ROCC macro')]
    pre += prepared[:prepared.index('_Static_assert')]
    for name, source in [('yolo32_packet_address', conv), ('yolo32_packet_config', conv),
                         ('yolo32_packet_submit', conv), ('yolo32_packed_silu_lut', prepared),
                         ('yolo32_ws_address', prepared), ('yolo32_ws_submit', prepared),
                         ('yolo32_prepared_ws', prepared)]:
        match = re.search(r'^static (?:inline )?[^\n]*\b' + name + r'\(', source, re.M)
        if not match:
            raise ValueError('Missing frozen packet submitter: ' + name)
        pre += function(source, match[0]) + '\n'
    pre += r'''
static void yolo32_fixed_conv(const struct yolo32_conv_packet_plan *p,
 const elem_t *a,const elem_t *b,const acc_t *d,elem_t *c){
 (void)p;(void)a;(void)b;(void)d;(void)c;abort();
}
'''
    pre += (model / 'software_batch_packets.inc').read_text()
    pre += 'static struct yolo32_conv_binding batch_conv_bindings[3][58];\n'
    pre += 'static struct yolo32_ws_binding batch_ws_bindings[3][20];\n'
    pre += function(text, 'static void yolo32_batch_bind_init(void) {') + '\n'
    pre += function(text, 'static void yolo32_batch_bind_start(unsigned worker) {') + '\n'
    memory = (model / 'memory_kernels_runtime.inc').read_text()
    memory = memory.replace('static elem_t memory_pad[3][17*22*128] __attribute__((aligned(64)));', 'static elem_t *memory_pad[3];')
    memory = memory.replace('static elem_t memory_intermediate[3][15*20*128] __attribute__((aligned(64)));', 'static elem_t *memory_intermediate[3];')
    old_pad = function(memory, 'static void memory_pad_input(')
    memory = memory.replace(old_pad, '''static void memory_pad_input(const elem_t *src,elem_t *pad,int h,int w,int c){
 (void)h;(void)w;(void)c;record(254,(uintptr_t)src,(uintptr_t)pad);
}''')
    memory_config = json.loads((model / 'memory_kernels.json').read_text())
    pre += f'#define YOLO32_RESIZE_BATCH {memory_config["resize_batch"]}\n#define YOLO32_RESIZE_ROWS {memory_config["resize_rows"]}\n'
    pre += 'typedef struct {uint64_t pool_calls,resize_calls,mvin,mvout,waits,pad_cycles;} Yolo32MemoryStats;\n'
    pre += 'static int analysis_enabled=0;\nstatic void yolo32_independent_memory_submit(void){}\n'
    pre += memory + '\n'
    code = pre + 'int main(void){\nyolo32_batch_bind_init();\n'
    code += 'for(unsigned i=0;i<3;++i){memory_pad[i]=(elem_t *)(uintptr_t)(0x98400000ULL+i*0x1000000ULL);memory_intermediate[i]=memory_pad[i]+65536;}\n'
    code += 'for(unsigned frame=0;frame<2;++frame)for(unsigned lane=0;lane<3;++lane){\n'
    code += 'current_lane=gemmini_pool_active_worker=lane;current_frame=frame;\n'
    code += 'worker_contexts[lane].input=(elem_t *)(uintptr_t)(0xb0000000ULL+lane*0x1000000ULL);\n'
    code += 'select_worker_memory(lane);yolo32_batch_bind_start(lane);\n'
    inventory = []
    for stage, body in sorted(stages.items()):
        ordinary = re.search(r'yolo32_bound_conv\(&conv_packet_plan_(\d+),&batch_conv_bindings\[worker_id\]\[(\d+)\]\)', body)
        ws = re.search(r'yolo32_batch_ws_(\d+)\(&batch_ws_bindings\[worker_id\]\[(\d+)\]\)', body)
        code += f'current_stage={stage};record(253,0,0);\n'
        if ordinary:
            kind = 'ordinary_conv'
        elif ws:
            kind = 'prepared_ws'
        elif 'yolo32_memory_' in body:
            kind = 'memory_kernel'
        else:
            kind = 'fused_marker' if 'PROFILE_SILU_FUSED_LUT' in body else 'elided_or_head_service'
        # Replay actual call order, including the memory helpers and existing
        # outer fences. No extra fence is inserted after profile-only stages.
        pattern = (r'yolo32_packed_silu_lut\(packed_silu_luts\[\d+\]\);|gemmini_fence\(\);|'
                   r'yolo32_reused_fence\(\d+U\);|yolo32_bound_conv\([^;]+\);|'
                   r'yolo32_batch_ws_\d+\([^;]+\);|yolo32_memory_(?:pool5|resize2)\([^;]+\);')
        for match in re.finditer(pattern, body):
            call = match[0].replace('worker_id', 'lane')
            call = re.sub(r'yolo32_reused_fence\(\d+U\)', 'gemmini_fence()', call)
            code += call + '\n'
        if 'yolo32_publish_head' in body:
            code += 'record(254,0,0);gemmini_fence();\n'
        inventory.append(dict(stage_id=stage, kind=kind))
    code += '}return 0;}\n'
    source = out / 'native_whole_packets.c'
    source.write_text(code)
    executable = out / 'native_whole_packets'
    subprocess.run([*shlex.split(os.environ.get('HOST_CC', 'cc')), '-std=gnu11', '-O2',
                    str(source), '-o', str(executable)], check=True)
    with (out / 'native_commands.txt').open('w') as handle:
        subprocess.run([str(executable)], stdout=handle, check=True)
    counts = {kind: sum(s['kind'] == kind for s in inventory) for kind in {s['kind'] for s in inventory}}
    if counts.get('ordinary_conv') != 58 or counts.get('prepared_ws') != 20:
        raise ValueError('Incomplete native graph command capture: ' + str(counts))
    result = dict(schema=1, status='FROZEN_NATIVE_FULL_PACKET_CAPTURE_PASS', frames=2, lanes=3,
                  stages=inventory, stage_counts=counts, weight_symbols=addresses,
                  relocation='Known native ASRAM arena aliases; synthetic aligned DDR parameter/scratch/head bases',
                  host_numeric_execution=False, full_network_numeric_execution=False,
                  sources_sha256={str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest()
                                  for p in model.rglob('*') if p.is_file()},
                  command_sha256=hashlib.sha256((out / 'native_commands.txt').read_bytes()).hexdigest())
    (out / 'workload.json').write_text(json.dumps(result, indent=2) + '\n')
    print(result['status'], counts)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--model', type=Path, default=MODEL)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    capture(args.model.resolve(), args.output.resolve())
