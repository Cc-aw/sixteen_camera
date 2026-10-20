#!/usr/bin/env python3
"""Build actual generated loop/load RTL for full-shape command enumeration.

The backend returns row byte credits without memory or computation. This is an
address-only necessary-condition experiment, never numerical/performance proof.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[4]
FEATURE = Path(__file__).resolve().parents[1]


def ports(path):
    header = re.sub(r'//[^\n]*', '', path.read_text().split(');', 1)[0])
    return re.findall(r'^\s*(input|output)\s+(\[[^]]+\]\s*)?(\w+)\s*[,\n]', header, re.M)


def closure(rtl, roots):
    mapping, contents = {}, {}
    for path in rtl.rglob('*'):
        if path.suffix not in ('.sv', '.v'):
            continue
        contents[path] = path.read_text()
        for name in re.findall(r'^module\s+(\w+)', contents[path], re.M):
            mapping[name] = path
    seen = set()

    def visit(name):
        path = mapping[name]
        if path in seen:
            return
        seen.add(path)
        for dep in re.findall(r'^\s+(\w+)\s+(?:#\s*\(|\w+\s*\()', contents[path], re.M):
            if dep in mapping:
                visit(dep)
    for name in roots:
        visit(name)
    return sorted(seen)


def wrapper(rtl):
    ps = {name: ports(rtl / (name + '.sv')) for name in ('LoopConv', 'LoopMatmul', 'LoadController')}
    row_fields = ['vaddr', 'laddr_data', 'laddr_is_acc_addr', 'cols', 'repeats', 'scale',
                  'has_acc_bitwidth', 'all_zeros', 'block_stride', 'pixel_repeats',
                  'cmd_id', 'cmd_first', 'cmd_last', 'cmd_rows', 'row_index', 'cmd_stride_bytes']
    output_ports = ['output wire busy,cmd_fire,row_fire', 'output wire [6:0] cmd_funct',
                    'output wire [63:0] cmd_rs1,cmd_rs2', 'output wire cmd_conv,cmd_ws']
    for field in row_fields:
        port = next(p for p in ps['LoadController'] if p[2] == 'io_dma_req_bits_' + field)
        output_ports.append(f'output wire {port[1]} row_{field}')
    text = 'module CscCommandTrace(input wire clock,reset,in_valid,output wire in_ready,\n'
    text += 'input wire [6:0] in_funct,input wire [63:0] in_rs1,in_rs2,input wire stall,\n'
    text += ',\n'.join(output_ports) + ');\n'
    for module, prefix in [('LoopConv', 'cv'), ('LoopMatmul', 'ws'), ('LoadController', 'ld')]:
        for direction, width, name in ps[module]:
            if direction == 'output':
                text += f'wire {width} {prefix}_{name};\n'
    text += r'''
wire is_load=ws_io_out_bits_cmd_inst_funct==1 || ws_io_out_bits_cmd_inst_funct==2 || ws_io_out_bits_cmd_inst_funct==14;
wire cfg_load=ws_io_out_bits_cmd_inst_funct==0 && ws_io_out_bits_cmd_rs1[1:0]==1;
wire cfg_store=ws_io_out_bits_cmd_inst_funct==0 && ws_io_out_bits_cmd_rs1[1:0]==2;
wire store_cmd=ws_io_out_bits_cmd_inst_funct==3 || ws_io_out_bits_cmd_inst_funct==23;
wire to_ld=is_load || cfg_load;
wire out_ready=!stall && (to_ld?ld_io_cmd_ready:1'b1);
reg [6:0] rob_next=0;
reg rob_cv[0:127],rob_ws[0:127];
reg cv_ld=0,cv_st=0,cv_ex=0,ws_ld=0,ws_st=0,ws_ex=0;
reg resp_valid=0;reg [7:0] resp_id=0;reg [15:0] resp_bytes=0;
wire [6:0] completed_id=ld_io_completed_bits;
wire cv_ld_done=ld_io_completed_valid && rob_cv[completed_id];
wire ws_ld_done=ld_io_completed_valid && rob_ws[completed_id];
assign cmd_fire=ws_io_out_valid && out_ready;
assign cmd_funct=ws_io_out_bits_cmd_inst_funct;
assign cmd_rs1=ws_io_out_bits_cmd_rs1;
assign cmd_rs2=ws_io_out_bits_cmd_rs2;
assign cmd_conv=ws_io_out_bits_from_conv_fsm;
assign cmd_ws=ws_io_out_bits_from_matmul_fsm;
assign row_fire=ld_io_dma_req_valid && !stall;
assign busy=cv_io_busy || ws_io_busy || ld_io_busy || resp_valid || cv_ld || cv_st || cv_ex || ws_ld || ws_st || ws_ex;
assign in_ready=cv_io_in_ready;
always @(posedge clock)begin
 if(reset)begin
  rob_next<=0;resp_valid<=0;cv_ld<=0;cv_st<=0;cv_ex<=0;ws_ld<=0;ws_st<=0;ws_ex<=0;
  for(integer i=0;i<128;i=i+1)begin rob_cv[i]<=0;rob_ws[i]<=0;end
 end else begin
  resp_valid<=row_fire;
  if(row_fire)begin
   resp_id<=ld_io_dma_req_bits_cmd_id;
   resp_bytes<=ld_io_dma_req_bits_cols << (ld_io_dma_req_bits_has_acc_bitwidth?2:0);
  end
  cv_ld<=cmd_fire && cmd_conv && cfg_load;
  ws_ld<=cmd_fire && cmd_ws && cfg_load;
  cv_st<=cmd_fire && cmd_conv && !is_load && (store_cmd || cfg_store);
  ws_st<=cmd_fire && cmd_ws && !is_load && (store_cmd || cfg_store);
  cv_ex<=cmd_fire && cmd_conv && !is_load && !cfg_load && !store_cmd && !cfg_store;
  ws_ex<=cmd_fire && cmd_ws && !is_load && !cfg_load && !store_cmd && !cfg_store;
  if(cmd_fire && is_load)begin
   rob_cv[rob_next]<=cmd_conv;rob_ws[rob_next]<=cmd_ws;rob_next<=rob_next+1'b1;
  end
 end
end
'''
    for module, prefix in [('LoopConv', 'cv'), ('LoopMatmul', 'ws'), ('LoadController', 'ld')]:
        bindings = []
        for direction, width, name in ps[module]:
            value = "'0"
            if direction == 'output':
                value = prefix + '_' + name
            elif name in ('clock', 'reset'):
                value = name
            elif module == 'LoopConv' and name == 'io_in_valid':
                value = 'in_valid'
            elif name.startswith('io_in_bits_') or name.startswith('io_cmd_bits_'):
                field = name.split('_bits_', 1)[1]
                if module == 'LoopConv':
                    value = {'cmd_inst_funct': 'in_funct', 'cmd_rs1': 'in_rs1', 'cmd_rs2': 'in_rs2',
                             'cmd_inst_xs1': "1'b1", 'cmd_inst_xs2': "1'b1", 'cmd_inst_opcode': "7'h0b"}.get(field, "'0")
                    if field.endswith(('status_prv', 'status_dprv', 'status_mpp')):
                        value = "2'd3"
                elif module == 'LoopMatmul':
                    value = 'cv_io_out_bits_' + field
                elif field == 'rob_id_bits':
                    value = 'rob_next'
                else:
                    value = 'ws_io_out_bits_' + field
            elif module == 'LoopMatmul' and name == 'io_in_valid':
                value = 'cv_io_out_valid'
            elif name == 'io_out_ready':
                value = 'ws_io_in_ready' if module == 'LoopConv' else 'out_ready'
            elif name in ('io_ld_completed', 'io_st_completed', 'io_ex_completed'):
                kind = name[3:5]
                if kind == 'ld':
                    value = f'({{6\'d0,{prefix}_ld}} + {{6\'d0,{prefix}_ld_done}})'
                else:
                    value = f"{{6'd0,{prefix}_{kind}}}"
            elif module == 'LoadController':
                value = {'io_cmd_valid': 'ws_io_out_valid && to_ld && !stall', 'io_dma_req_ready': '!stall',
                         'io_completed_ready': "1'b1", 'io_dma_resp_valid': 'resp_valid',
                         'io_dma_resp_bits_cmd_id': 'resp_id', 'io_dma_resp_bits_bytesRead': 'resp_bytes'}.get(name, "'0")
            bindings.append(f'.{name}({value})')
        text += f'{module} {prefix}(' + ',\n'.join(bindings) + ');\n'
    for field in row_fields:
        text += f'assign row_{field}=ld_io_dma_req_bits_{field};\n'
    return text + 'endmodule\n'


def build(context, out):
    out.mkdir(parents=True, exist_ok=False)
    identity = json.loads(context.read_text())
    rtl = context.parent / 'gen-collateral'
    sources = closure(rtl, ('LoopConv', 'LoopMatmul', 'LoadController'))
    for path in sources:
        if hashlib.sha256(path.read_bytes()).hexdigest() != identity['final_rtl_sha256'][path.name]:
            raise ValueError('RTL hash mismatch: ' + str(path))
    top = out / 'CscCommandTrace.sv'
    top.write_text(wrapper(rtl))
    driver = FEATURE / 'tests/full_command_driver.cpp'
    prefix = Path(sys.executable).resolve().parents[1]
    cflags = '-O2 -std=c++17'
    ldflags = '-lz'
    if (prefix / 'include/zlib.h').is_file():
        cflags += ' -I' + str(prefix / 'include')
        ldflags = f'-L{prefix}/lib -Wl,-rpath,{prefix}/lib -lz'
    command = ['verilator', '--cc', '--exe', '--build', '--assert', '-Wno-fatal',
               '--top-module', 'CscCommandTrace', '--Mdir', str(out / 'obj'), '-j', '4',
               '-CFLAGS', cflags, '-LDFLAGS', ldflags, str(top), *map(str, sources), str(driver)]
    (out / 'compile_command.json').write_text(json.dumps(command, indent=2) + '\n')
    subprocess.run(command, check=True)
    manifest = dict(schema=1, status='COMMAND_ENUMERATOR_BUILT', build_id=identity['dma_load_build_id'],
                    backend='Synthetic one-cycle row byte credits; no SRAM/EX numeric execution',
                    full_gemmini_execution=False, performance_model=False,
                    sha256={str(p): hashlib.sha256(p.read_bytes()).hexdigest() for p in [context, top, driver, *sources]})
    (out / 'build_manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--context', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    build(args.context.resolve(), args.output.resolve())
