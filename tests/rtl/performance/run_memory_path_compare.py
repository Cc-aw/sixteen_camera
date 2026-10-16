#!/usr/bin/env python3
"""Compare actual L2 -> CacheCork -> MemoryBus/AXI -> Head -> checked DDR RTL.

One or two active cache banks, ordinary DDR reads, inactive PPU/local stores. This does
not execute an ELF or model the DDR controller/PHY or its register slice.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def ports(rtl, module):
    text = re.sub(r'//[^\n]*', '', (rtl / (module + '.sv')).read_text())
    header = re.search(r'\bmodule\s+' + module + r'\s*\((.*?)\);', text, re.S)[1]
    result = {}
    for field in header.split(','):
        match = re.fullmatch(r'\s*(input|output)\s*(\[\d+:\d+\])?\s*(\w+)\s*', field)
        assert match, field
        result[match[3]] = (match[1], match[2] or '')
    return result


def make_bench(rtl, base, decouple, banks=1, supports_h1=True):
    bank = ports(rtl, 'InclusiveCacheBankScheduler')
    cork = ports(rtl, 'TLCacheCork')
    bus = ports(rtl, 'MemoryBus')
    lines = ['`timescale 1ns/1ps', 'module tb_memory_path;',
             "logic clock=0, reset=1; always #5 clock=~clock;"]
    bits = int(re.search(r'\[(\d+):', bank['io_in_a_bits_source'][1])[1]) + 1
    lines += [f'localparam SOURCE_BITS={bits};']
    for name, (_, width) in bank.items():
        if name not in ('clock', 'reset'):
            lines += [f'logic {width} {name};']
            if banks == 2:
                lines += [f'logic {width} bank1_{name};']
                if name.startswith('io_in_'):
                    lines += [f'logic {width} bank0_{name};']
    for prefix, interface in [('ck', cork), ('mb', bus)]:
        for name, (_, width) in interface.items():
            if name not in ('clock', 'reset'):
                lines += [f'logic {width} {prefix}_{name};']
    connections = lambda names, prefix: ',\n'.join(
        f'.{name}({name if name in ("clock", "reset") else prefix+name})' for name in names)
    bank_connections = ',\n'.join(f'.{name}({"bank0_"+name if banks==2 and name.startswith("io_in_") else name})' for name in bank)
    lines += ['InclusiveCacheBankScheduler dut(' + bank_connections + ');',
              'TLCacheCork cork(' + connections(cork, 'ck_') + ');',
              'MemoryBus mbus(' + connections(bus, 'mb_') + ');']
    if banks == 2:
        lines += ['InclusiveCacheBankScheduler dut1(' + connections(bank, 'bank1_') + ');', '''
logic response_locked=0,response_owner=0,response_beat=0,response_prefer=0;
wire response_pick=response_locked ? response_owner :
    (response_prefer ? bank1_io_in_d_valid : !bank0_io_in_d_valid);
always @(posedge clock) begin
    if(reset) begin response_locked<=0;response_owner<=0;response_beat<=0;response_prefer<=0;end
    else if(io_in_d_valid) begin
        response_owner<=response_pick;
        if(io_in_d_ready && response_beat) begin
            response_locked<=0;response_beat<=0;response_prefer<=!response_pick;
        end else begin
            response_locked<=1;
            if(io_in_d_ready) response_beat<=1;
        end
    end
end
''']
        for name, (direction, _) in bank.items():
            if name in ('clock', 'reset') or name.startswith('io_out_'):
                continue
            if name.startswith('io_in_'):
                if direction == 'input':
                    for index in range(2):
                        value = name
                        if name == 'io_in_a_valid':
                            value += f' && (io_in_a_bits_address[12]==1\'b{index})'
                        elif name == 'io_in_d_ready':
                            value += f' && (response_pick==1\'b{index})'
                        lines += [f'assign bank{index}_{name}={value};']
                elif name == 'io_in_a_ready':
                    lines += [f'assign {name}=io_in_a_bits_address[12] ? bank1_{name} : bank0_{name};']
                elif name.startswith('io_in_d_'):
                    lines += [f'assign {name}=response_pick ? bank1_{name} : bank0_{name};']
                elif name == 'io_in_b_valid':
                    lines += [f'assign {name}=bank0_{name} || bank1_{name};']
                else:
                    lines += [f'assign {name}=bank0_{name};']
            elif direction == 'input':
                lines += [f'assign bank1_{name}={name};']
    initialized = [f"{name}='0;" for name, (direction, _) in bank.items()
                   if direction == 'input' and name not in ('clock', 'reset') and not name.startswith('io_out_')]
    lines += ['initial begin ' + ' '.join(initialized) + ' end']
    source = (base / 'tb_l2_performance.sv').read_text()
    eligible = re.search(r'wire bench_eligible = [^;]+;', source)[0]
    lines += [eligible]
    if banks == 2:
        lines += [eligible.replace('bench_eligible', 'bench_eligible1').replace('dut.', 'dut1.')]
    driven = set()
    # CacheCork contains the two actual production bank ports. Only bank 0
    # receives traffic in one-bank mode; both are connected in two-bank mode.
    for name, (direction, _) in cork.items():
        if name in ('clock', 'reset'):
            continue
        signal = 'ck_' + name
        match = re.fullmatch(r'auto_in_([01])_(.*)', name)
        if match:
            index, field = match.groups()
            raw_counterpart = 'io_out_' + field
            counterpart = ('' if index == '0' else 'bank1_') + raw_counterpart
            if (index == '0' or banks == 2) and raw_counterpart in bank:
                if direction == 'input':
                    # InclusiveCache's production wrapper restores A12 on
                    # bank-1 outer addresses; Scheduler itself clears it.
                    value = counterpart + (" | 33'h1000" if index == '1' and field in ('a_bits_address','c_bits_address') else '')
                    lines += [f'assign {signal}={value};']
                else:
                    lines += [f'assign {counterpart}={signal};']
                    driven.add(counterpart)
            elif direction == 'input':
                lines += [f"assign {signal}={'1' if field == 'd_ready' else '0'};"]
            continue
        match = re.fullmatch(r'auto_out_([01])_(.*)', name)
        assert match, name
        index, field = match.groups()
        counterpart = 'auto_bus_xing_in_' + index + '_' + field
        if counterpart in bus:
            if direction == 'input':
                lines += [f'assign {signal}=mb_{counterpart};']
            else:
                lines += [f'assign mb_{counterpart}={signal};']
        elif direction == 'input':
            lines += [f"assign {signal}='0;"]
    for index in range(banks):
        for name, (direction, _) in bank.items():
            signal = ('' if index == 0 else 'bank1_') + name
            if name.startswith('io_out_') and direction == 'input' and signal not in driven:
                lines += [f"assign {signal}={'1' if name.endswith('_ready') else '0'};"]
    lines += ['axi4_if #(.ADDR_WIDTH(33),.DATA_WIDTH(512),.ID_WIDTH(2)) axi();',
              'axi4_if #(.ADDR_WIDTH(33),.DATA_WIDTH(512),.ID_WIDTH(2)) memory();',
              'assign axi.aclk=clock; assign axi.aresetn=~reset;',
              'assign memory.aclk=clock; assign memory.aresetn=~reset;']
    axi_prefix = 'auto_coupler_to_memory_controller_port_named_axi4_axi4yank_out_'
    for name, (direction, _) in bus.items():
        signal = 'mb_' + name
        if name.startswith('auto_bus_xing_in_'):
            counterpart = re.sub(r'^auto_bus_xing_in_', 'auto_out_', name)
            if direction == 'input' and counterpart not in cork:
                lines += [f"assign {signal}='0;"]
        elif name.startswith(axi_prefix):
            field = name.removeprefix(axi_prefix).replace('_bits_', '').replace('_', '')
            lines += [f'assign {signal}=axi.{field};' if direction == 'input'
                      else f'assign axi.{field}={signal};']
        elif name.startswith('auto_buffer_out_'):
            if direction == 'input':
                lines += [f"assign {signal}={'1' if name.endswith('_a_ready') else '0'};"]
        elif direction == 'input' and name.endswith('_clock'):
            lines += [f'assign {signal}=clock;']
        elif direction == 'input' and name.endswith('_reset'):
            lines += [f'assign {signal}=reset;']
        elif direction == 'input':
            raise AssertionError('Unconnected MemoryBus input: ' + name)
    head_options = f'.READ_DECOUPLE({decouple}),.READ_ACCEPT_LIMIT(32),' if supports_h1 else ''
    assert supports_h1 or decouple == 0, 'S1 Head has no H1 mode'
    lines += [f'''axi4_head_uram_router_v3 #(.ADDR_WIDTH(33),.DATA_WIDTH(512),
        .LOCAL_DATA_WIDTH(256),.ID_WIDTH(2),.DDR_OUTSTANDING(32),
        {head_options}.SLOT_BYTES(512)) head(
        .clk(clock),.resetn(~reset),.s_axi(axi),.m_ddr_axi(memory),
        .local_read_bank(3'd0),.local_read_req_valid(1'b0),
        .local_read_req_ready(),.local_read_req_word_addr(4'd0),
        .local_read_rsp_data(),.local_read_rsp_valid(),.local_read_rsp_ready(1'b1),.perf_events());''']
    workload = (HERE / 'l2_workload.svh').read_text()
    first = workload.index('            if(io_out_a_valid && io_out_a_ready)')
    last = workload.index('            if(io_in_b_valid)', first)
    workload = workload[:first] + workload[last:]
    if banks == 2:
        function = re.search(r'    function automatic \[32:0\] address_for\(.*?endfunction', workload, re.S)[0]
        replacement = re.sub(r'\bn\b', 'm', function).replace('input integer m', 'input integer n')
        replacement = replacement.replace(');\n', ');\n        integer m;\n        begin\n        m=n/2;\n', 1)
        replacement = replacement.replace('endfunction', "address_for=address_for+33'((n%2)*4096);\n        end\n    endfunction")
        workload = workload.replace(function, replacement)
        workload = workload.replace('n<64;n++) request', 'n<128;n++) request')
        workload = workload.replace('if(|dut.mshr_selectOH) schedule_count++;',
            'if(|dut.mshr_selectOH) schedule_count++; if(|dut1.mshr_selectOH) schedule_count++;')
        workload = workload.replace('if(bench_eligible && !(|dut.mshr_selectOH)) eligible_bubbles++;',
            'if(bench_eligible && !(|dut.mshr_selectOH)) eligible_bubbles++; if(bench_eligible1 && !(|dut1.mshr_selectOH)) eligible_bubbles++;')
        workload = workload.replace('$countones(dut.requests.used)',
            '($countones(dut.requests.used)+$countones(dut1.requests.used))')
    first = workload.index('            io_out_a_ready=')
    last = workload.index('\n        end\n    end\n    task automatic request', first)
    workload = workload[:first] + workload[last:]
    endpoint = '''
            if(memory.awvalid || memory.wvalid) $fatal(1,"Unexpected write in read-only test");
            if(mb_auto_buffer_out_a_valid) $fatal(1,"Unexpected non-DDR address");
            if(memory.arvalid && memory.arready) begin
                if(memory.arlen!=0 || memory.arsize!=6) $fatal(1,"Unexpected AXI read shape");
                return_source[qwrite%4096]=memory.arid;
                return_address[qwrite%4096]=memory.araddr;
                return_cycle[qwrite%4096]=cycle+memory_delay;
                qwrite++;outer_sent++;
                id_mask |= 1<<memory.arid;id_live[memory.arid]++;
            end
            if(memory.rvalid && memory.rready) begin
                id_live[memory.rid]--;qread++;outer_done++;
            end
            for(integer i=0;i<4;i++) begin
                if(id_live[i]<0) $fatal(1,"Unexpected AXI response ID");
                if(id_live[i]>id_peak[i]) id_peak[i]=id_live[i];
            end
            if(qwrite-qread>memory_peak) memory_peak=qwrite-qread;
'''
    workload = workload.replace('            if(io_in_b_valid)', endpoint+'            if(io_in_b_valid)', 1)
    lines += ['integer id_peak[4], id_live[4]; integer id_mask=0, memory_peak=0;',
              'initial for(integer i=0;i<4;i++) begin id_peak[i]=0;id_live[i]=0;end',
              workload, '''
    assign memory.awready=1; assign memory.wready=1;
    assign memory.bid=0; assign memory.bresp=0; assign memory.bvalid=0;
    assign memory.arready=!random_stalls || rng[1] || rng[6];
    assign memory.rresp=0; assign memory.rlast=1;
    initial begin memory.rvalid=0;memory.rid=0;memory.rdata=0;end
    always @(negedge clock) begin
        memory.rvalid=!reset && qwrite>qread && cycle>=return_cycle[qread%4096];
        memory.rid=2'(return_source[qread%4096]);
        memory.rdata=line_data(return_address[qread%4096]);
    end
    final $display("MEMORY_PATH_AXI ids=%h peak=%0d per_id=%0d,%0d,%0d,%0d",id_mask,
        memory_peak,id_peak[0],id_peak[1],id_peak[2],id_peak[3]);
endmodule
''']
    return '\n'.join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--base', type=Path, required=True, help='Checked isolated-L2 comparison directory')
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--read-decouple', type=int, choices=(0, 1), required=True)
    parser.add_argument('--banks', type=int, choices=(1, 2), default=1)
    parser.add_argument('--router', type=Path, default=ROOT / 'hw/rtl/ai/postprocess/axi4_head_uram_router_v3.sv')
    parser.add_argument('--count', type=int, default=512)
    parser.add_argument('--extra-seeds', type=int, nargs='+', default=[],
                        help='Add delay-64 stalled windows 24/96; save a separate extended result')
    parser.add_argument('--verilator', default=os.environ.get('HEAD_VERILATOR', shutil.which('verilator') or 'verilator'))
    parser.add_argument('--reuse', action='store_true')
    args = parser.parse_args()
    base = args.base.resolve()
    data = json.loads((base / f'results_count{args.count}.json').read_text())
    rtl = Path(data['rtl'])
    expected = json.loads((base / 'compiled_sources.json').read_text())['rtl_sha256']
    supports_h1 = bool(re.search(r'parameter\s+bit\s+READ_DECOUPLE', args.router.read_text()))
    text = make_bench(rtl, base, args.read_decouple, args.banks, supports_h1)
    out = args.output.resolve();out.mkdir(parents=True, exist_ok=True)
    bench = out / 'tb_memory_path.sv';bench.write_text(text)
    mems = list(rtl.glob('*.top.mems.v'))
    module_files = {}
    for path in mems:
        for module in re.findall(r'^module\s+(\w+)', path.read_text(), re.M):
            module_files[module] = path
    sources = set()
    def visit(module):
        path = next((rtl / (module + suffix) for suffix in ('.sv', '.v') if (rtl / (module + suffix)).exists()), module_files.get(module))
        if path is None or path in sources:
            return
        sources.add(path)
        assert sha(path) == expected[path.name], 'Changed checked input: ' + path.name
        for child in re.findall(r'^\s+(\w+)\s+(?:#\s*\(.*?\)\s*)?\w+\s*\(', path.read_text(), re.M):
            visit(child)
    for module in ('InclusiveCacheBankScheduler', 'TLCacheCork', 'MemoryBus'):
        visit(module)
    support = [ROOT / 'hw/rtl/interfaces/axi4_if.sv', ROOT / 'hw/rtl/ai/postprocess/head_uram_store.sv', args.router.resolve()]
    identity = dict(rtl_sha256={p.name:sha(p) for p in sorted(sources)},
                    support_sha256={str(p):sha(p) for p in support},
                    bench_sha256=hashlib.sha256(text.encode()).hexdigest(), read_decouple=args.read_decouple)
    manifest = out / 'compiled_sources.json'
    if args.reuse:
        assert json.loads(manifest.read_text()) == identity, 'Changed integrated simulation inputs'
    else:
        manifest.unlink(missing_ok=True)
        frozen = out / 'rtl'
        frozen.mkdir(exist_ok=True)
        compile_sources = []
        snapshot = []
        for path in [*support, *sorted(sources)]:
            destination = frozen / path.name
            shutil.copyfile(path, destination)
            digest = sha(destination)
            expected_digest = identity['rtl_sha256'].get(path.name, identity['support_sha256'].get(str(path)))
            assert digest == expected_digest, 'Input changed while freezing: ' + str(path)
            compile_sources.append(str(destination))
            snapshot.append(dict(source=str(path), snapshot=str(destination), sha256=digest))
        with (out / 'compile.log').open('w') as log:
            subprocess.run([args.verilator,'--binary','--timing','--assert','-Wno-fatal','-j','4',
                            '--top-module','tb_memory_path','--Mdir',str(out/'obj'),
                            *compile_sources,str(bench)],
                           stdout=log,stderr=subprocess.STDOUT,check=True)
        (out / 'source_snapshot.json').write_text(json.dumps(snapshot, indent=2)+'\n')
        manifest.write_text(json.dumps(identity, indent=2)+'\n')
    rows=[]
    configurations={(x['window'],x['delay'],x['stalls'],x['seed']) for x in data['results']}
    if args.banks == 2:
        # Exercise the shared Head credit ceiling with both banks active and
        # no artificial response stalls; a single bank can hide this limit.
        configurations |= {(96, delay, 0, 151034) for delay in (64,128)}
    configurations |= {(window,64,1,seed) for window in (24,96) for seed in args.extra_seeds}
    for window, delay, stalls, seed in sorted(configurations):
        command=[str(out/'obj/Vtb_memory_path'),f'+WINDOW={window}',f'+DELAY={delay}',
                 f'+COUNT={args.count}',f'+SEED={seed}']+(['+STALLS'] if stalls else [])
        result=subprocess.run(command,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True)
        log=out/f'count{args.count}_window{window}_delay{delay}_stalls{stalls}_seed{seed}.log';log.write_text(result.stdout)
        assert result.returncode==0 and 'L2_PERF_SCOREBOARD=PASS' in result.stdout,str(log)
        for line in result.stdout.splitlines():
            if line.startswith('L2_PERF '):rows.append({k:int(v) for k,v in re.findall(r'(\w+)=(\d+)',line)})
    report=dict(results=rows,read_decouple=args.read_decouple,active_banks=args.banks,binary_sha256=sha(out/'obj/Vtb_memory_path'),
                compiled_sources_sha256=sha(manifest),workload_sha256=sha(HERE/'l2_workload.svh'),
                endpoint_generator_sha256=sha(Path(__file__)),bench_sha256=identity['bench_sha256'],
                scope=__doc__,DDR_PHY_AND_REGISTER_SLICE='NOT_MODELED',BOARD_SPEEDUP='NOT_CLAIMED')
    suffix = '_extended' if args.extra_seeds else ''
    (out/f'results_count{args.count}{suffix}.json').write_text(json.dumps(report,indent=2)+'\n')
    print(f'MEMORY_PATH_SCOREBOARD=PASS scenarios={len(rows)} count={args.count} output={out}')


if __name__ == '__main__':
    main()
