#!/usr/bin/env python3
"""Native full-compute positive/epoch test; not a production workload or G2 case.

Repeat the real compact 4x4x32, 1x1 Conv packet in one physical Input half.
Each of 3 lanes and 3 frames has distinct nonzero input bytes. Both OFF/ON
execute precisely these same native commands, including real EX and stores.
"""
import argparse
import json
from pathlib import Path
import struct

from compare_candidate import sha


def prepare(reference, output):
    output.mkdir(parents=True, exist_ok=False)
    memory = output / 'memory'
    memory.mkdir()
    original = reference / 'commands.txt'
    rows = [list(map(int, line.split())) for line in original.read_text().splitlines()]
    commands, inputs = [], [original, Path(__file__).resolve()]
    for lane in range(3):
        case = [r for r in rows if r[0] == lane and r[1] == 0 and r[2] == 2]
        begin = next(i for i, r in enumerate(case) if r[3] == 16)
        end = next(i for i in range(begin, len(case)) if case[i][3] == 15)
        packet = [r[:] for r in case[begin:end+1]]
        if [r[3] for r in packet] != list(range(16, 22)) + [15]:
            raise ValueError('Compact native packet format changed')
        source = reference / 'memory' / f'lane{lane}_stage2.bin'
        inputs.append(source)
        blob = source.read_bytes()
        base, size = struct.unpack('<QI', blob[:12])
        if len(blob) != size+12:
            raise ValueError('Expected one native compact memory segment')
        input_address = 0x80004000 + lane*0x100000
        # Config 6 holds the original native Input pointer in rs2.
        if packet[5][5] != input_address:
            raise ValueError('Unexpected compact Input mapping')
        packet[-1][4] = (packet[-1][4] & ~((3<<18)|(3<<16))) | (1<<18) | (2<<16)
        for frame in range(3):
            stage = frame+2
            image = bytearray(blob)
            offset = 12+input_address-base
            image[offset:offset+512] = bytes((i*13+lane*73+frame*29+7)%256 for i in range(512))
            (memory / f'lane{lane}_stage{stage}.bin').write_bytes(image)
            for row in case[:begin]:
                commands.append([lane, frame, stage, *row[3:]])
            for _ in range(4):
                for row in packet:
                    commands.append([lane, frame, stage, *row[3:]])
            for row in case[end+1:]:
                commands.append([lane, frame, stage, *row[3:]])
    command_file = output / 'commands.txt'
    command_file.write_text(''.join(' '.join(map(str, row))+'\n' for row in commands))
    result = dict(schema=1, status='NATIVE_DIRECTED_FIXTURE', production_workload=False,
                  performance_evidence=False, lanes=3, frames=3, repeated_packets_per_frame=4,
                  physical_input_half=0, physical_weight_half=1, distinct_input_per_lane_and_frame=True,
                  expected_requests_per_lane=12, expected_skips_per_lane=9,
                  native_packet_changes='Physical A/B overrides; repeat first complete 4x4x32 Conv packet',
                  sha256={str(p):sha(p) for p in [*inputs, command_file, *sorted(memory.iterdir())]})
    (output / 'fixture.json').write_text(json.dumps(result, indent=2)+'\n')
    print('CSC_NATIVE_DIRECTED_FIXTURE_COMPLETE')


if __name__ == '__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--reference',type=Path,required=True)
    parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args()
    prepare(args.reference.resolve(),args.output.resolve())
