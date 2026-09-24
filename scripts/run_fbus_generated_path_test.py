#!/usr/bin/env python3
"""Simulate the actual generated FBus coupling and its dependency closure."""
import argparse
import os
from pathlib import Path
import re
import subprocess
import tempfile

repo = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--collateral', type=Path, default=next((repo / 'generated/soc').glob('tsmc*/gen-collateral')))
parser.add_argument('--bytes', type=int, default=32768)
parser.add_argument('--base-address', type=lambda value: int(value, 0),
                    default=0x0b2000000)
parser.add_argument('--short-only', action='store_true')
parser.add_argument('--min-mbps', type=int, default=0)
parser.add_argument('--slots', type=int, choices=[2, 4, 8, 16, 32, 64, 128], default=64)
parser.add_argument('--read-ids', type=int, choices=[2, 4, 8, 16, 31])
parser.add_argument('--burst', type=int, choices=[2, 4, 8, 16, 32, 64, 128])
parser.add_argument('--latency', type=int, default=48)
parser.add_argument('--memory-gap', type=int, default=0)
parser.add_argument('--consumer-period', type=int, default=1)
parser.add_argument('--contention-period', type=int, default=0)
parser.add_argument('--shared-write-id', action='store_true')
parser.add_argument('--write-traffic', action='store_true')
parser.add_argument('--write-only', action='store_true')
parser.add_argument('--write-count', type=int, default=64)
parser.add_argument('--fair-memory', action='store_true')
parser.add_argument('--require-eight', action='store_true',
                    help='require peak_TL_requests >= 8 for this explicit gate test')
parser.add_argument('--baseline', action='store_true',
                    help='deprecated compatibility option; parameter scans are ungated by default')
args = parser.parse_args()
top = 'TLInterconnectCoupler_fbus_from_port_named_slave_port_axi4'
seen = set()
def dependencies(name):
    if name in seen:
        return
    path = args.collateral / (name + '.sv')
    if not path.exists():
        raise SystemExit(f'Missing generated module {name}')
    seen.add(name)
    for child in re.findall(r'^  (\w+) \w+ \(', path.read_text(), re.M):
        dependencies(child)
dependencies(top)
coupler_text = (args.collateral / (top+'.sv')).read_text()
width_match = re.search(r'input\s+\[(\d+):0\]\s+auto_tl_out_d_bits_data', coupler_text)
if not width_match:
    raise SystemExit('Missing generated FBus response width')
memory_width = int(width_match[1]) + 1
id_match = re.search(r'input\s+\[(\d+):0\]\s+auto_axi4index_in_ar_bits_id', coupler_text)
if not id_match:
    raise SystemExit('Missing generated FBus AXI ID width')
axi_id_width = int(id_match[1]) + 1
# I: Optional sweep overrides and the generated bridge AXI ID width.
# P: Select a legal reader concurrency point without changing production RTL.
# O: A parameterized generated-path executable for one burst/ID/slot case.
# A: hlk
# T: 2026-09-21 12:26:37 CST
read_id_count = args.read_ids or ((1 << axi_id_width) - (0 if args.shared_write_id else 1))
max_read_ids = (1 << axi_id_width) - (0 if args.shared_write_id else 1)
if read_id_count > max_read_ids:
    raise SystemExit(f'--read-ids={read_id_count} exceeds available IDs={max_read_ids}')
write_id = 0 if args.shared_write_id else (1 << axi_id_width)-1
write_traffic = args.write_traffic or args.write_only
print(f"FBUS_TEST_CONFIG fbus_bits={memory_width} axi_id_bits={axi_id_width} "
      f"read_ids={read_id_count} slots={args.slots} bytes={args.bytes} "
      f"base=0x{args.base_address:x} "
      f"burst={args.burst or 'legacy'} "
      f"latency={args.latency} memory_gap={args.memory_gap} "
      f"fair_memory={args.fair_memory} writes={write_traffic} "
      f"write_only={args.write_only} write_count={args.write_count} "
      f"consumer_period={args.consumer_period} min_MBps={args.min_mbps}", flush=True)
