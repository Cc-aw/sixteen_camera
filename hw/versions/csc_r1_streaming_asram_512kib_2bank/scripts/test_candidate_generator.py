#!/usr/bin/env python3
"""Check the actual Input generator's config-preserving replacement path."""
import argparse
import json
from pathlib import Path
import subprocess

from candidate_rtl import sha
from full_command_rtl import closure, ports


def run(context, output):
    identity = json.loads(context.read_text())
    rtl = context.parent / 'gen-collateral'
    sources = closure(rtl, ('LoopConvLdInput',))
    for path in sources:
        if sha(path) != identity['final_rtl_sha256'][path.name]:
            raise ValueError('Input generator snapshot changed')
    output.mkdir(parents=True, exist_ok=False)
    ps = ports(rtl / 'LoopConvLdInput.sv')
    defaults = dict(clock=0, reset=1, csc_skip=0, io_cmd_ready=1,
                    io_req_bits_outer_bounds_batch_size=1, io_req_bits_outer_bounds_in_row_dim=3,
                    io_req_bits_outer_bounds_in_col_dim=5, io_req_bits_outer_bounds_in_stride=13,
                    io_req_bits_inner_bounds_batches=1, io_req_bits_derived_params_irows=3,
                    io_req_bits_derived_params_icols=5, io_req_bits_derived_params_irows_unpadded=3,
                    io_req_bits_derived_params_icols_unpadded=5, io_req_bits_derived_params_ichs=13,
                    io_req_bits_derived_params_input_spad_stride=15, io_req_bits_max_pixels_per_row=1,
                    io_req_bits_dram_addr=0x20001000)
    lines = ['`timescale 1ns/1ps', 'module tb_csc_generator;']
    for direction, width, name in ps:
        lines.append(f'{"reg" if direction=="input" else "wire"} {width} {name}' +
                     (f' = {defaults.get(name, 0)};' if direction=='input' else ';'))
    lines += ['LoopConvLdInput dut(' + ','.join(f'.{name}({name})' for _, _, name in ps) + ');', '''
always #5 clock=~clock;
integer configs=0,loads=0,cycles=0;
reg [63:0] config_a,config_b;
reg checking=0,held=0;
reg [6:0] held_f;
reg [63:0] held_a,held_b;
always @(posedge clock) begin
  if(!reset)begin
    cycles=cycles+1;
    if(held && (!io_cmd_valid || io_cmd_bits_inst_funct!=held_f ||
       io_cmd_bits_rs1!=held_a || io_cmd_bits_rs2!=held_b)) $fatal(1,"command changed while stalled");
    held=io_cmd_valid&&!io_cmd_ready;
    held_f=io_cmd_bits_inst_funct; held_a=io_cmd_bits_rs1; held_b=io_cmd_bits_rs2;
    if(io_cmd_valid&&io_cmd_ready)begin
      if(io_cmd_bits_inst_funct==0)begin
        configs=configs+1;
        if(checking && (config_a!=io_cmd_bits_rs1 || config_b!=io_cmd_bits_rs2))
          $fatal(1,"replacement changed Input configuration");
        config_a=io_cmd_bits_rs1; config_b=io_cmd_bits_rs2;
      end else if(io_cmd_bits_inst_funct==2)loads=loads+1;
      else $fatal(1,"unexpected generated command");
    end
  end
end
task tick;
  begin @(negedge clock); #1; io_cmd_ready=(cycles%3)!=0; @(posedge clock); #1; end
endtask
task request(input reg skip, input reg [39:0] source);
  integer timeout;
  begin
    @(negedge clock); #1; csc_skip=skip; io_req_bits_dram_addr=source; io_req_valid=1;
    timeout=0;
    while(!io_req_ready)begin tick; timeout=timeout+1; if(timeout>1000)$fatal(1,"request deadlock");end
    @(posedge clock); #1; @(negedge clock); #1; io_req_valid=0;
    timeout=0;
    while(!io_idle)begin tick; timeout=timeout+1; if(timeout>1000)$fatal(1,"completion deadlock");end
  end
endtask
initial begin
  repeat(4)tick; @(negedge clock); #1; reset=0;
  request(0,40'h20001000);
  if(configs!=1||loads!=3)$fatal(1,"baseline generator mismatch configs=%0d loads=%0d",configs,loads);
  configs=0;loads=0;checking=1;
  request(1,40'h20001000);
  if(configs!=1||loads!=0)$fatal(1,"skip must retain config and omit every Mvin");
  configs=0;loads=0;
  request(0,40'h0);
  if(configs!=0||loads!=0)$fatal(1,"native null Input behavior changed");
  $display("CSC_INPUT_GENERATOR_PASS baseline_mvin=3 skip_mvin=0 preserved_config=1 native_null_unchanged=1");
  $finish;
end
initial begin #100000; $fatal(1,"generator timeout"); end
endmodule
''']
    top=output/'tb_csc_generator.sv'
    top.write_text('\n'.join(lines))
    executable=output/'generator.vvp'
    command=['iverilog','-g2012','-s','tb_csc_generator','-o',str(executable),str(top),*map(str,sources)]
    subprocess.run(command,check=True)
    result=subprocess.run(['vvp',str(executable)],capture_output=True,text=True)
    (output/'simulation.log').write_text(result.stdout+result.stderr)
    passed=result.returncode==0 and 'CSC_INPUT_GENERATOR_PASS' in result.stdout
    (output/'result.json').write_text(json.dumps(dict(schema=1,status='PASS' if passed else 'FAIL',
        returncode=result.returncode,compile_command=command,
        sha256={str(p):sha(p) for p in [context,Path(__file__).resolve(),top,*sources]}),indent=2)+'\n')
    if not passed: raise RuntimeError('Generator replacement failed: '+result.stdout+result.stderr)
    print(result.stdout.strip())


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--context',type=Path,required=True)
    parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args()
    run(args.context.resolve(),args.output.resolve())
