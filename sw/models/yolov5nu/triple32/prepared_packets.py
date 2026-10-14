"""Bake LUT uploads and the remaining native WS helpers into relocation tables.

The production C header packs every command, including float-to-half scales.
Python only groups the resulting stream and records relative tensor addresses.
"""
from pathlib import Path
import hashlib
import json
import re
import shlex
import subprocess
import tempfile
from fixed_plans import function, graph_stages

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
PARAM_SOURCE = HERE.parent / 'aot/yolov5nu-stage8f-dual-consumer-spad-reuse-img640x480-image025-profile_params.h'


def stage_calls(model):
    result = {}
    for stage, body in graph_stages(model).items():
        matches = list(re.finditer(r'\b(gemmini_splitk_\w+|add_gemmini_\w+)\(([^;]+)\);', body))
        if not matches:
            continue
        if len(matches) != 1:
            raise ValueError(f'Ambiguous WS stage {stage}')
        m = matches[0]
        args = [x.strip() for x in m[2].split(',')]
        bases = ['NULL'] * 10  # A0..A3, W0/W1, bias0/bias1, output0/output1
        arrays = ''
        if 'two_consumer' in m[1]:
            binding = {0: 0, 1: 1, 2: 4, 3: 6, 4: 8, 8: 5, 9: 7, 10: 9}
        elif 'multi_slice' in m[1]:
            binding = {4: 4, 5: 6, 6: 8}
            for index, kind, var in ((0, r'const elem_t\s*\*', 'sources'),
                                     (1, 'const int', 'channels'),
                                     (2, 'const float', 'scales')):
                match = re.search(kind + r'\s*' + re.escape(args[index]) + r'\[\]\s*=\s*\{([^}]+)\}', body)
                if not match:
                    raise ValueError(f'Missing WS array {args[index]} at stage {stage}')
                values = [x.strip() for x in match[1].split(',')]
                if index == 0:
                    if len(values) != 4:
                        raise ValueError('Expected four fixed input slices')
                    bases[:4] = values
                    arrays += 'const elem_t *sources[]={inputs[0],inputs[1],inputs[2],inputs[3]};\n'
                else:
                    arrays += f'{kind} {var}[]={{' + ','.join(values) + '};\n'
                args[index] = var
        elif m[1].startswith('add_gemmini_'):
            binding = {0: 0, 1: 1, 2: 8}
        else:
            binding = {0: 0, 1: 1, 2: 4, 3: 6, 4: 8}
        synthetic = ['inputs[0]', 'inputs[1]', 'inputs[2]', 'inputs[3]',
                     'weights[0]', 'weights[1]', 'biases[0]', 'biases[1]', 'outputs[0]', 'outputs[1]']
        for index, role in binding.items():
            bases[role] = args[index]
            args[index] = synthetic[role]
        result[stage] = dict(helper=m[1], args=args, arrays=arrays, bases=bases)
    if len(result) != 20 or sum(p['helper'].startswith('gemmini_splitk_') for p in result.values()) != 13:
        raise ValueError('Prepared packets require all 13 Split-K and seven residual stages')
    return result


def lut_declarations(source):
    declarations = re.findall(r'static const elem_t (yolov5nu_silu_lut\d+)\[256\]\s*=\s*\{([^}]+)\};', source)
    result = {}
    for name, body in declarations:
        if re.sub(r'-?\d+|[\s,]', '', body):
            raise ValueError(f'Nonliteral SiLU table {name}')
        values = [int(v) for v in re.findall(r'-?\d+', body)]
        if len(values) != 256 or any(v < -128 or v > 127 for v in values):
            raise ValueError(f'Invalid SiLU table {name}')
        result[name] = 'static const elem_t ' + name + '[256]={' + body + '};\n'
    if len(result) != 69:
        raise ValueError('Expected all 69 model SiLU tables')
    return result


