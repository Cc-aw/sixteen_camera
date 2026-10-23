#!/usr/bin/env python3
"""Compare pipelined RS against the imported RS at actual table allocations.

The reference decodes commands independently at allocation, with its own
configuration state. This checks metadata snapshots, live dependencies, issue
ordering and completion recycling across input/output stalls.
"""
import json
import gzip
import hashlib
import os
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'scripts'))
from common import selected_output, sha
from rtl_support import module_closure, ports


def renamed_closure(rtl, prefix, out):
    paths = module_closure(rtl, ['ReservationStation'])
    names = {n for path in paths for n in re.findall(r'^module\s+(\w+)', path.read_text(), re.M)}
    pattern = re.compile(r'\b(' + '|'.join(sorted(names, key=len, reverse=True)) + r')\b')
    source = '\n'.join(pattern.sub(lambda m: prefix + m[0], path.read_text()) for path in paths)
    path = out / (prefix + '.sv')
    path.write_text(source)
    return path


def main():
    generated, context = selected_output(Path(os.environ.get('S3_GENERATED_OUTPUT', str(ROOT / 'build/timing_generated_final'))))
    rtl = generated / 'gen-collateral'
    out = Path(os.environ.get('S3_RS_OUTPUT', str(ROOT / 'build/timing_s1_rs_reference'))).resolve()
    if ROOT / 'build' not in out.parents:
        raise ValueError('RS test output must stay inside this version build/')
    out.mkdir(parents=True, exist_ok=False)
    reference = out / 'reference'
    reference.mkdir()
    fixtures = ROOT / 'tests/timing/fixtures/rs_original'
    frozen = json.loads((fixtures / 'manifest.json').read_text())
    for name, item in frozen['files'].items():
        if Path(name).name != name or Path(item['file']).name != item['file']:
            raise ValueError('Unsafe RS reference fixture path')
        archive = fixtures / item['file']
        if sha(archive) != item['compressed_sha256']:
            raise ValueError('RS reference archive changed')
        data = gzip.decompress(archive.read_bytes())
        if len(data) != item['bytes'] or hashlib.sha256(data).hexdigest() != item['sha256']:
            raise ValueError('RS reference RTL changed')
        (reference / name).write_bytes(data)
    ps = ports(rtl / 'ReservationStation.sv')
    reference_ports = ports(reference / 'ReservationStation.sv')
    assert set(reference_ports) <= set(ps)
    decl, instances, checks = [], [], []
    for prefix in ('d', 'r'):
        bindings = []
        for direction, width, name in (ps if prefix == 'd' else reference_ports):
            if direction == 'output':
                decl.append(f'wire {width} {prefix}_{name};')
                value = f'{prefix}_{name}'
            elif name in ('clock', 'reset', 'io_completed_valid', 'io_completed_bits'):
                value = name
            elif name.startswith('io_issue_') and name.endswith('_ready'):
                value = f'ready_{name.split("_")[2]}'
            elif name == 'io_alloc_valid':
                value = 'src_valid' if prefix == 'd' else 'dut._alloc_metadata_io_deq_valid'
            elif name.startswith('io_alloc_bits_'):
                suffix = name.removeprefix('io_alloc_bits_')
                if prefix == 'r':
                    value = 'dut._alloc_metadata_io_deq_bits_cmd_' + suffix
                else:
                    value = dict(cmd_inst_funct='funct', cmd_rs1='rs1', cmd_rs2='rs2',
                                 from_conv_fsm='from_conv', from_matmul_fsm='from_matmul').get(suffix, "'0")
            else:
                value = "'0"
            bindings.append(f'.{name}({value})')
        instances.append(('Dut' if prefix == 'd' else 'Ref') + 'ReservationStation ' +
                         ('dut' if prefix == 'd' else 'ref_dut') + '(' + ','.join(bindings) + ');')
    for direction, _, name in ps:
        if direction != 'output':
            continue
        if name.startswith('io_issue_'):
            q = name.split('_')[2]
            guard = "1'b1" if name.endswith('_valid') else f'd_io_issue_{q}_valid'
        elif re.match(r'io_(conv|matmul)_(ld|ex|st)_completed$', name):
            guard = "1'b1"
        else:
            continue
        checks.append(f'if ({guard} && d_{name} !== r_{name}) $fatal(1,"RS reference mismatch: {name}, cycle=%0d",cycle);')
    issue_checks = []
    for q, index in (('ld', 0), ('ex', 1), ('st', 2)):
        issue_checks.append(f'''
        if (d_io_issue_{q}_valid && ready_{q}) begin
            issued_count = issued_count + 1;
            if (!((d_io_issue_{q}_cmd_cmd_inst_funct == 0 ||
                   d_io_issue_{q}_cmd_cmd_inst_funct == 26) && {index} != 1)) begin
                if (pending[d_io_issue_{q}_rob_id]) $fatal(1,"Duplicate live ROB id");
                pending[d_io_issue_{q}_rob_id] = 1;
                due[d_io_issue_{q}_rob_id] = cycle + 4 + $urandom_range(0, 50);
            end
        end''')
    body = '''`timescale 1ns/1ps
module tb_rs;
reg clock=0, reset=1;
always #5 clock=~clock;
reg src_valid=0, from_conv=0, from_matmul=0;
reg [6:0] funct=0;
reg [63:0] rs1=0,rs2=0;
reg ready_ld=0,ready_ex=0,ready_st=0;
reg io_completed_valid=0;
reg [6:0] io_completed_bits=0;
integer cycle=0, accepted=0, allocated=0, issued_count=0, blocked=0, completions=0;
bit pending[128];
integer due[128];
''' + '\n'.join(decl + instances) + '''
always @(negedge clock) begin
    if (!reset) begin
        ready_ld = cycle > 120 && (cycle % 13 < 8);
        ready_st = cycle > 160 && (cycle % 17 < 11);
        ready_ex = cycle > 200 && (cycle % 19 < 12);
        io_completed_valid=0;
        for (integer i=0;i<128;i=i+1) begin
            if (!io_completed_valid && pending[(i+cycle)%128] && due[(i+cycle)%128]<=cycle) begin
                io_completed_valid=1;
                io_completed_bits=7'((i+cycle)%128);
            end
        end
    end
end
always @(posedge clock) begin
    if (!reset) begin
        cycle=cycle+1;
        if (src_valid && d_io_alloc_ready) accepted=accepted+1;
        if (src_valid && !d_io_alloc_ready) blocked=blocked+1;
        if (dut._alloc_metadata_io_deq_valid) begin
            if (!d_io_busy) $fatal(1,"Busy dropped with buffered command");
            if (dut.alloc_metadata.io_deq_ready !== r_io_alloc_ready)
                $fatal(1,"RS allocation readiness differs");
            if (r_io_alloc_ready) allocated=allocated+1;
        end
''' + '\n'.join(checks) + '''
        if (io_completed_valid) begin
            if (!pending[io_completed_bits]) $fatal(1,"Completion without issue");
            pending[io_completed_bits]=0;
            completions=completions+1;
        end
''' + '\n'.join(issue_checks) + '''
    end
end
task automatic send(input [6:0] f,input [63:0] a,input [63:0] b,input integer n);
    @(negedge clock);
    src_valid=1;funct=f;rs1=a;rs2=b;
    from_conv=(n%3==1);from_matmul=(n%3==2);
    do @(posedge clock); while(!d_io_alloc_ready);
endtask
initial begin
    for(integer i=0;i<128;i=i+1) begin pending[i]=0;due[i]=0;end
    repeat(8) @(negedge clock);
    reset=0;
    // Repeated stride/transpose/pooling changes immediately followed by data
    // operations, including wraparound and overlapped local address ranges.
    for(integer n=0;n<1800;n=n+1) begin
        case(n%12)
          0: send(0,64'(1+(n%9))<<16 | 64'((n/12)%2)<<8,64'(1+n%5)<<48,n);
          1: send(0,64'(16+n%17)<<16 | 64'(1+n%4)<<8 | 1,0,n);
          2: send(2,64'h80000000+n*64,64'(2+n%31)<<48 | 64'(1+n%63)<<32 | 64'(n%2?16370:16),n);
          3: send(6,64'(8)<<48 | 64'(32)<<32 | 64'(n%256),64'(8)<<48 | 64'(32)<<32 | 64'h80000000,n);
          4: send(4,64'(8)<<48 | 64'(32)<<32 | 64'(n%256),64'(8)<<48 | 64'(32)<<32 | 64'(n%256+16),n);
          5: send(0,64'h22,0,n);
          6: send(3,64'h80001000+n*64,64'(4)<<48 | 64'(32)<<32 | 64'h80000000 | 64'(n%256),n);
          7: send(0,64'(32+n%16)<<16 | 64'(1+n%4)<<8 | 9,0,n);
          8: send(1,64'h80002000+n*64,64'(3)<<48 | 64'(63)<<32 | 64'(n%256),n);
          9: send(0,2,0,n);
         10: send(23,64'(n%256+8),64'(4)<<48 | 64'(32)<<32 | 64'(n%256),n);
         11: send(0,64'(32+n%16)<<16 | 64'(1)<<8 | 17,0,n);
        endcase
    end
    @(negedge clock);src_valid=0;
    wait (allocated==1800 && issued_count==1800 && completions>0 && !d_io_busy);
    repeat(10) @(negedge clock);
    if (accepted!=1800 || blocked==0) $fatal(1,"Missing acceptance/backpressure coverage");
    $display("RS_REFERENCE_PASS commands=%0d table_allocations=%0d issues=%0d completions=%0d blocked_cycles=%0d",accepted,allocated,issued_count,completions,blocked);
    $finish;
end
initial begin #10000000;$fatal(1,"RS reference timeout");end
endmodule
'''
    tb = out / 'tb_rs.sv'
    tb.write_text(body)
    files = [renamed_closure(rtl, 'Dut', out), renamed_closure(reference, 'Ref', out), tb]
    with (out / 'compile.log').open('w') as log:
        subprocess.run([os.environ.get('VERILATOR', 'verilator'),
            '--binary', '--timing', '--assert', '-Wno-fatal', '-j', '4', '--top-module', 'tb_rs',
            '--Mdir', str(out/'obj'), *map(str, files)], stdout=log, stderr=subprocess.STDOUT, check=True)
    result = subprocess.run([str(out/'obj/Vtb_rs')], capture_output=True, text=True)
    (out/'result.log').write_text(result.stdout+result.stderr)
    print(result.stdout+result.stderr, flush=True)
    result.check_returncode()
    assert 'RS_REFERENCE_PASS' in result.stdout
    (out/'evidence.json').write_text(json.dumps(dict(status='RS_REFERENCE_PASS',
        build_id=context['dma_load_build_id'], commands=1800, reference='IMPORTED_ORIGINAL_RS',
        allocation_alignment='CANDIDATE_METADATA_DEQUEUE',
        compared='ISSUE_COMMANDS_ROB_IDS_CREDITS_AND_ALLOCATION_READY',
        log_sha256=sha(out/'result.log')), indent=2)+'\n')


if __name__=='__main__':
    main()
