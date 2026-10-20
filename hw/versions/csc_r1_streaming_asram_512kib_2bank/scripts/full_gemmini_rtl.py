#!/usr/bin/env python3
"""Build unmodified C0 Gemmini, including RS, EX, DMA and physical SRAM.

The external memory service is a deterministic functional model. Its cycles
are not full-system cycles. No generated/production source is edited.
"""
import argparse
import hashlib
import json
import os
import re
import shutil
from pathlib import Path
import subprocess
import sys

from full_command_rtl import closure, ports, FEATURE


def vivado_executable():
    configured = os.environ.get('VIVADO_BIN')
    if not configured:
        local = FEATURE.parents[2] / 'tools/config/tools.local.mk'
        if local.is_file():
            match = re.search(r'^\s*VIVADO_BIN\s*(?::=|\?=|=)\s*([^\n#]+)', local.read_text(), re.M)
            if match and '$' not in match[1]:
                configured = match[1].strip().strip('"\'')
    executable = shutil.which(configured or 'vivado')
    if not executable:
        raise ValueError('Set VIVADO_BIN or configure tools/config/tools.local.mk')
    return Path(executable).resolve()


def wrapper(rtl):
    ps = ports(rtl / 'Gemmini.sv')
    selected = [p for p in ps if p[2] in ('clock', 'reset', 'io_cmd_ready', 'io_cmd_valid',
                'io_cmd_bits_inst_funct', 'io_cmd_bits_rs1', 'io_cmd_bits_rs2', 'io_busy',
                'io_interrupt', 'io_dma_load_mode') or p[2].startswith('auto_spad_id_out_')]
    declarations = [f'{d} wire {w} {n}' for d, w, n in selected]
    declarations += ['output wire row_fire,credit_valid,complete_valid',
                     'output wire get_reserve', 'output wire [4:0] get_source',
                     'output wire [7:0] get_cmd',
                     'output wire [5:0] metric_signals',
                     'output wire [7:0] credit_id,complete_rob,row_rob',
                     'output wire [15:0] credit_bytes',
                     'output wire [7:0] wa,wc,wx,wz,ri,rr,rd',
                     'output wire [10:0] wa_addr[0:7],wc_addr[0:7],ri_addr[0:7],rr_addr[0:7]',
                     'output wire [31:0] wa_mask[0:7],wc_mask[0:7]',
                     'output wire [255:0] wa_data[0:7],wc_data[0:7],rd_data[0:7]',
                     'output wire [7:0] wa_id[0:7]']
    fields = ['vaddr', 'laddr_data', 'laddr_is_acc_addr', 'cols', 'repeats', 'scale',
              'has_acc_bitwidth', 'all_zeros', 'block_stride', 'pixel_repeats',
              'cmd_id', 'cmd_first', 'cmd_last', 'cmd_rows', 'row_index', 'cmd_stride_bytes']
    ld = ports(rtl / 'LoadController.sv')
    for field in fields:
        width = next(w for d, w, n in ld if n == 'io_dma_req_bits_' + field)
        declarations.append(f'output wire {width} row_{field}')
    text = 'module FullGemmini(' + ',\n'.join(declarations) + ');\nglbl glbl();\n'
    names = {n for d, w, n in selected}
    bindings = []
    for direction, width, name in ps:
        value = name if name in names else ('' if direction == 'output' else "'0")
        if name in ('io_resp_ready', 'io_cmd_bits_inst_xs1', 'io_cmd_bits_inst_xs2'):
            value = "1'b1"
        if name in ('io_cmd_bits_status_prv', 'io_cmd_bits_status_dprv'):
            value = "2'd3"
        if name == 'io_cmd_bits_inst_opcode':
            value = "7'h0b"
        if name == 'io_loopconv_request_accept':
            value = "io_cmd_valid && io_cmd_ready && io_cmd_bits_inst_funct==15"
        bindings.append(f'.{name}({value})')
    text += 'Gemmini dut(' + ',\n'.join(bindings) + ');\n'
    p = 'dut.load_controller'
    text += f'assign row_fire={p}.io_dma_req_valid && {p}.io_dma_req_ready;\n'
    for field in fields:
        text += f'assign row_{field}={p}.io_dma_req_bits_{field};\n'
    text += f'''assign row_rob={p}._cmd_q_io_deq_bits_rob_id_bits;
assign credit_valid={p}.io_dma_resp_valid;
assign credit_id={p}.io_dma_resp_bits_cmd_id;
assign credit_bytes={p}.io_dma_resp_bits_bytesRead;
assign complete_valid={p}.io_completed_valid && {p}.io_completed_ready;
assign complete_rob={p}.io_completed_bits;
assign get_reserve=dut.spad.reader.core.io_reserve_valid && dut.spad.reader.core.io_reserve_ready;
assign get_source=dut.spad.reader.core.io_reserve_xactid;
assign get_cmd=dut.spad.reader.core.io_reserve_entry_group ?
 (dut.spad.reader.core.io_reserve_entry_group_id ? dut.spad.group.descriptor_1_cmd_id : dut.spad.group.descriptor_0_cmd_id) :
 dut.spad.reader.core.req_cmd_id;
assign metric_signals={{dut.load_controller.io_counter_event_signal_10,dut.load_controller.io_busy,
 dut.ex_controller.io_counter_event_signal_31,dut.ex_controller.io_counter_event_signal_30,
 dut.ex_controller.io_counter_event_signal_29,dut.ex_controller.io_counter_event_signal_24}};
'''
    for bank in range(8):
        q = 'dut.spad.' + ('pending' if bank == 0 else f'pending_{bank}')
        ex = 'dut.spad.' + ('ex_read_skid' if bank == 0 else f'ex_read_skid_{bank}')
        b = f'dut.spad.spad_mems_{bank}'
        text += f'''assign wa[{bank}]={q}.io_enq_valid && {q}.io_enq_ready;
assign wc[{bank}]={q}.io_deq_valid;
assign wx[{bank}]={q}.io_enq_bits_ex;
assign wz[{bank}]={q}.io_enq_bits_zero;
assign wa_addr[{bank}]={q}.io_enq_bits_addr;
assign wc_addr[{bank}]={q}.io_deq_bits_addr;
assign wa_data[{bank}]={q}.io_enq_bits_data;
assign wc_data[{bank}]={q}.io_deq_bits_data;
assign wa_id[{bank}]=dut.spad.{'selected' if bank == 0 else f'selected_{bank}'}==2 ?
 dut.spad._zeroWriteBuffer_io_deq_bits_tag_cmd_id : dut.spad._mvinWriteBuffer_io_deq_bits_tag_cmd_id;
assign ri[{bank}]={ex}.io_deq_valid;
assign ri_addr[{bank}]={ex}.io_deq_bits_addr;
assign rr[{bank}]={b}.io_read_req_valid && {b}.io_read_req_ready;
assign rr_addr[{bank}]={b}.io_read_req_bits_addr;
assign rd[{bank}]={b}.io_read_resp_valid && {b}.io_read_resp_ready;
assign rd_data[{bank}]={b}.io_read_resp_bits_data;
'''
        for port, direction in [('wa', 'enq'), ('wc', 'deq')]:
            mask = '{' + ','.join(f'{q}.io_{direction}_bits_mask_{j}' for j in reversed(range(32))) + '}'
            text += f'assign {port}_mask[{bank}]={mask};\n'
    return text + 'endmodule\n'


