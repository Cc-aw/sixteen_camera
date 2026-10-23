#!/usr/bin/env python3
"""Check production SourceC + BankedStore eviction/refill ordering and data.

The scoreboard uses externally written victim bytes, not SourceC internal state.
Concurrent SinkD refills and higher priority SinkC reservations exercise the
noop's actual arbitration effect in the generated BankedStore.
"""
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
    generated, context = selected_output(Path(os.environ.get('S3_GENERATED_OUTPUT', str(ROOT / 'build/timing_generated_final'))))
    rtl = generated / 'gen-collateral'
    out = ROOT / 'build/s2_sourcec_bankedstore'
    out.mkdir(parents=True, exist_ok=True)
    decl, binding = [], []
    for direction, width, name in ports(rtl / 'SourceC.sv'):
        decl.append(f'{"reg" if direction == "input" else "wire"} {width} {name}' +
                    (' = 0;' if direction == 'input' else ';'))
        binding.append(f'.{name}({name})')
    assert 'io_bs_adr_bits_noop' in '\n'.join(decl), 'missing production noop port'
    instances = ['SourceC dut(' + ','.join(binding) + ');']
    binding = []
    for direction, width, name in ports(rtl / 'BankedStore.sv'):
        value = name
        if name == 'clock':
            pass
        elif name.startswith('io_sourceC_adr_'):
            value = name.replace('io_sourceC_adr_', 'io_bs_adr_')
        elif name == 'io_sourceC_dat_data':
            value = 'io_bs_dat_data'
        else:
            decl.append(f'{"reg" if direction == "input" else "wire"} {width} {name}' +
                        (' = 0;' if direction == 'input' else ';'))
        binding.append(f'.{name}({value})')
    instances.append('BankedStore store(' + ','.join(binding) + ');')
    # Store drives this input to SourceC, not the testbench.
    decl = [x.replace('reg [511:0]  io_bs_dat_data = 0;', 'wire [511:0] io_bs_dat_data;') for x in decl]
    decl = [('wire [511:0] io_bs_dat_data;' if ' io_bs_dat_data ' in x else x) for x in decl]
    body = r'''
always #5 clock = ~clock;
integer replies=0, reads=0, reservations=0, blocked_refills=0, blocked_sourcec=0, hazards=0;
integer expected_source=0, expected_opcode=0;
reg [32:0] expected_address=0;
reg [511:0] expected_data=0;
reg expected_dirty=0;
reg waiting=0;
always @(posedge clock) if(!reset) begin
  if(io_bs_adr_valid && io_bs_adr_bits_noop) begin
    reservations=reservations+1;
    if(io_sinkD_adr_valid && io_sinkD_adr_ready) $fatal(1,"refill passed eviction reservation");
  end
  if(io_bs_adr_valid && !io_bs_adr_ready) blocked_sourcec=blocked_sourcec+1;
  if(io_sinkD_adr_valid && !io_sinkD_adr_ready) blocked_refills=blocked_refills+1;
  if(!io_evict_safe && waiting) hazards=hazards+1;
  if(io_bs_adr_valid && io_bs_adr_ready && !io_bs_adr_bits_noop) reads=reads+1;
  if(io_c_valid && io_c_ready) begin
    if(!waiting) $fatal(1,"unexpected or duplicate C response");
    if(io_c_bits_source!==5'(expected_source) || io_c_bits_opcode!==3'(expected_opcode) ||
       io_c_bits_address!==expected_address || io_c_bits_size!==6 || io_c_bits_corrupt!==0)
      $fatal(1,"C metadata mismatch");
    if(expected_dirty && io_c_bits_data!==expected_data) $fatal(1,"victim overwritten or wrong SRAM data");
    waiting=0;replies=replies+1;
  end
end
task automatic tick; @(posedge clock); @(negedge clock); endtask
initial begin
  reset=1; repeat(6) tick(); reset=0;
  io_bs_adr_ready=0; // driven by store below, removed by generator
  io_sinkD_adr_bits_noop=0;io_sinkC_adr_bits_noop=1;
  io_sinkC_adr_bits_mask=15;
  for(integer n=0;n<240;n=n+1) begin
    // Each transaction uses a new victim, initialized by the real write port.
    io_sinkD_adr_bits_set=9'(n);io_sinkD_adr_bits_way=3'(n%8);
    for(integer b=0;b<64;b=b+1) expected_data[b*8+:8]=8'(n*13+b*7);
    io_sinkD_dat_data=expected_data;io_sinkD_adr_valid=1;
    do tick(); while(!io_sinkD_adr_ready);
    io_sinkD_adr_valid=0;
    expected_dirty=(n%3!=0);expected_opcode=expected_dirty?7:6;
    // Physical L2 bank select is address bit 12 (kept zero in bank 0).
    expected_source=n%32;expected_address=(33'(n+17)<<16) | (33'(n/64)<<13) | (33'(n%64)<<6);
    io_req_bits_set=9'(n);io_req_bits_way=3'(n%8);io_req_bits_tag=17'(n+17);
    io_req_bits_dirty=expected_dirty;io_req_bits_opcode=3'(expected_opcode);
    io_req_bits_source=5'(expected_source);io_req_valid=1;io_c_ready=0;
    io_evict_safe=(n%4!=1);
    waiting=1;
    // Hold a higher-priority bank reservation during the first few cycles.
    io_sinkC_adr_bits_set=9'(n);io_sinkC_adr_bits_way=3'(n%8);
    io_sinkC_adr_valid=(n%5==2 && expected_dirty);
    io_sinkD_dat_data=~expected_data;
    io_sinkD_adr_valid=expected_dirty && io_evict_safe;
    #1;
    if(n>0 && (io_evict_req_set!==9'(n-1) || io_evict_req_way!==3'((n-1)%8)))
      $fatal(1,"new request leaked through the registered hazard address");
    @(posedge clock);while(!io_req_ready) @(posedge clock);
    @(negedge clock);io_req_valid=0;
    // On accepted dirty requests, try to overwrite the victim immediately.
    // Unsafe cases wait for the hazard to drain as required by the MSHR plan.
    for(integer k=0;k<40;k=k+1) begin
      if(k==4) io_sinkC_adr_valid=0;
      if(k==6) io_evict_safe=1;
      if(k==12) io_c_ready=1;
      @(posedge clock);
      if(io_sinkD_adr_valid && io_sinkD_adr_ready) begin
        @(negedge clock);io_sinkD_adr_valid=0;
      end else @(negedge clock);
    end
    if(waiting || replies!=n+1) $fatal(1,"lost or stalled eviction");
  end
  if(reads!=160 || reservations!=160 || blocked_refills==0 || blocked_sourcec==0 || hazards==0)
    $fatal(1,"missing eviction/refill/hazard/backpressure coverage");
  $display("SOURCEC_BANKEDSTORE_PASS replies=%0d dirty_reads=%0d reservations=%0d blocked_refills=%0d blocked_sourcec=%0d hazards=%0d",replies,reads,reservations,blocked_refills,blocked_sourcec,hazards);
  $finish;
end
initial begin #1000000;$fatal(1,"SourceC timeout");end
'''
    # Handshake and SRAM data are driven by the real BankedStore outputs.
    decl = [x.replace('reg  io_bs_adr_ready = 0;', 'wire io_bs_adr_ready;') for x in decl]
    decl = [('wire io_bs_adr_ready;' if ' io_bs_adr_ready ' in x else x) for x in decl]
    body = body.replace('  io_bs_adr_ready=0; // driven by store below, removed by generator\n', '')
    tb = out / 'tb.sv'
    tb.write_text('`timescale 1ns/1ps\nmodule tb;\n' + '\n'.join(decl + instances) + body + '\nendmodule\n')
    files = module_closure(rtl, ['SourceC', 'BankedStore']) + [tb]
    command = [os.environ.get('VERILATOR', 'verilator'),
               '--binary', '--timing', '--assert', '-Wno-fatal', '-j', '4',
               '--top-module', 'tb', '--Mdir', str(out / 'obj'), *map(str, files)]
    with (out / 'compile.log').open('w') as log:
        subprocess.run(command, stdout=log, stderr=subprocess.STDOUT, check=True)
    result = subprocess.run([str(out / 'obj/Vtb')], capture_output=True, text=True, timeout=120)
    (out / 'result.log').write_text(result.stdout + result.stderr)
    assert result.returncode == 0 and 'SOURCEC_BANKEDSTORE_PASS' in result.stdout, result.stdout
    (out / 'evidence.json').write_text(json.dumps(dict(status='SOURCEC_BANKEDSTORE_PASS',
        build_id=context['dma_load_build_id'], replies=240, dirty_reads=160,
        sources={str(p.relative_to(ROOT)):sha(p) for p in files}), indent=2) + '\n')
    print(result.stdout)


if __name__ == '__main__':
    main()