def native_streams(header, native_model, params_path, host_cc):
    calls = stage_calls(native_model)
    luts = lut_declarations(PARAM_SOURCE.read_text())
    names = sorted(luts, key=lambda n: int(n.removeprefix('yolov5nu_silu_lut')))
    pre = r'''
#include <assert.h>
#include <stdint.h>
#include <stddef.h>
#include <stdio.h>
static void record(unsigned f,uint64_t a,uint64_t b);
static void wait_record(void);
#define gemmini_fence() wait_record()
#define GEMMINI_LOOPCONV_CREDIT_ADMISSION 0
#include "include/gemmini.h"
static unsigned stage;
static elem_t inputs[4][8000000], weights[2][8000000], outputs[2][8000000];
static acc_t biases[2][1024];
static const void *const bases[]={inputs[0],inputs[1],inputs[2],inputs[3],weights[0],weights[1],biases[0],biases[1],outputs[0],outputs[1]};
static uint64_t relative(uint64_t p) {
  if(!p)return UINT64_C(255)<<32;
  for(unsigned i=0;i<10;++i){
    uintptr_t base=(uintptr_t)bases[i];
    size_t size=(i==6||i==7)?sizeof(biases[0]):sizeof(inputs[0]);
    if(p>=base && p-base<size)return ((uint64_t)i<<32)|(p-base);
  }
  assert(!"unbound command address");return 0;
}
static void record(unsigned f,uint64_t a,uint64_t b) {
  if(f==10 || f==11){a=relative(a);b=relative(b);}
  printf("%u %u %llu %llu\n",stage,f,(unsigned long long)a,(unsigned long long)b);
}
static void wait_record(void){record(255,0,0);}
'''
    pre += ''.join(luts[n] for n in names)
    for name in sorted({p['helper'] for p in calls.values()}):
        pre += function(native_model, 'static void ' + name + '(') + '\n'
    main = 'int main(void){\n'
    for index, name in enumerate(names):
        main += f'stage={1000+index};gemmini_config_silu_lut({name});\n'
    for stage, p in calls.items():
        main += '{\n' + p['arrays'] + f'stage={stage};' + p['helper'] + '(' + ','.join(p['args']) + ');\n}\n'
    main += 'return 0;}\n'
    with tempfile.TemporaryDirectory(prefix='yolo32-prepared-') as tmp:
        tmp = Path(tmp)
        (tmp/'include').mkdir()
        # Record at the final native RoCC assembly boundary. All production
        # packing macros and SP helpers remain the oracle.
        h = header.replace('#include "rocc-software/src/xcustom.h"',
            '#include "rocc-software/src/xcustom.h"\n#undef ROCC_INSTRUCTION_0_R_R\n'
            '#define ROCC_INSTRUCTION_0_R_R(op,a,b,f) record(f,(uint64_t)(a),(uint64_t)(b));')
        (tmp/'include/gemmini.h').write_text(h)
        (tmp/'native.c').write_text(pre+main)
        includes = [tmp, ROOT/'sw/third_party/gemmini_v3',
                    ROOT/'sw/third_party/gemmini_v3/include',
                    ROOT/'sw/third_party/gemmini_v3']
        command = shlex.split(host_cc)+['-std=gnu11','-O2','-include',str(Path(params_path).resolve())]
        command += ['-I'+str(p) for p in includes]+[str(tmp/'native.c'),'-lm','-o',str(tmp/'native')]
        build = subprocess.run(command, capture_output=True, text=True)
        if build.returncode:
            raise ValueError('Native WS packet compiler failed:\n'+build.stderr)
        result = subprocess.run([str(tmp/'native')],check=True,capture_output=True,text=True)
    streams = {}
    for line in result.stdout.splitlines():
        stage, f, a, b = map(int, line.split())
        streams.setdefault(stage, []).append([f, a, b])
    packed = []
    for index in range(len(names)):
        stream = streams.pop(1000+index)
        if len(stream) != 32 or any(f != 26 or a != i*8 for i,(f,a,b) in enumerate(stream)):
            raise ValueError('SiLU upload ABI changed')
        packed.append([b for f,a,b in stream])
    if set(streams) != set(calls):
        raise ValueError('Incomplete native WS streams')
    return calls, names, packed, streams