def build(context, out, threads=1):
    out.mkdir(parents=True, exist_ok=False)
    identity = json.loads(context.read_text())
    rtl = context.parent / 'gen-collateral'
    sources = closure(rtl, ('Gemmini',))
    for path in sources:
        if hashlib.sha256(path.read_bytes()).hexdigest() != identity['final_rtl_sha256'][path.name]:
            raise ValueError('RTL hash mismatch: ' + str(path))
    vendor = vivado_executable().parents[1] / 'data/verilog/src'
    original_primitive = vendor / 'unisims/RAMB36E2.v'
    primitive = out / 'RAMB36E2_functional.v'
    # Verilator 5.044 cannot parse Xilinx PATHPULSE$. Omit the specify timing
    # annotation only; retain the vendor's complete functional implementation.
    adapted, count = re.subn(r'\bspecify\b.*?\bendspecify\b', '', original_primitive.read_text(), flags=re.S)
    if count != 1:
        raise ValueError('Unexpected vendor specify block count')
    # Every primitive input is explicitly driven by SiluLutBramMulti. In this
    # two-state harness the vendor's disconnected-input Z tests are constants.
    adapted, z_count = re.subn(r"\(([A-Za-z0-9_]+(?:\[\d+\])?) (===|!==) 1'bz\)",
                              lambda m: "(1'b0)" if m[2] == '===' else "(1'b1)", adapted)
    if z_count < 100:
        raise ValueError('Unexpected vendor disconnected-input tests')
    adapted = adapted.replace('tri0 glblGSR', 'wire glblGSR')
    primitive.write_text(adapted)
    sources += [primitive, vendor / 'glbl.v']
    top = out / 'FullGemmini.sv'
    top.write_text(wrapper(rtl))
    original_driver = FEATURE / 'tests/full_gemmini_driver.cpp'
    driver = out / 'full_gemmini_driver.cpp'
    shutil.copyfile(original_driver, driver)
    prefix = Path(sys.executable).resolve().parents[1]
    cflags = '-O2 -std=c++17'
    ldflags = '-lz'
    if (prefix / 'include/zlib.h').is_file():
        cflags += ' -I' + str(prefix / 'include')
        ldflags = f'-L{prefix}/lib -Wl,-rpath,{prefix}/lib -lz'
    command = ['verilator', '--cc', '--exe', '--build', '--assert', '--timing', '-Wno-fatal',
               '--top-module', 'FullGemmini', '--Mdir', str(out / 'obj'), '-j', '4', '--threads', str(threads),
               '-CFLAGS', cflags, '-LDFLAGS', ldflags, str(top), *map(str, sources), str(driver)]
    (out / 'compile_command.json').write_text(json.dumps(command, indent=2) + '\n')
    subprocess.run(command, check=True)
    manifest = dict(schema=1, status='FULL_GEMMINI_RTL_BUILT', build_id=identity['dma_load_build_id'],
                    backend='Functional sparse physical memory; real EX/RS/SRAM/DMA',
                    performance_model=False,
                    verilator_threads=threads,
                    vendor_adaptation='Experiment-local specify removal and constant Z checks for explicitly driven two-state inputs',
                    vendor_z_tests_simplified=z_count,
                    sha256={str(p): hashlib.sha256(p.read_bytes()).hexdigest() for p in [context, top, driver, original_driver, original_primitive, *sources]})
    (out / 'build_manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--context', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--threads', type=int, choices=(1, 2, 4, 8), default=1)
    args = parser.parse_args()
    build(args.context.resolve(), args.output.resolve(), args.threads)
