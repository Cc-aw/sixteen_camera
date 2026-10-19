#!/usr/bin/env python3
"""Derive the V33 frontend adapter from locked local v32 inputs.

Only the configured ignored build output is written; the donor is never read.
The native packet geometry, reuse, FP16 operands and memory kernels are retained.
"""
from pathlib import Path
import hashlib
import json
import re
import shutil

import os
ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT
OUT = ROOT / 'build'
SNAP = ROOT / 'model'
GEN = OUT / 'yolo_generated'
LOCK = ROOT / 'model/sources.lock.json'
PARAMS = 'yolov5nu-stage8f-dual-consumer-spad-reuse-img640x480-image025-profile_params.h'
EXPECTED_ELF = '7aa5962cb3c00badf2afde3ef31935e21d2a938635d9a9dd8c80ac737692dd7e'

def digest(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()

def once(s, old, new):
    if s.count(old) != 1:
        raise ValueError('Unreviewed source anchor: ' + old[:100])
    return s.replace(old, new, 1)

def function(s, start):
    a = s.index(start); b = s.index('{', a); i = b + 1; depth = 1
    while depth:
        depth += (s[i] == '{') - (s[i] == '}'); i += 1
    return s[a:i]

def freeze():
    """Materialize only locked repository inputs; never access the donor."""
    manifest = json.loads(LOCK.read_text())
    for item in manifest['sources']:
        source = PROJECT / item['path']
        if digest(source) != item['sha256']:
            raise ValueError('Frozen V33 input changed: ' + item['path'])
        target = SNAP / item['snapshot']
        target.parent.mkdir(parents=True, exist_ok=True)
        if not target.exists() or digest(target) != item['sha256']:
            shutil.copyfile(source, target)


def generate():
    freeze(); GEN.mkdir(parents=True, exist_ok=True)
    original_manifest = json.loads((SNAP / 'capacity_manifest.json').read_text())
    for name, sha in original_manifest['artifacts'].items():
        if name != 'yolo32.elf' and digest(SNAP / name) != sha:
            raise ValueError('Baseline artifact mismatch: ' + name)
    if digest(SNAP / 'include/gemmini_params.h') != original_manifest['params_sha256']:
        raise ValueError('Baseline hardware parameter mismatch')
    h = (SNAP / 'include/gemmini.h').read_text()
    a = h.index('#ifdef GEMMINI_POOL_RUNTIME_DISPATCH\nextern unsigned')
    b = h.index('// mvin and mvout', a)
    h = h[:a] + '''#define ROCC_INSTRUCTION_RS1_RS2(op,a,b,f) { at_raw(f,(uintptr_t)(a),(uintptr_t)(b)); }
#define GEMMINI_POOL_RECORD_COMMAND(f) ((void)0)
#define gemmini_fence() at_drain()
''' + h[b:]
    (GEN / 'include').mkdir(exist_ok=True)
    (GEN / 'include/gemmini.h').write_text(h)
    hardware = ROOT / 'hardware/gemmini_params_custom0.h'
    params = hardware.read_text()
    baseline_params = (SNAP / 'include/gemmini_params.h').read_text()
    def math_abi(text):
        text = re.sub(r'^#define GEMMINI_(?:BUSY|LOOPCONV)\w*[^\n]*\n', '', text, flags=re.M)
        return re.sub(r'^#define XCUSTOM_ACC \d+', '#define XCUSTOM_ACC 0', text, flags=re.M)
    if math_abi(params) != math_abi(baseline_params):
        raise ValueError('Current DIM32/FP16 command ABI differs from frozen V33')
    params = re.sub(r'^#define GEMMINI_(?:BUSY|LOOPCONV)\w*[^\n]*\n', '', params, flags=re.M)
    if '#define XCUSTOM_ACC 0' not in params:
        raise ValueError('V33 direct lane0 requires custom0')
    (GEN / 'include/gemmini_params.h').write_text(params)
    # Fixed worker dispatch macros now record identical funct/operands into a
    # table. Original custom3/custom2/custom1 selectors never reach hardware.
    (GEN / 'packet_dispatch_runtime.inc').write_text('''
#define YOLO32_EMIT_FIXED(op,f,a,b) at_raw(f,(uintptr_t)(a),(uintptr_t)(b))
#define YOLO32_RECORD_FIXED_RUN(w,f) ((void)0)
''')
    # These generated tables include the dispatch file relative to themselves.
    for name in ('fixed_conv_packets.inc', 'prepared_packets.inc', 'software_batch_packets.inc', 'fixed_plans_guard.inc'):
        shutil.copyfile(SNAP / name, GEN / name)
    fixed = (GEN / 'fixed_conv_packets.inc').read_text()
    fixed = once(fixed, function(fixed, 'static void parallel_execute('), '')
    (GEN / 'fixed_conv_packets.inc').write_text(fixed)
    memory = (SNAP / 'memory_kernels_runtime.inc').read_text()
    sig = 'static void memory_pad_input(const elem_t *src,elem_t *pad,int h,int w,int c) {'
    memory = once(memory, sig, sig + '\n    if (planning) { at_pad(src,pad,h,w,c); return; }')
    (GEN / 'memory_kernels_runtime.inc').write_text(memory)

    model = (SNAP / 'parallel_model.inc').read_text()
    prefix = model[:model.index('\nunsigned gemmini_pool_active_worker;')]
    for name, signature, body in (
        ('yolo_frame_profile_clock', 'static inline uint64_t yolo_frame_profile_clock(', 'static inline uint64_t yolo_frame_profile_clock(void) { return 0; }'),
        ('yolo_profile_fence', 'static inline void yolo_profile_fence(', 'static inline void yolo_profile_fence(void) { at_drain(); }'),
        ('frame_counter_access', 'static uint32_t frame_counter_access(', 'static uint32_t frame_counter_access(uint32_t w,uint32_t c) { (void)w;(void)c;return 0; }')):
        prefix = once(prefix, function(prefix, signature), body)
    prefix = once(prefix,
        'static elem_t activation_arenas[YOLOV5NU_DIM16_WORKER_COUNT][2217600] __attribute__((aligned(64)));',
        'static elem_t ddr_activation_backing[YOLOV5NU_DIM16_WORKER_COUNT][ASRAM_ARENA_BYTES+128] __attribute__((aligned(64)));\n'
        'static elem_t *activation_arenas[YOLOV5NU_DIM16_WORKER_COUNT];')
    native = prefix + model[model.index('\nunsigned gemmini_pool_active_worker;'):]
    native = once(native, function(native, 'static inline uint64_t read_worker_busy('),
        'static inline uint64_t read_worker_busy(uint32_t w) { (void)w;return 0; }')
    native = once(native, '    switch (context->stage) {', '    current_phase=context->stage;\n    switch (context->stage) {')
    (GEN / 'native_graph.inc').write_text(native)
    context = model[model.index('struct yolov5nu_worker_context {'):model.index('static inline uint64_t read_worker_busy(')]
    select = function(model, 'static void select_worker_memory(')
    binding = model[model.index('static struct yolo32_conv_binding batch_conv_bindings'):model.index('int yolov5nu_dim16_worker_poll(uint32_t worker_id,')]
    stages = {}
    for m in re.finditer(r'    case (\d+)U:', model):
        n = int(m[1])
        if n < 165: stages[n] = function(model[m.end():], '{')
    if set(stages) != set(range(165)):
        raise ValueError('Graph stage set changed')
    code = prefix + context + select + binding + '''
static void at_phase(unsigned worker_id,unsigned phase) {
    struct yolov5nu_worker_context *context=&worker_contexts[worker_id];
    const elem_t *model_input=context->input;
    uint64_t *silu_config_cycles=context->silu_config_cycles;
    select_worker_memory(worker_id);
    switch(phase) {
'''
    for n, body in stages.items():
        body = re.sub(r'if \(context->hardware_head && head_callback\) yolo32_publish_head\(worker_id, (\d)\);', r'at_head(\1);', body)
        # No mathematical CPU op is omitted. All nonaccelerator graph stages
        # below 165 are profile-only/compile-time eliminated in this build.
        clean = re.sub(r'/\*.*?\*/', '', body, flags=re.S)
        calls = set(re.findall(r'\b(\w+)\s*\(', clean)) - {'if','for','sizeof','yolo_profile_add','yolo_profile_begin','yolo_profile_clock'}
        allowed = {'yolo32_bound_conv','yolo32_packed_silu_lut','gemmini_fence',
                   'yolo32_reused_fence','yolo32_memory_pool5','yolo32_memory_resize2','at_head'}
        if any(c not in allowed and not re.fullmatch(r'yolo32_batch_ws_\d+', c) for c in calls):
            raise ValueError(f'Unreviewed graph call at {n}: {calls}')
        code += f'case {n}:\n{body}\nbreak;\n'
    code += 'default: at_fail("phase_range",phase);\n}\n}\n'
    names = re.findall(r'^static const (?:elem_t|acc_t|float) (\w+)\[', (SNAP / PARAMS).read_text(), re.M)
    (GEN / 'constants.inc').write_text(''.join(f'{{{n},sizeof({n})}},\n' for n in names))
    code += 'static const struct Range constants[] = {\n' + ''.join(f'{{{n},sizeof({n})}},\n' for n in names) + '};\n'
    (GEN / 'graph.inc').write_text(code)
    manifest = dict(firmware='YOLO32_FRONTEND/v33', baseline='memory_schedule/v32',
        implementation_reference='Atestsoftv1',
        baseline_elf_sha256=EXPECTED_ELF, frames=12, modes=3, images=['025','036','142'],
        dim=32, scale='fp16', postprocess='hardware PPU A', ordinary_conv_packets=462,
        ws_packets=224, frontend='custom3 IRQ13', direct='custom0/custom1/custom2',
        removed='old coroutine/credit polling/Head admission-window scheduling',
        retained='native model, concurrent tile geometry, B reuse, LUT, MaxPool/Resize, local waits, Head clean/PPU',
        cpu_model_work='six native MaxPool padding/copy boundaries per frame',
        graph_sha256=digest(GEN / 'graph.inc'))
    (GEN / 'manifest.json').write_text(json.dumps(manifest, indent=2)+'\n')
    print('ATSOFT1,GENERATED,baseline=v32,phases=165,conv=462,ws=224,model_ops_removed=0')

if __name__ == '__main__':
    generate()