connections = []
tl = {'a_ready':'a_ready', 'a_valid':'a_valid', 'a_bits_opcode':'a_opcode',
      'a_bits_size':'a_size', 'a_bits_source':'a_source', 'a_bits_address':'a_address',
      'd_ready':'d_ready', 'd_valid':'d_valid', 'd_bits_opcode':'d_opcode',
      'd_bits_param':"2'd0", 'd_bits_size':'d_size', 'd_bits_source':'d_source',
      'd_bits_sink':"5'd0", 'd_bits_denied':"1'b0", 'd_bits_data':'d_data',
      'd_bits_corrupt':"1'b0"}
for direction, name in re.findall(r'^\s*(input|output)\s+(?:\[[^]]+\]\s+)?(\w+)\s*[,\t]', (args.collateral / (top+'.sv')).read_text(), re.M):
    if name == 'clock': value = 'clk'
    elif name == 'reset': value = '!resetn'
    elif name.startswith('auto_axi4index_in_'):
        value = 'axi.' + name.removeprefix('auto_axi4index_in_').replace('_bits_', '').replace('_', '')
    elif name.startswith('auto_tl_out_'):
        key = name.removeprefix('auto_tl_out_')
        value = tl.get(key, '' if direction == 'output' else "'0")
    else: raise SystemExit(f'Unexpected port {name}')
    connections.append(f'.{name}({value})')
wrapper = '''module fbus_generated_wrapper(
input wire clk, resetn, axi4_if.slave axi,
input wire a_ready, output wire a_valid,
output wire [2:0] a_opcode, output wire [3:0] a_size,
output wire [6:0] a_source, output wire [32:0] a_address,
output wire d_ready, input wire d_valid, input wire [2:0] d_opcode,
input wire [3:0] d_size, input wire [6:0] d_source,
input wire [MEMORY_MSB:0] d_data);
''' + top + ' dut(\n' + ',\n'.join(connections) + '\n);\nendmodule\n'
wrapper = wrapper.replace('MEMORY_MSB', str(memory_width-1))
with tempfile.TemporaryDirectory(prefix='fbus-generated-') as directory:
    temp = Path(directory)
    (temp/'wrapper.sv').write_text(wrapper)
    verilator = os.environ.get('VERILATOR', 'verilator')
    cmd = [verilator, '--binary', '--timing', '--assert', '-O0', '-Wno-fatal',
           '--top-module', 'tb_fbus_generated_path', f'-GREADER_SLOTS={args.slots}', f'-GBYTES={args.bytes}', f"-GBASE_ADDR=33'h{args.base_address:09x}", f"-GSHORT_ONLY=1'b{int(args.short_only)}", f'-GMIN_MBPS={args.min_mbps}', f"-GFAIR_MEMORY=1'b{int(args.fair_memory)}", f"-GWRITE_TRAFFIC=1'b{int(write_traffic)}", f"-GWRITE_ONLY=1'b{int(args.write_only)}", f'-GWRITE_COUNT={args.write_count}', f'-GAXI_ID_WIDTH={axi_id_width}', f'-GREAD_ID_COUNT={read_id_count}', f'-GWRITE_ID={write_id}',
           f'-GMEMORY_LATENCY={args.latency}', f'-GMEMORY_GAP_CYCLES={args.memory_gap}', f'-GMEMORY_DATA_WIDTH={memory_width}', f'-GCONTENTION_PERIOD={args.contention_period}', f'-GCONSUMER_PERIOD={args.consumer_period}', '--Mdir', str(temp/'obj'), '-j', '4',
           str(repo/'rtl/interfaces/axi4_if.sv'), str(repo/'rtl/bus/axi4_channel_join.sv'), str(repo/'rtl/ai/postprocess/fbus_read_engine.sv'),
           *[str(args.collateral/(name+'.sv')) for name in sorted(seen)],
           str(temp/'wrapper.sv'), str(repo/'sim/tb_fbus_generated_path.sv')]
    if args.burst:
        cmd.insert(6, f'-GBURST_BEATS={args.burst}')
    subprocess.run(cmd, check=True)
    # The eight-request assertion is an explicit stress-test contract.  Parameter
    # scans must report the measured peak instead of inheriting this gate.
    require_eight = args.require_eight and not args.write_only
    subprocess.run([str(temp/'obj/Vtb_fbus_generated_path')] +
                   (['+require_eight'] if require_eight else []), check=True)