def bake(out, header, native_model, model, params_path, host_cc):
    calls, names, luts, streams = native_streams(header, native_model, params_path, host_cc)
    packets, configs, plans = [], [], {}
    for stage, events in streams.items():
        steps, i = [], 0
        while i < len(events):
            f,a,b = events[i]
            if f == 0:
                value = [a,b]
                if value not in configs:
                    configs.append(value)
                steps.append([0,configs.index(value)])
                i += 1
            elif f == 9:
                packet = events[i:i+6]
                if [e[0] for e in packet] != [9,10,11,12,13,8]:
                    raise ValueError(f'Incomplete native WS packet at stage {stage}')
                addresses = packet[1][1:] + packet[2][1:]
                data = dict(bounds=packet[0][1:], offsets=[v&0xffffffff for v in addresses],
                            roles=[v>>32 for v in addresses], strides=packet[3][1:]+packet[4][1:],
                            launch=packet[5][1:])
                if any(r not in range(10) and r != 255 for r in data['roles']):
                    raise ValueError('Invalid WS relocation')
                steps.append([1,len(packets)])
                packets.append(data)
                i += 6
            elif f == 26:
                upload = events[i:i+32]
                words = [e[2] for e in upload]
                if len(upload) != 32 or any(e[:2] != [26,j*8] for j,e in enumerate(upload)) or words not in luts:
                    raise ValueError('Unexpected WS SiLU upload')
                steps.append([2,luts.index(words)])
                i += 32
            elif f == 255 and a == b == 0:
                steps.append([3,0])
                i += 1
            else:
                raise ValueError(f'Unsupported WS command {f} at stage {stage}')
        p = calls[stage]
        count = sum(kind == 1 for kind,index in steps)
        plans[str(stage)] = dict(helper=p['helper'],bases=p['bases'],steps=steps,packets=count)
        body = graph_stages(model)[stage]
        match = re.search(r'\b'+re.escape(p['helper'])+r'\(([^;]+)\);',body)
        if not match or model.count(match[0]) != 1:
            raise ValueError('Prepared WS call is not unique')
        replacement = f'yolo32_prepared_ws(&prepared_ws_plan_{stage}, (const void *const[10]){{' + ','.join(p['bases']) + '});'
        model = model.replace(match[0],replacement,1)
    splitk = sum(p['packets'] for p in plans.values() if p['helper'].startswith('gemmini_splitk_'))
    residual = sum(p['packets'] for p in plans.values() if p['helper'].startswith('add_gemmini_'))
    if (splitk,residual) != (184,40):
        raise ValueError('Native WS request counts changed')
    words = lambda values: '{'+','.join(f'UINT64_C({v})' for v in values)+'}'
    ints = lambda values: '{'+','.join(map(str,values))+'}'
    code = '''/* Generated by the native C command packers. Shared by all workers. */
struct yolo32_prepared_ws_packet {
  uint64_t bounds[2], strides[4], launch[2];
  uint32_t offsets[4];
  uint8_t roles[4];
};
struct yolo32_prepared_ws_step { uint16_t kind, index; };
struct yolo32_prepared_ws_plan {
  unsigned count;
  const struct yolo32_prepared_ws_step *steps;
};
'''
    code += 'static const uint64_t packed_silu_luts[69][32] = {\n'+',\n'.join(words(v) for v in luts)+'\n};\n'
    code += 'static const uint64_t prepared_ws_configs[][2] = {\n'+',\n'.join(words(v) for v in configs)+'\n};\n'
    code += 'static const struct yolo32_prepared_ws_packet prepared_ws_packets[] = {\n'
    code += ',\n'.join('{'+','.join([words(p['bounds']),words(p['strides']),words(p['launch']),ints(p['offsets']),ints(p['roles'])])+'}' for p in packets)+'\n};\n'
    for stage,p in plans.items():
        code += f'static const struct yolo32_prepared_ws_step prepared_ws_steps_{stage}[] = {{'+','.join(ints(v) for v in p['steps'])+'};\n'
        code += f'static const struct yolo32_prepared_ws_plan prepared_ws_plan_{stage} = {{'+f'{len(p["steps"])}, prepared_ws_steps_{stage}'+'};\n'
    code += (HERE/'prepared_packets_runtime.inc').read_text()
    (out/'prepared_packets.inc').write_text(code)
    for index,name in enumerate(names):
        model = model.replace(f'gemmini_config_silu_lut({name})',f'yolo32_packed_silu_lut(packed_silu_luts[{index}])')
    model = model.replace('#include "fixed_conv_packets.inc"',
                          '#include "fixed_conv_packets.inc"\n#include "prepared_packets.inc"',1)
    manifest = json.loads((out/'fixed_plans.json').read_text())
    manifest.update(prepared_ws=plans,prepared_ws_packets=packets,prepared_ws_configs=configs,
                    packed_silu_luts=dict(zip(names,luts)),
                    prepared_params_sha256=hashlib.sha256(PARAM_SOURCE.read_bytes()).hexdigest(),
                    prepared_ws_packets_per_worker=224,
                    prepared_table_bytes=69*256+len(configs)*16+len(packets)*88+sum(len(p['steps'])*4+16 for p in plans.values()))
    (out/'fixed_plans.json').write_text(json.dumps(manifest,indent=2,sort_keys=True)+'\n')
    with (out/'fixed_plans_guard.inc').open('a') as guard:
        guard.write('_Static_assert(YOLO32_PREPARED_PACKETS == 1, "Prepared graph requires prepared packet build");\n')
        guard.write('#ifdef YOLOV5NU_STAGE8_MODE_8H_SPLITK_CONFIG_FENCE_MERGE\n#error "Regenerate prepared WS packets for the changed fence policy"\n#endif\n')
    return model
