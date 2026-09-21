#!/usr/bin/env python3
"""Run one parameterized reader-only bandwidth and correctness case."""

# I: Command-line bandwidth model settings and an explicit Verilator executable.
# P: Build in a unique temporary directory and parameterize the reader-only TB.
# O: Reproducible reader counters with no generated-bridge behavior mixed in.
# A: hlk
# T: 2026-09-21 12:36:00 CST
import argparse
import os
from pathlib import Path
import subprocess
import tempfile

repo = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--bytes', type=int, default=65536)
parser.add_argument('--slots', type=int, choices=[2, 4, 8, 16, 32, 64, 128],
                    default=64)
parser.add_argument('--read-ids', type=int, choices=[2, 4, 8, 16, 31],
                    default=31)
parser.add_argument('--burst', type=int,
                    choices=[2, 4, 8, 16, 32, 64, 128], default=2)
parser.add_argument('--latency', type=int, default=48)
parser.add_argument('--ar-stall-period', type=int, default=0)
parser.add_argument('--rvalid-period', type=int, default=1)
parser.add_argument('--consumer-period', type=int, default=1)
parser.add_argument('--response-mode', type=int, choices=[0, 1, 2], default=0,
                    help='0=request order, 1=reverse-ready order, 2=beat round-robin')
parser.add_argument('--inject-error', choices=['none', 'rresp', 'rid', 'rlast'],
                    default='none')
parser.add_argument('--base-address', type=lambda value: int(value, 0),
                    default=0x18000000)
args = parser.parse_args()

error_modes = {'none': 0, 'rresp': 1, 'rid': 2, 'rlast': 3}

if args.read_ids > args.slots:
    print('FBUS_TEST_NOTE effective reader IDs are limited by slot count',
          flush=True)

print(f"READER_TEST_CONFIG read_ids={args.read_ids} slots={args.slots} "
      f"bytes={args.bytes} burst={args.burst} latency={args.latency} "
      f"ar_stall_period={args.ar_stall_period} "
      f"rvalid_period={args.rvalid_period} "
      f"consumer_period={args.consumer_period} mode={args.response_mode} "
      f"inject_error={args.inject_error} "
      f"base=0x{args.base_address:x}", flush=True)

verilator = os.environ.get('VERILATOR', 'verilator')
with tempfile.TemporaryDirectory(prefix='fbus-reader-bandwidth-') as directory:
    obj = Path(directory) / 'obj'
    command = [
        verilator, '--binary', '--timing', '--assert', '-O0', '-Wno-fatal',
        '--top-module', 'tb_fbus_read_bandwidth',
        f'-GREAD_ID_COUNT={args.read_ids}',
        f'-GREADER_SLOTS={args.slots}',
        f'-GBYTES={args.bytes}',
        f'-GBURST_BEATS={args.burst}',
        f'-GRESPONSE_LATENCY={args.latency}',
        f'-GAR_STALL_PERIOD={args.ar_stall_period}',
        f'-GRVALID_PERIOD={args.rvalid_period}',
        f'-GCONSUMER_PERIOD={args.consumer_period}',
        f'-GRESPONSE_MODE={args.response_mode}',
        f'-GERROR_MODE={error_modes[args.inject_error]}',
        f"-GBASE_ADDR=33'h{args.base_address:09x}",
        '--Mdir', str(obj), '-j', '4',
        str(repo / 'rtl/interfaces/axi4_if.sv'),
        str(repo / 'rtl/ai/postprocess/fbus_read_engine.sv'),
        str(repo / 'sim/tb_fbus_read_bandwidth.sv'),
    ]
    subprocess.run(command, check=True)
    subprocess.run([str(obj / 'Vtb_fbus_read_bandwidth')], check=True)
