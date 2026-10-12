#!/usr/bin/env python3
"""Derive a three-worker tile executor from this project's native DIM32 ABI."""
from pathlib import Path
import argparse
import re

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
ABI = ROOT / 'sw/third_party/gemmini_v3/include/gemmini.h'
MODEL = HERE / 'native/yolov5nu_dim16_dual.c'


def function(text, begin):
    a = text.index(begin)
    b = text.index('{', a)
    depth, i = 1, b + 1
    while depth:
        depth += (text[i] == '{') - (text[i] == '}')
        i += 1
    return text[a:i]


def tail_wait_annotations(model):
    """Mark only complete WS packets immediately followed by native waits.

    Instructions, scales, reuse and fences are unchanged. The v14 hook defers
    the optional packet yield to that fence; macro=0 retains the v13 path.
    """
    helpers = {
        'gemmini_splitk_1x1_two_slice_i8': 2,
        'gemmini_splitk_1x1_two_slice_i8_spad_reuse': 2,
        'gemmini_splitk_1x1_two_slice_two_consumer_spad_reuse_i8': 4,
        'gemmini_splitk_1x1_multi_slice_i8': 1,
        'add_gemmini_resadd_strided_i8': 1,
        'add_gemmini_shared_resadd_i8': 1,
    }
    for name, count in helpers.items():
        begin = 'static void ' + name + '('
        pos = model.index(begin)
        if model.find(';', pos) < model.find('{', pos):
            pos = model.index(begin, pos + len(begin))
        original = function(model[pos:], begin)
        callee = 'sp_tiled_resadd' if name.startswith('add_') else 'sp_tiled_matmul_ws'
        needle = '    ' + callee + '('
        if original.count(needle) != count:
            raise ValueError('Tail wait annotation mismatch: ' + name)
        condition = 'yolo32_independent_enabled'
        marker = '#if YOLO32_TAIL_WAIT\n'
        if name.startswith('add_'):
            condition += ' && i + i_tile == (size_t)positions'
        if name.endswith('multi_slice_i8'):
            marker += '#if defined(YOLOV5NU_STAGE8_MODE_8H_SPLITK_CONFIG_FENCE_MERGE)\n'
            marker += '    if (' + condition + ' &&\n' \
                      '        (last || input_scales[slice] != input_scales[slice + 1]))\n'
            marker += '        yolo32_independent_arm_tail_wait(8U);\n#else\n'
        marker += '    if (' + condition + ') yolo32_independent_arm_tail_wait(8U);\n#endif\n'
        if name.endswith('multi_slice_i8'):
            marker += '#endif\n'
        model = model.replace(original, original.replace(needle, marker + needle), 1)
    return model


