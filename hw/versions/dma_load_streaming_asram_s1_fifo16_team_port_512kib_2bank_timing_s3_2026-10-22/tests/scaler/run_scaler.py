#!/usr/bin/env python3
"""Compare native generated INT8/FP16 scalers against FIFO16 and finite math."""
import argparse
import hashlib
import json
import math
import os
from pathlib import Path
import random
import re
import struct
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'scripts'))
from common import selected_output, sha
from rtl_support import module_closure, ports


def namespaced_sources(rtl, out, prefix):
    sources = module_closure(rtl, ['VectorScalarMultiplier'])
    names = [name for path in sources
             for name in re.findall(r'^module\s+(\w+)', path.read_text(), re.M)]
    pattern = re.compile(r'\b(' + '|'.join(map(re.escape, names)) + r')\b')
    result = []
    for path in sources:
        target = out / (prefix + path.name)
        # Rename only symbols in disposable simulation copies so both native
        # module closures can coexist; production RTL remains hash checked.
        target.write_text(pattern.sub(lambda m: prefix + m[0], path.read_text()))
        result.append(target)
    return result


def wrapper(rtl, prefix, alias, lane_skip=False):
    bindings = []
    outputs = dict(io_req_ready='req_ready', io_resp_valid='resp_valid',
                   io_resp_bits_row='out_row', io_resp_bits_last='out_last',
                   io_resp_bits_tag_cmd_id='out_tag')
    inputs = dict(clock='clock', reset='reset', io_req_valid='req_valid',
                  io_req_bits_scale_bits='in_scale', io_req_bits_repeats='in_repeats',
                  io_req_bits_last='in_last', io_req_bits_tag_cmd_id='in_tag',
                  io_resp_ready='resp_ready')
    for lane in range(32):
        inputs[f'io_req_bits_in_{lane}'] = f'in_data[{lane*8}+:8]'
        # Match Scratchpad's elaborated binding when exercising a native
        # scaler outside its parent: a disabled skip flag supplies all-valid.
        inputs[f'io_req_bits_lane_valid_{lane}'] = f'in_mask[{lane}]' if lane_skip else "1'b1"
        inputs[f'io_req_bits_tag_mask_{lane}'] = f'in_mask[{lane}]'
        outputs[f'io_resp_bits_out_{lane}'] = f'out_data[{lane*8}+:8]'
        outputs[f'io_resp_bits_tag_mask_{lane}'] = f'out_mask[{lane}]'
    ps = ports(rtl / 'VectorScalarMultiplier.sv')
    assert {name for _, _, name in ps} >= set(outputs)
    for direction, _, name in ps:
        value = inputs.get(name, "'0") if direction == 'input' else outputs.get(name, '')
        bindings.append(f'.{name}({value})')
    pipes = re.findall(r'^\s*ScalePipe(?:_\d+)?\s+(\w+)\s*\(',
                       (rtl / 'VectorScalarMultiplier.sv').read_text(), re.M)
    assert len(pipes) == 4, pipes
    tasks = '+'.join(f"32'(native_dut.{name}.io_in_valid)" for name in pipes)
    return f'''module {alias}(
        input clock,reset,req_valid,output req_ready,
        input [255:0] in_data,input [31:0] in_mask,
        input [15:0] in_scale,in_repeats,input [7:0] in_tag,input in_last,
        output resp_valid,input resp_ready,output [255:0] out_data,
        output [31:0] out_mask,output [15:0] out_row,
        output [7:0] out_tag,output out_last,output [31:0] scale_tasks);
        {prefix}VectorScalarMultiplier native_dut(''' + ','.join(bindings) + f''');
        assign scale_tasks={tasks};
    endmodule
'''


