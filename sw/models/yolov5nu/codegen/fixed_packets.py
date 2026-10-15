"""Bake native ordinary-convolution command operands and byte offsets.

Host C executes the production tile loops, SP helper, command macros and FP16
packer. Runtime replays the same seven-instruction packets; only tensor bases
are relocated. No accelerator command or synchronization boundary is removed.
"""
from pathlib import Path
import json
import hashlib
import re
import shlex
import subprocess
import tempfile
from fixed_plans import function, graph_stages


def macro(header, name):
    lines = header.splitlines(keepends=True)
    for i, line in enumerate(lines):
        if re.match(r'#define\s+' + re.escape(name) + r'\(', line):
            result = line
            while result.rstrip().endswith('\\'):
                i += 1
                result += lines[i]
            return result
    raise ValueError(f'Missing native macro {name}')


def native_program(header, params_path):
    float16 = Path(__file__).resolve().parents[4] / 'sw/third_party/gemmini/include/gemmini_float16.h'
    # All packing macros come from the actual ABI. Do not reimplement them in
    # Python or change scale precision when moving work out of inference.
    constants = '\n'.join(line for line in header.splitlines() if
        re.match(r'#define (k_\w+|CONFIG_\w+|WEIGHT_STATIONARY|SILU_LUT|NO_ACTIVATION) \d+$', line))
    pre = '''#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
'''
    pre += f'#include "{Path(params_path).resolve()}"\n#include "{float16}"\n'
    pre += constants + '\n' + '''
enum tiled_matmul_type_t { OS, WS, CPU };
#define GEMMINI_ASSERTIONS
#define GEMMINI_DISABLE_B_REUSE 0
#define GEMMINI_BATCH_DEBUG 0
#define GEMMINI_CONV_TILE_FENCE 0
#define ceil_divide_int(a,b) (((a)+(b)-1)/(b))
#define conv_cpu(...) abort()
#define gemmini_loopconv_wait_for_credit() ((void)0)
#define ROCC_INSTRUCTION_RS1_RS2(x,a,b,f) record(f,(uint64_t)(a),(uint64_t)(b));
'''
    pre += function(header, 'static acc_scale_t_bits acc_scale_t_to_acc_scale_t_bits(') + '\n'
    for name in ('gemmini_extended3_config_ex', 'gemmini_extended2_config_st',
                 'gemmini_extended_config_st', 'gemmini_loop_conv_ws'):
        # Use the current 3-bit activation ABI, after its explicit #else.
        h = header
        if name == 'gemmini_extended2_config_st':
            h = header[header.index('#else\n#define gemmini_extended2_config_st'):]
        pre += macro(h, name) + '\n'
    pre += 'static void record(unsigned f,uint64_t a,uint64_t b);\n'
    # The SP helper contains an old commented-out implementation with
    # unbalanced braces. Ignore comments before finding its live function end.
    live_header = re.sub(r'/\*.*?\*/|//[^\n]*', '', header, flags=re.S)
    for begin in ('static void sp_tiled_conv(', 'static int tiled_conv_total_spad_rows(', 'static void tiled_conv(\n'):
        pre += function(live_header, begin) + '\n'
    return pre


