"""Run the native convolution planner at build time, then emit fixed geometry.

The host program uses the production C planner, including its reduce/grow
heuristics. No duplicate Python implementation of that algorithm is used.
"""
from pathlib import Path
import hashlib
import json
import re
import shlex
import subprocess
import tempfile


def function(text, begin):
    start = text.index(begin)
    brace = text.index('{', start)
    depth, end = 1, brace + 1
    while depth:
        depth += (text[end] == '{') - (text[end] == '}')
        end += 1
    return text[start:end]


def graph_stages(model):
    poll = function(model, 'int yolov5nu_dim16_worker_poll(')
    parts = re.split(r'    case (\d+)U:', poll)[1:]
    return {int(parts[i]): parts[i + 1] for i in range(0, len(parts), 2)}


def hardware_parameters(path):
    text = Path(path).read_text()
    values = {}
    for name in ('DIM', 'BANK_NUM', 'BANK_ROWS', 'ACC_ROWS'):
        match = re.search(r'^#define\s+' + name + r'\s+(\d+)\s*$', text, re.M)
        if not match:
            raise ValueError(f'Cannot read hardware parameter {name} from {path}')
        values[name] = int(match[1])
    if values['DIM'] != 32:
        raise ValueError('Fixed YOLO32 plans require DIM=32')
    return values


def native_plans(header, model, params, host_cc):
    calls = []
    for stage, body in graph_stages(model).items():
        match = re.search(r'\btiled_conv_auto\(([^;]+)\);', body)
        if match:
            args = [x.strip() for x in match[1].split(',')]
            if len(args) != 27 or args[-1] != 'WS':
                raise ValueError(f'Unexpected convolution ABI at stage {stage}')
            calls.append((stage, args))
    if len(calls) != 58:
        raise ValueError(f'Expected 58 ordinary convolutions, found {len(calls)}')
    native = function(header, 'static void tiled_conv(\n')
    signature = native.split(') {', 1)[0]
    stub = signature + ''') {
    int ps = pool_stride ? pool_stride : 1;
    int psize = pool_stride ? pool_size : 1;
    bool downsample = stride == 2 && kernel_dim == 1 && padding == 0 &&
      pool_stride == 0 && in_row_dim % 2 == 0 && in_col_dim % 2 == 0;
    int spad = tiled_conv_total_spad_rows(false, stride, input_dilation,
      kernel_dilation, downsample, trans_weight_0132, trans_input_3120,
      batches, porows, pocols, pochs, krows, kcols, kchs, psize, ps);
    int acc = tiled_conv_total_spad_rows(true, stride, input_dilation,
      kernel_dilation, downsample, trans_weight_0132, trans_input_3120,
      batches, porows, pocols, pochs, krows, kcols, kchs, psize, ps);
    if (spad > BANK_NUM * BANK_ROWS / 2 || acc > ACC_ROWS / 2 ||
        batches <= 0 || porows <= 0 || pocols <= 0 || pochs <= 0 ||
        krows <= 0 || kcols <= 0 || kchs <= 0) exit(1);
    int oh = (out_row_dim + 2 * pool_padding - psize) / ps + 1;
    int ow = (out_col_dim + 2 * pool_padding - psize) / ps + 1;
    long packets = ((batch_size+batches-1)/batches) * ((oh+porows-1)/porows) *
      ((ow+pocols-1)/pocols) * ((out_channels+pochs-1)/pochs) *
      ((kernel_dim+krows-1)/krows) * ((kernel_dim+kcols-1)/kcols) *
      ((in_channels+kchs-1)/kchs);
    printf("%d %d %d %d %d %d %d %d %d %d %ld\\n", current_stage,
      batches, porows, pocols, pochs, krows, kcols, kchs, spad, acc, packets);
}'''
    pre = '''#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
typedef int8_t elem_t; typedef int32_t acc_t; typedef float acc_scale_t;
enum tiled_matmul_type_t {OS, WS, CPU};
#define _STATIC static
static int current_stage;
'''
    pre += ''.join(f'#define {key} {value}\n' for key, value in params.items())
    pre += function(header, 'static int tiled_conv_total_spad_rows(') + '\n'
    pre += stub + '\n' + function(header, 'static void tiled_conv_stride_auto(')
    pre += '\n' + function(header, '_STATIC void tiled_conv_auto(')
    main = 'int main(void) {\n'
    for stage, args in calls:
        a = args.copy()
        a[17:21] = ['NULL'] * 4
        a[21:23] = ['0', '1.0f']
        main += f'current_stage={stage}; tiled_conv_auto({",".join(a)});\n'
    main += 'return 0; }\n'
    with tempfile.TemporaryDirectory(prefix='yolo32-plan-') as tmp:
        src, exe = Path(tmp) / 'planner.c', Path(tmp) / 'planner'
        src.write_text(pre + main)
        subprocess.run(shlex.split(host_cc) + ['-std=c11', '-O2', str(src), '-o', str(exe)],
                       check=True, capture_output=True)
        result = subprocess.run([str(exe)], check=True, capture_output=True, text=True)
    plans = {}
    for line in result.stdout.splitlines():
        stage, *values = map(int, line.split())
        if len(values) != 10 or stage in plans:
            raise ValueError('Unexpected native planner output')
        plans[stage] = dict(tile=values[:7], spad_rows=values[7],
                            acc_rows=values[8], packets=values[9])
    if set(plans) != {s for s, _ in calls}:
        raise ValueError('Incomplete native convolution plans')
    return calls, plans