def fp16_scale(value, bits):
    scale = struct.unpack('<e', struct.pack('<H', bits))[0]
    if not math.isfinite(scale):
        return 0
    try:
        product = struct.unpack('<e', struct.pack('<e', value * scale))[0]
    except OverflowError:
        product = math.copysign(math.inf, value * scale)
    if math.isinf(product):
        return -128 if product < 0 else 127
    return max(-128, min(127, round(product)))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--generated', type=Path, required=True)
    parser.add_argument('--reference', type=Path, default=ROOT / 'build/fifo16_baseline/generated')
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--jobs', type=int, default=4)
    parser.add_argument('--workload', choices=('matrix', 'full-mask', 'identity'), default='matrix')
    args = parser.parse_args()
    out = args.output.resolve()
    if ROOT / 'build' not in out.parents:
        raise ValueError('Use a new output below candidate build/')
    out.mkdir(parents=True, exist_ok=False)
    generated, context = selected_output(args.generated)
    reference, reference_context = selected_output(args.reference)
    rtl, ref = generated / 'gen-collateral', reference / 'gen-collateral'
    enabled = context.get('build_parameters', {}).get('S1_MVIN_SKIP', '0') == '1'
    rng = random.Random(0x513216)
    masks = [(1 << n) - 1 for n in (0, 1, 15, 16, 31, 32)] + [0x55555555, 0x80000001, 0xf0f00f0f]
    scales = [0x3c00, 0x3800, 0x4000, 0x3555, 0x3c01, 0x0400, 0x0001,
              0x8000, 0xbc00, 0x7bff, 0xfbff, 0x7c00, 0xfc00, 0x7e00]
    cases = [(mask, scale) for mask in masks for scale in scales]
    cases += [(rng.getrandbits(32), rng.choice(scales)) for _ in range(96)]
    if args.workload == 'full-mask':
        cases = [(0xffffffff, scales[i % len(scales)]) for i in range(160)]
    elif args.workload == 'identity':
        cases = [(rng.getrandbits(32), 0x3c00) for _ in range(160)]
    requests, golden, metadata = [], [], []
    ref_ops, new_ops = 0, 0
    for tag, (mask, scale) in enumerate(cases):
        repeats = tag % 4
        last = int(tag % 3 != 0)
        data = [rng.randrange(-128, 128) for _ in range(32)]
        data[:8] = [-128, -127, -3, -1, 0, 1, 3, 127]
        packed_data = sum((v & 255) << (8*i) for i, v in enumerate(data))
        requests.append(packed_data | mask << 256 | scale << 288 | repeats << 304 | tag << 320 | last << 328)
        expected = sum((fp16_scale(v, scale) & 255) << (8*i) for i, v in enumerate(data))
        finite = (scale >> 10) & 31 != 31
        for row in reversed(range(repeats+1)):
            golden.append(expected)
            metadata.append(int(finite) << 57 | mask << 25 | tag << 17 | row << 1 | (last if row == 0 else 0))
        if scale != 0x3c00:
            ref_ops += 32 * (repeats+1)
            new_ops += (mask.bit_count() if enabled else 32) * (repeats+1)
    assert len(requests) <= 256 and len(golden) <= 1024
    for name, values in (('requests', requests), ('golden', golden), ('metadata', metadata)):
        (out / (name + '.mem')).write_text('\n'.join(f'{v:x}' for v in values) + '\n')
    sources = namespaced_sources(ref, out, 'Ref_') + namespaced_sources(rtl, out, 'New_')
    (out / 'wrappers.sv').write_text(wrapper(ref, 'Ref_', 'ScalerRef') + wrapper(rtl, 'New_', 'ScalerNew', enabled))
    sources += [out / 'wrappers.sv', ROOT / 'tests/scaler/tb_scaler.sv']
    command = [os.environ.get('VERILATOR', 'verilator'), '--binary', '--timing', '--assert',
               '-Wno-fatal', '-j', str(args.jobs), '--top-module', 'tb_scaler',
               '--Mdir', str(out / 'obj'), '-DREQUESTS=' + str(len(requests)),
               '-DRESPONSES=' + str(len(golden)), '-DREF_OPS=' + str(ref_ops),
               '-DNEW_OPS=' + str(new_ops), *map(str, sources)]
    if args.workload != 'matrix':
        command.insert(1, '-DLOCKSTEP_RESP=1')
    with (out / 'build.log').open('w') as log:
        subprocess.run(command, cwd=out, stdout=log, stderr=subprocess.STDOUT, check=True)
    completed = subprocess.run([str(out / 'obj/Vtb_scaler')], cwd=out,
                               stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    (out / 'result.log').write_text(completed.stdout)
    print(completed.stdout, flush=True)
    completed.check_returncode()
    assert 'S1_SCALER_PASS,' in completed.stdout
    (out / 'evidence.json').write_text(json.dumps(dict(status='PASS',
        hardware_build_id=context['dma_load_build_id'], reference_build_id=reference_context['dma_load_build_id'],
        skip_enabled=enabled, requests=len(requests), responses=len(golden),
        workload=args.workload, cycle_identical=args.workload != 'matrix',
        reference_tasks=ref_ops, candidate_tasks=new_ops,
        source_sha256={str(p.relative_to(ROOT)): sha(p) for p in (Path(__file__), ROOT / 'tests/scaler/tb_scaler.sv')},
        result_sha256=hashlib.sha256(completed.stdout.encode()).hexdigest()), indent=2) + '\n')


if __name__ == '__main__':
    main()