def bake(out, header, model, params_path, host_cc):
    calls = []
    for stage, body in graph_stages(model).items():
        m = re.search(r'\btiled_conv\(([^;]+)\);', body)
        if m:
            args = [a.strip() for a in m[1].split(',')]
            if len(args) != 37 or args[-1] != 'WS' or any(a == 'NULL' for a in args[27:31]):
                raise ValueError(f'Unsupported fixed packet convolution at stage {stage}')
            calls.append((stage,args,m[0]))
    if len(calls) != 58:
        raise ValueError('Fixed packets require all 58 fixed-plan ordinary convolutions')
    recorder = r'''
static unsigned stage;
static elem_t inputs[8000000],weights[8000000],outputs[8000000];
static acc_t biases[1024];
static uint64_t offset(uint64_t p,const void *base) {
  if(!p)return UINT32_MAX;
  uint64_t delta=p-(uintptr_t)base;
  assert(delta<UINT32_MAX);return delta;
}
static void record(unsigned f,uint64_t a,uint64_t b) {
  if(f==20){a=offset(a,weights);b=offset(b,outputs);}
  if(f==21){a=offset(a,biases);b=offset(b,inputs);}
  printf("%u %u %llu %llu\n",stage,f,(unsigned long long)a,(unsigned long long)b);
}
int main(void) {
'''
    for stage,args,_ in calls:
        a=args.copy();a[27:31]=['inputs','weights','biases','outputs']
        recorder+=f'stage={stage};tiled_conv('+','.join(a)+');\n'
    recorder+='return 0;}\n'
    with tempfile.TemporaryDirectory(prefix='yolo32-packets-') as tmp:
        src,exe=Path(tmp)/'packets.c',Path(tmp)/'packets'
        src.write_text(native_program(header,params_path)+recorder)
        build = subprocess.run(shlex.split(host_cc)+['-std=gnu11','-O2',str(src),'-o',str(exe)],capture_output=True,text=True)
        if build.returncode:
            raise ValueError('Native packet compiler failed:\n'+build.stderr)
        result=subprocess.run([str(exe)],check=True,capture_output=True,text=True)
    streams={stage:[] for stage,_,_ in calls}
    for line in result.stdout.splitlines():
        stage,f,a,b=map(int,line.split())
        streams[stage].append([f,a,b])
    declarations=[]
    manifest=json.loads((out/'fixed_plans.json').read_text())
    packed={}
    for stage,args,original in calls:
        events=streams[stage]
        if [e[0] for e in events[:2]]!=[0,0] or (len(events)-2)%7:
            raise ValueError(f'Unexpected convolution instruction stream at stage {stage}')
        tiles=[];bounds=None
        for begin in range(2,len(events),7):
            packet=events[begin:begin+7]
            if [e[0] for e in packet]!=[16,17,18,19,20,21,15]:
                raise ValueError('Native packet order changed')
            if bounds is None:bounds=packet[0][1:]
            if bounds!=packet[0][1:]:raise ValueError('Layer bounds differ between packets')
            geometry=sum((p[1:] for p in packet[1:4]),[])
            addresses=packet[4][1:]+packet[5][1:]
            launch=packet[6][1:]
            tiles.append(dict(geometry=geometry,offsets=addresses,launch=launch))
        expected=manifest['ordinary'][str(stage)]['packets']
        if len(tiles)!=expected:raise ValueError('Fixed packet count differs from native planner')
        config=events[0][1:]+events[1][1:]+bounds
        def words(values):return '{'+','.join(f'UINT64_C({v})' for v in values)+'}'
        def offsets(values):return '{'+','.join(f'UINT32_C({v})' for v in values)+'}'
        declarations.append(f'static const struct yolo32_conv_packet conv_packets_{stage}[] = {{\n'+
            ',\n'.join('{'+words(t['geometry'])+','+offsets(t['offsets'])+','+words(t['launch'])+'}' for t in tiles)+'\n};')
        declarations.append(f'static const struct yolo32_conv_packet_plan conv_packet_plan_{stage} = {{'+
                            words(config)+f', {len(tiles)}, conv_packets_{stage}'+'};')
        packed[str(stage)]=dict(config=config,tiles=tiles)
        replacement=f'yolo32_fixed_conv(&conv_packet_plan_{stage}, '+', '.join(args[27:31])+');'
        if model.count(original)!=1:raise ValueError('Non-unique fixed convolution call')
        model=model.replace(original,replacement,1)
    structs='''struct yolo32_conv_packet {
  uint64_t geometry[6];
  uint32_t offsets[4]; /* weight, output, bias, input; UINT32_MAX means NULL */
  uint64_t launch[2];
};
struct yolo32_conv_packet_plan {
  uint64_t config[6]; /* store, execution, LoopConv bounds */
  unsigned count;
  const struct yolo32_conv_packet *packets;
};
'''
    runtime=Path(__file__).with_name('fixed_packets_runtime.inc').read_text()
    (out/'fixed_conv_packets.inc').write_text(structs+'\n'.join(declarations)+'\n'+runtime)
    model=model.replace('#include "fixed_plans_guard.inc"',
                        '#include "fixed_plans_guard.inc"\n#include "fixed_conv_packets.inc"',1)
    guard=(out/'fixed_plans_guard.inc').read_text()
    guard+='''_Static_assert(YOLO32_FIXED_PACKETS == 1, "Fixed packet graph requires packet build");
_Static_assert(sizeof(elem_t) == 1 && sizeof(acc_t) == 4 && sizeof(acc_scale_t_bits) == 2,
               "Regenerate fixed convolution packet encoding");
_Static_assert(ADDR_LEN == 32 && ACC_SCALE_EXP_BITS == 5 && ACC_SCALE_SIG_BITS == 11,
               "Regenerate fixed convolution numeric encoding");
_Static_assert(GEMMINI_DISABLE_B_REUSE == 0 && GEMMINI_CONV_TILE_FENCE == 0,
               "Regenerate fixed convolution reuse/fence policy");
#ifndef HAS_FIRST_LAYER_OPTIMIZATIONS
#error "Regenerate fixed convolution first-layer encoding"
#endif
#ifdef GEMMINI_LEGACY_2BIT_ACTIVATION_ABI
#error "Regenerate fixed convolution activation encoding"
#endif
'''
    (out/'fixed_plans_guard.inc').write_text(guard)
    manifest['fixed_packets']=packed
    manifest['packet_table_bytes']=sum(len(p['tiles'])*80 for p in packed.values())
    float16=Path(__file__).resolve().parents[4] / 'sw/third_party/gemmini/include/gemmini_float16.h'
    manifest['packet_fp16_sha256']=hashlib.sha256(float16.read_bytes()).hexdigest()
    (out/'fixed_plans.json').write_text(json.dumps(manifest,indent=2,sort_keys=True)+'\n')
    return model