def generate(out, fixed_plans=False, params=None, host_cc='gcc', fixed_packets=False, prepared_packets=False):
    if prepared_packets and not fixed_packets:
        raise ValueError('Prepared packets require fixed packets')
    if fixed_packets and not fixed_plans:
        raise ValueError('Fixed packets require fixed plans')
    (out / 'include').mkdir(parents=True, exist_ok=True)
    header, model = ABI.read_text(), MODEL.read_text()
    native = function(header, 'static void tiled_conv(\n')
    sig, body = native.split(') {', 1)
    if fixed_plans:
        from fixed_plans import bake, remove_capacity_checks
        if params is None:
            raise ValueError('Fixed plans require the build hardware parameter header')
        fixed_model = bake(out, header, model, params, host_cc)
        if fixed_packets:
            from fixed_packets import bake as bake_packets
            fixed_model = bake_packets(out, header, fixed_model, params, host_cc)
        if prepared_packets:
            from prepared_packets import bake as bake_prepared
            fixed_model = bake_prepared(out, header, model, fixed_model, params, host_cc)
        body = remove_capacity_checks(body)
    parts = [p.strip() for p in sig[sig.index('(') + 1:].split(',')]
    names = [re.search(r'(\w+)$', p)[1] for p in parts]
    assert len(names) == 37
    struct = 'struct yolo32_conv_args {\n' + ''.join(p + ';\n' for p in parts) + '};\n'
    decl = struct + 'static struct yolo32_conv_args parallel_args[3];\n'
    capture = '''
    if (parallel_collecting) {
        unsigned w = gemmini_pool_active_worker;
        if (w >= 3 || (parallel_pending & (1U << w)))
            yolo32_fail("parallel_duplicate_descriptor");
'''
    capture += ''.join(f'        parallel_args[w].{n} = {n};\n' for n in names)
    capture += '        parallel_pending |= 1U << w;\n        return;\n    }\n'
    header = header.replace(native, decl + sig + ') {' + capture + body, 1)
    # Measure only operand-ready dispatch + the native instruction, before the
    # return hook can suspend this stack. Shared/live ABI files stay unchanged.
    start = '#define ROCC_INSTRUCTION_RS1_RS2(x, rs1, rs2, funct) { '
    end = '\n}\n#else\n#define GEMMINI_POOL_RECORD_COMMAND'
    a = header.index(start)
    b = header.index(end, a)
    macro = header[a:b]
    macro = macro.replace('  GEMMINI_POOL_COMMAND_ARGS_HOOK(funct, rs1, rs2);',
        '  uint64_t _yolo32_rs1=(uint64_t)(rs1), _yolo32_rs2=(uint64_t)(rs2); \\\n'
        '  GEMMINI_POOL_COMMAND_ARGS_HOOK(funct, _yolo32_rs1, _yolo32_rs2); \\\n'
        '  __asm__ volatile("" :: "r"(_yolo32_rs1), "r"(_yolo32_rs2) : "memory"); \\\n'
        '  uint64_t _yolo32_start=GEMMINI_POOL_COMMAND_CLOCK(funct);')
    for op in (1, 2, 3):
        macro = macro.replace(f'ROCC_INSTRUCTION_0_R_R({op}, rs1, rs2, funct)',
                              f'ROCC_INSTRUCTION_0_R_R({op}, _yolo32_rs1, _yolo32_rs2, funct)')
    macro = macro.replace('  GEMMINI_POOL_COMMAND_RETURN_HOOK(funct);',
        '  GEMMINI_POOL_COMMAND_ELAPSED(funct, _yolo32_start); \\\n'
        '  GEMMINI_POOL_COMMAND_RETURN_HOOK(funct);')
    defaults = '''#ifndef GEMMINI_POOL_COMMAND_CLOCK
#define GEMMINI_POOL_COMMAND_CLOCK(funct) UINT64_C(0)
#define GEMMINI_POOL_COMMAND_ELAPSED(funct, start) do { (void)(start); } while (0)
#endif
'''
    header = header[:a] + defaults + macro + header[b:]
    (out / 'include/gemmini.h').write_text(header)

    a = body.index('    gemmini_extended_config_st(')
    b = body.index('\n    const int pool_out_row_dim', a)
    body = body[:a] + '    for (unsigned w=0; w<3; ++w) { gemmini_pool_active_worker=w;\n' + body[a:b] + '\n    }\n' + body[b:]
    a = body.index('                                sp_tiled_conv(')
    b = body.index('false, a_spad_id, b_spad_id);', a) + len('false, a_spad_id, b_spad_id);')
    call = body[a:b]
    # Weights/bias must match. Independent activation arenas require offset mapping;
    # preserve NULL markers for native accumulation and scratchpad reuse.
    for n, base in [('in', 'input'), ('out', 'output')]:
        needle = '                                    ' + n + ','
        assert call.count(needle) == 1
        mapped = f'(w == 0 ? {n} : ({n} ? parallel_args[w].{base} + ({n} - {base}) : NULL))'
        call = call.replace(needle, '                                    ' + mapped + ',')
    body = body[:a] + '                                for (unsigned w=0; w<3; ++w) { gemmini_pool_active_worker=w;\n' + call + '\n                                }\n                                ++parallel_stats.tile_groups;\n                                parallel_sample_busy();\n' + body[b:]
    executor = sig.replace('tiled_conv(', 'yolo32_group_conv(') + ') {' + body
    executor += '\nstatic void parallel_execute(void) {\n    if (parallel_pending != 7) yolo32_fail("parallel_incomplete_descriptors");\n'
    for n in names:
        if n in ('input', 'output'):
            continue
        executor += f'    for (unsigned w=1; w<3; ++w) if (parallel_args[0].{n} != parallel_args[w].{n}) yolo32_fail("parallel_field_{n}");\n'
    executor += '    parallel_collecting=0;\n    yolo32_group_conv(' + ','.join('parallel_args[0].' + n for n in names) + ');\n    parallel_drain();\n    ++parallel_stats.conv_groups;\n    parallel_pending=0;\n}\n'
    (out / 'parallel_executor.inc').write_text(
        '/* Packet executor is in fixed_conv_packets.inc. */\n' if fixed_packets else executor)

    poll = function(model, 'int yolov5nu_dim16_worker_poll(')
    blocks = re.split(r'    case (\d+)U:', poll)[1:]
    stages = {int(blocks[i]): blocks[i + 1] for i in range(0, len(blocks), 2)}
    assert set(stages) == set(range(167))
    conv = [int('tiled_conv_auto(' in stages[i]) for i in range(167)]
    assert sum(conv) == 58
    # Every CPU stage also yields once in lockstep mode. Serial paths stay intact.
    tail = '    }\n  }\n}'
    assert poll.endswith(tail)
    patched = poll[:-len(tail)] + '    }\n    if (parallel_mode) return YOLOV5NU_DIM16_RUNNING;\n  }\n}'
    # Fixed-image firmware now stops at raw heads. CPU Class/DFL/Decode/NMS
    # is deliberately removed from this poll, including any fallback path.
    post = patched.index('    case 165U:')
    patched = patched[:post] + '''    case 165U:
      gemmini_fence();
      frame_counter_finish(worker_id);
      context->stage = YOLOV5NU_GRAPH_STAGE_COUNT;
      return YOLOV5NU_DIM16_HEAD_READY;
    default: return YOLOV5NU_DIM16_ERROR;
    }
    if (parallel_mode || yolo32_independent_enabled || analysis_enabled) return YOLOV5NU_DIM16_RUNNING;
  }
}'''
    patched = patched.replace('if (parallel_mode) return',
                              'if (parallel_mode || (analysis_enabled && context->stage < 165U)) return')
    model = model.replace(poll, patched, 1)
    if fixed_plans:
        # Apply the same poll/PPU transformations to the fixed graph. Ordinary
        # calls retain the captured tiled_conv ABI used by lockstep controls.
        fixed_poll = function(fixed_model, 'int yolov5nu_dim16_worker_poll(')
        fixed_patched = fixed_poll[:fixed_poll.index('    case 165U:')] + patched[patched.index('    case 165U:'):]
        model = fixed_model.replace(fixed_poll, fixed_patched, 1)
    # The independent task already completes each native dependency at the
    # scoped fence. Do not add the old poll-armed delay on its next stage.
    model = model.replace('  if (context->waiting != 0U) {',
        '  if (yolo32_independent_enabled) context->waiting = context->poll_armed = 0;\n'
        '  if (context->waiting != 0U) {', 1)
    # All native fences, including Split-K internal scale/LUT boundaries,
    # pass through this helper. Legacy modes retain the hardware fence.
    model = model.replace('  asm volatile("fence" ::: "memory");',
        '  if (yolo32_independent_enabled) yolo32_independent_wait();\n'
        '  else asm volatile("fence" ::: "memory");', 1)
    model = re.sub(r'head_callback\(worker_id, ([0-5])\)',
                   r'yolo32_publish_head(worker_id, \1)', model)
    # Detailed instrumentation is enabled only for dedicated analysis passes.
    model = model.replace('  asm volatile("rdcycle %0"',
                          '  if (!analysis_enabled) return 0;\n  asm volatile("rdcycle %0"', 1)
    model = model.replace('  memset(&frame_profiles[worker_id], 0, sizeof(frame_profiles[worker_id]));',
                          '  memset(&frame_profiles[worker_id], 0, sizeof(frame_profiles[worker_id]));\n'
                          '  if (!analysis_enabled) return;', 1)
    model = model.replace('static void frame_counter_finish(uint32_t worker_id) {',
                          'static void frame_counter_finish(uint32_t worker_id) {\n'
                          '  if (!analysis_enabled) return;', 1)
    # Parallel tile submission bypasses the model's ordinary conv timer.
    # Do not label descriptor capture time as actual accelerator submission.
    if fixed_packets:
        model = tail_wait_annotations(model)
    (out / 'parallel_model.inc').write_text(model)
    (out / 'parallel_stages.inc').write_text('static const unsigned char parallel_conv_stage[167] = {' + ','.join(map(str, conv)) + '};\n')
    kinds, labels = [], []
    for i in range(165):
        block = stages[i]
        match = re.search(r'yolo_profile_begin\([^,]+, "([^"]+)", "([^"]+)"', block)
        kind = 'conv' if conv[i] else (match[1].lower() if match else 'cpu')
        if 'gemmini_splitk_' in block:
            kind = 'splitk'
        elif 'add_gemmini_' in block:
            kind = 'resadd'
        kinds.append(kind)
        labels.append(match[2] if match else f'stage{i}')
    (out / 'parallel_stages.inc').write_text((out / 'parallel_stages.inc').read_text()
        + 'static const char *const stage_kinds[165] = {' + ','.join('"'+k+'"' for k in kinds) + '};\n'
        + 'static const char *const stage_labels[165] = {' + ','.join('"'+k+'"' for k in labels) + '};\n')
    print('Generated DIM32 graph: 167 stages, 58 three-worker convolutions, hardware backpressure')
    if fixed_plans:
        print('Fixed plans: 58 ordinary + 13 Split-K stages; native planner runs only at build time')
    if fixed_packets:
        print('Fixed packets: 469 ordinary-convolution packets per worker; native FP16 operands + byte offsets')
    if prepared_packets:
        print('Prepared packets: 224 WS packets per worker + 69 packed SiLU tables; native commands and waits preserved')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('out', type=Path)
    parser.add_argument('--fixed-plans', action='store_true')
    parser.add_argument('--fixed-packets', action='store_true')
    parser.add_argument('--prepared-packets', action='store_true')
    parser.add_argument('--params', type=Path)
    parser.add_argument('--host-cc', default='gcc')
    args = parser.parse_args()
    generate(args.out, args.fixed_plans, args.params, args.host_cc, args.fixed_packets, args.prepared_packets)