def remove_capacity_checks(body):
    """Capacity is verified by the native host planner, not on every inference."""
    start = body.index('        const int spad_rows = tiled_conv_total_spad_rows(false,')
    end = body.index('        if (kernel_dim <= padding)', start)
    return body[:start] + '        /* Capacity checked by fixed_plans.py at build time. */\n' + body[end:]


def bake_splitk(model, params):
    dim, acc = params['DIM'], params['ACC_ROWS']
    plans, declarations = {}, []
    helpers = set()
    for stage, body in graph_stages(model).items():
        match = re.search(r'\b(gemmini_splitk_\w+)\(([^;]+)\);', body)
        if not match:
            continue
        name, args = match[1], [x.strip() for x in match[2].split(',')]
        helpers.add(name)
        if 'two_consumer' in name:
            positions, channels = int(args[14]), [int(args[15])] * 2
            outs = [int(args[6]), int(args[12])]
        elif 'multi_slice' in name:
            positions, outs = int(args[7]), [int(args[8])]
            array = re.search(r'const int ' + re.escape(args[1]) + r'\[\] = \{([^}]+)\}', body)
            if not array:
                raise ValueError(f'Missing Split-K channels at stage {stage}')
            channels = [int(x.strip()) for x in array[1].split(',')]
            if len(channels) != int(args[3]):
                raise ValueError('Split-K slice count mismatch')
        else:
            positions, channels, outs = int(args[5]), [int(args[6])] * 2, [int(args[7])]
        j = [(out + dim - 1) // dim for out in outs]
        blocks = min((acc // 2) // (x * dim) for x in j)
        if blocks <= 0 or positions <= 0 or min(channels) <= 0:
            raise ValueError(f'Invalid Split-K geometry at stage {stage}')
        tile_rows = blocks * dim
        rows = []
        for row in range(0, positions, tile_rows):
            count = min(tile_rows, positions - row)
            iblocks = (count + dim - 1) // dim
            rows.append([row, count, iblocks, iblocks * dim - count])
        k = [(c + dim - 1) // dim for c in channels]
        padk = [b * dim - c for b, c in zip(k, channels)]
        plans[stage] = dict(helper=name, tile_rows=tile_rows, rows=rows,
                            j_blocks=j, channels=channels, k_blocks=k, pad_k=padk,
                            packets=len(rows) * (4 if len(outs) == 2 else len(channels)))
        declarations.append(f'static const struct yolo32_splitk_tile splitk_tiles_{stage}[] = {{' +
                            ','.join('{' + ','.join(map(str, r)) + '}' for r in rows) + '};')
        arrays = [j + [0] * (2 - len(j)), channels + [0] * (4 - len(channels)),
                  k + [0] * (4 - len(k)), padk + [0] * (4 - len(padk))]
        declarations.append(f'static const struct yolo32_splitk_plan splitk_plan_{stage} = ' +
                            '{' + f'{len(rows)}, splitk_tiles_{stage}, ' +
                            ','.join('{' + ','.join(map(str, a)) + '}' for a in arrays) + '};')
        replacement = name + '(' + ', '.join(args) + f', &splitk_plan_{stage});'
        if model.count(match[0]) != 1:
            raise ValueError('Split-K call is not unique')
        model = model.replace(match[0], replacement, 1)
    if len(plans) != 13:
        raise ValueError(f'Expected 13 Split-K stages, found {len(plans)}')
    for name in helpers:
        original = function(model, 'static void ' + name + '(')
        sig, body = original.split(') {', 1)
        config = body.index('  gemmini_extended_config_ex(')
        prefix = body[:config]
        # Replace only geometry planning. Keep checks, scales, commands and fences.
        start = prefix.index('  const size_t j_blocks')
        if 'two_consumer' in name:
            fixed = '''  const size_t j_blocks0 = fixed_plan->j_blocks[0];
  const size_t j_blocks1 = fixed_plan->j_blocks[1];
  const size_t k_blocks = fixed_plan->k_blocks[0];
  const size_t pad_k = fixed_plan->pad_k[0];
'''
        elif 'multi_slice' in name:
            fixed = '  const size_t j_blocks = fixed_plan->j_blocks[0];\n'
        else:
            fixed = '''  const size_t j_blocks = fixed_plan->j_blocks[0];
  const size_t k_blocks = fixed_plan->k_blocks[0];
  const size_t pad_k = fixed_plan->pad_k[0];
'''
        after = prefix.index('  const size_t tile_rows = max_i_blocks * DIM;', start)
        after += len('  const size_t tile_rows = max_i_blocks * DIM;')
        body = prefix[:start] + fixed + prefix[after:] + body[config:]
        loop = '  for (size_t row = 0; row < (size_t)positions; row += tile_rows) {'
        if body.count(loop) != 1:
            raise ValueError(f'Unexpected Split-K loop in {name}')
        start = body.index(loop)
        end = body.index('    const size_t pad_i = ', start)
        end = body.index(';', end) + 1
        i_names = ['i_blocks0', 'i_blocks1'] if 'two_consumer' in name else ['i_blocks']
        fixed_loop = '''  for (unsigned tile = 0; tile < fixed_plan->tile_count; ++tile) {
    const struct yolo32_splitk_tile *geometry = &fixed_plan->tiles[tile];
    const size_t row = geometry->row;
'''
        fixed_loop += ''.join(f'    const size_t {n} = geometry->i_blocks;\n' for n in i_names)
        fixed_loop += '    const size_t pad_i = geometry->pad_i;'
        body = body[:start] + fixed_loop + body[end:]
        if 'multi_slice' in name:
            begin = body.index('      const size_t channels = (size_t)slice_channels[slice];')
            end = body.index('      const bool first', begin)
            body = body[:begin] + '''      const size_t channels = fixed_plan->channels[slice];
      const size_t k_blocks = fixed_plan->k_blocks[slice];
      const size_t pad_k = fixed_plan->pad_k[slice];
''' + body[end:]
        replacement = sig + ', const struct yolo32_splitk_plan *fixed_plan) {' + body
        model = model.replace(original, replacement, 1)
    structs = '''struct yolo32_splitk_tile { size_t row, rows, i_blocks, pad_i; };
struct yolo32_splitk_plan {
  unsigned tile_count;
  const struct yolo32_splitk_tile *tiles;
  size_t j_blocks[2], channels[4], k_blocks[4], pad_k[4];
};
'''
    include = '#include "yolov5nu_head_layout.h"'
    model = model.replace(include, include + '\n' + structs + '\n'.join(declarations), 1)
    return model, plans


def bake(out, header, model, params_path, host_cc):
    model_digest = hashlib.sha256(model.encode()).hexdigest()
    params = hardware_parameters(params_path)
    calls, plans = native_plans(header, model, params, host_cc)
    for stage, args in calls:
        original = 'tiled_conv_auto(' + ', '.join(args) + ');'
        if model.count(original) != 1:
            raise ValueError(f'Convolution call mismatch at stage {stage}')
        fixed = args[:12] + [args[3], args[4], args[4]] + args[12:17]
        fixed += list(map(str, plans[stage]['tile'])) + args[17:]
        model = model.replace(original, 'tiled_conv(' + ', '.join(fixed) + ');', 1)
    model, splitk = bake_splitk(model, params)
    guard = '\n'.join(f'_Static_assert({k} == {v}, "Regenerate fixed YOLO32 plans: {k}");'
                      for k, v in params.items())
    guard += '\n_Static_assert(YOLO32_FIXED_PLANS == 1, "Fixed graph requires fixed plans build");\n'
    (out / 'fixed_plans_guard.inc').write_text(guard)
    model = model.replace('#include "include/gemmini.h"',
                          '#include "include/gemmini.h"\n#include "fixed_plans_guard.inc"', 1)
    manifest = dict(hardware=params, abi_sha256=hashlib.sha256(header.encode()).hexdigest(),
                    model_sha256=model_digest,
                    ordinary=plans, splitk=splitk,
                    ordinary_packets_per_worker=sum(p['packets'] for p in plans.values()))
    (out / 'fixed_plans.json').write_text(json.dumps(manifest, indent=2, sort_keys=True) + '\n')
    return model
