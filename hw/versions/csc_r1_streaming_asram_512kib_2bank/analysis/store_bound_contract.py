#!/usr/bin/env python3
"""Audit the frozen native tiling bound used before derived ochs is ready.

This prototype accepts the frozen legal workload, not malformed native packets.
The real derived ochs pipeline copies inner pochs; its configured outer output
channels upper-bound every such tile in the accepted workload and fixtures.
"""
import argparse
import json
from pathlib import Path

from compare_candidate import sha


def audit(rtl, commands, output):
    derived = rtl / 'LoopConvDerivedParamsPipe.sv'
    text = derived.read_text()
    for expression in ('s1Ochs <= io_in_bits_inner_bounds_pochs;',
                       's2Ochs <= s1Ochs;', 'io_out_bits_params_r_ochs <= s2Ochs;'):
        if expression not in text:
            raise ValueError('Derived output channel pipeline changed')
    lc = rtl / 'LoopConv.sv'
    for slot in range(2):
        for expression in (f'loops_{slot}_outer_bounds_out_channels <= _cmd_q_io_deq_bits_cmd_rs1[63:48];',
                           f'loops_{slot}_inner_bounds_pochs <= _cmd_q_io_deq_bits_cmd_rs2[15:0];'):
            if expression not in lc.read_text():
                raise ValueError('Native configuration packing changed')
    results = []
    for path in commands:
        packets, pending = 0, {}
        for line in path.read_text().splitlines():
            lane, frame, stage, funct, rs1, rs2 = map(int, line.split())
            key = (lane, frame)
            cfg = pending.setdefault(key, {})
            if 16 <= funct <= 21:
                if funct in cfg or (funct != 16 and 16 not in cfg):
                    raise ValueError('Incomplete/repeated native configuration')
                cfg[funct] = (rs1, rs2)
            elif funct == 15:
                if set(cfg) != set(range(16, 22)):
                    raise ValueError('Native run lacks its complete configuration')
                outer, tile = (cfg[16][0] >> 48) & 65535, cfg[17][1] & 65535
                if not 0 < tile <= outer:
                    raise ValueError(f'Outer channel bound violated: {path} lane={lane} frame={frame} stage={stage}')
                packets += 1
                cfg.clear()
        if any(pending.values()) or not packets:
            raise ValueError('Unfinished/empty native workload')
        results.append(dict(commands=str(path), native_conv_packets=packets, tile_channels_le_outer=True))
    result = dict(schema=1, status='PASS', scope='Frozen legal native tiling and directed fixtures only',
                  malformed_native_packets_supported=False, cases=results,
                  sha256={str(p): sha(p) for p in [Path(__file__).resolve(), derived, lc, *commands]})
    output.write_text(json.dumps(result, indent=2) + '\n')
    print('CSC_STORE_BOUND_CONTRACT_PASS', sum(r['native_conv_packets'] for r in results))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--rtl', type=Path, required=True)
    parser.add_argument('--commands', type=Path, action='append', required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    audit(args.rtl.resolve(), [p.resolve() for p in args.commands], args.output.resolve())
