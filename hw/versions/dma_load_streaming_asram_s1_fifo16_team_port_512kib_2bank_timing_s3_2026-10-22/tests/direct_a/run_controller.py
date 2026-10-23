#!/usr/bin/env python3
"""Exercise native DirectA32 LoadController and placement from the full SoC."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'scripts'))
from common import selected_output, sha
from rtl_support import module_closure, ports


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--generated', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    out = args.output.resolve()
    if ROOT / 'build' not in out.parents:
        raise ValueError('Use a new output below this hardware version build/')
    out.mkdir(parents=True, exist_ok=False)
    generated, context = selected_output(args.generated)
    assert context['build_parameters']['S1_DIRECT_A'] == '1'
    rtl = generated / 'gen-collateral'
    inputs = dict(clock='clock', reset='reset', io_cmd_valid='cmd_valid',
        io_cmd_bits_cmd_inst_funct='cmd_funct', io_cmd_bits_cmd_rs1='cmd_rs1',
        io_cmd_bits_cmd_rs2='cmd_rs2', io_cmd_bits_rob_id_bits='cmd_rob',
        io_dma_req_ready='req_ready', io_dma_resp_valid='resp_valid',
        io_dma_resp_bits_bytesRead='resp_bytes', io_dma_resp_bits_cmd_id='resp_id',
        io_completed_ready="1'b1")
    outputs = dict(io_cmd_ready='cmd_ready', io_dma_req_valid='req_valid',
        io_completed_valid='completed_valid', io_completed_bits='completed_rob', io_busy='busy')
    for field, name in dict(vaddr='address', laddr_data='local_address', cols='cols',
        repeats='repeats', scale='scale', block_stride='block_stride', pixel_repeats='pixels',
        cmd_id='request_id', cmd_rows='rows', row_index='row_index', cmd_first='first',
        cmd_last='last', cmd_stride_bytes='stride', dual='dual', lane_high='high',
        has_acc_bitwidth='has_acc', all_zeros='zeros').items():
        outputs['io_dma_req_bits_' + field] = name
    ps = ports(rtl / 'LoadController.sv')
    assert set(outputs) <= {name for _, _, name in ps}
    bindings = []
    for direction, _, name in ps:
        value = inputs.get(name, "'0") if direction == 'input' else outputs.get(name, '')
        bindings.append(f'.{name}({value})')
    (out / 'wrapper.sv').write_text('''module ControllerProbe(
        input clock,reset,cmd_valid,output cmd_ready,input [6:0] cmd_funct,cmd_rob,
        input [63:0] cmd_rs1,cmd_rs2,input req_ready,output req_valid,
        input resp_valid,input [15:0] resp_bytes,input [7:0] resp_id,
        output completed_valid,output [6:0] completed_rob,output busy,
        output [39:0] address,stride,output [13:0] local_address,
        output [15:0] cols,repeats,scale,block_stride,output [7:0] pixels,request_id,
        output [5:0] rows,output [4:0] row_index,output first,last,dual,high,has_acc,zeros);
        LoadController native_dut(''' + ','.join(bindings) + ');\nendmodule\n')
    sources = module_closure(rtl, ['LoadController', 'S1MvinLanePlace'])
    sources += [out / 'wrapper.sv', ROOT / 'tests/direct_a/tb_controller.sv']
    with (out / 'build.log').open('w') as log:
        subprocess.run([os.environ.get('VERILATOR', 'verilator'), '--binary', '--timing', '--assert',
            '-Wno-fatal', '-j', '4', '--top-module', 'tb_controller', '--Mdir', str(out / 'obj'),
            *map(str, sources)], stdout=log, stderr=subprocess.STDOUT, check=True)
    result = subprocess.run([str(out / 'obj/Vtb_controller')], stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, text=True)
    (out / 'result.log').write_text(result.stdout)
    print(result.stdout, flush=True)
    result.check_returncode()
    assert 'S1_DIRECT_A_CONTROLLER_PASS' in result.stdout
    (out / 'evidence.json').write_text(json.dumps(dict(status='PASS',
        hardware_build_id=context['dma_load_build_id'], cases=36, ld_states=3,
        placement_cases=256, native_dma_or_compute_executed=False,
        result_sha256=sha(out / 'result.log')), indent=2) + '\n')


if __name__ == '__main__':
    main()
