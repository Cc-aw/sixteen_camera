#!/usr/bin/env python3
"""Calibrate the full Verilator service against archived real XSim writes."""
import argparse
from collections import Counter
import csv
import gzip
import hashlib
import json
from pathlib import Path
import re
import struct
import subprocess

from calibrate_commands import commands

ROOT = Path(__file__).resolve().parents[4]


def selected(word, mask):
    value = int(word, 16)
    return tuple((value >> (8*i)) & 255 for i in range(32) if mask >> i & 1)


def calibrate(compact, executable, out):
    out.mkdir(parents=True, exist_ok=False)
    reference_manifest = json.loads((compact / 'trace_manifest.json').read_text())
    for name, expected in reference_manifest['traces'].items():
        if hashlib.sha256((compact / name).read_bytes()).hexdigest() != expected:
            raise ValueError('Reference XSim trace hash mismatch: ' + name)
    cases = json.loads((compact / 'cases.json').read_text())
    lut = (ROOT / 'sw/board_tests/dma_load_streaming_asram_512kib_2bank/model/prepared_packets.inc').read_text()
    lut = lut.split('packed_silu_luts[69][32] = {', 1)[1].split('};', 1)[0]
    luts = list(map(int, re.findall(r'UINT64_C\((\d+)\)', lut)))
    if len(luts) != 69 * 32:
        raise ValueError('Incomplete frozen LUT')
    command = out / 'commands.txt'
    command.write_text(''.join(' '.join(map(str, row)) + '\n' for row in commands(cases, luts)))
    memory = out / 'memory'
    memory.mkdir()
    for lane in range(3):
        for stage, case in enumerate(cases):
            image = bytearray([0xa5]) * 1048576
            offset = 0
            for line in (compact / f'layer_{case["stage"]}.mem').read_text().splitlines():
                if line.startswith('@'):
                    offset = int(line[1:], 16)
                elif line:
                    image[offset] = int(line, 16)
                    offset += 1
            (memory / f'lane{lane}_stage{stage}.bin').write_bytes(
                struct.pack('<QI', 0x80000000 + lane * 0x100000, len(image)) + image)
    with (out / 'simulation.log').open('w') as log:
        subprocess.run([str(executable), str(command), str(memory), str(out / 'trace'), '1', '3', '7'],
                       stdout=log, stderr=subprocess.STDOUT, check=True)
    reference, observed = Counter(), Counter()
    for row in csv.reader((compact / 'spad_events_lane0.csv').open()):
        if row[2] == 'BANK_COMMIT':
            mask = int(row[8], 16)
            reference[(int(row[5]), int(row[6]), int(row[7]), mask, int(row[11]), selected(row[9], mask))] += 1
    with gzip.open(out / 'trace/full_lane0.csv.gz', 'rt') as handle:
        for row in csv.reader(handle):
            if row[0] == 'W' and row[3] == '2':
                stage, bank, address, mask, kind = map(int, (row[4], *row[6:10]))
                observed[(stage, bank, address, mask, kind, selected(row[11], mask))] += 1
    result = dict(schema=1, status='FULL_RTL_COMPACT_WRITE_CALIBRATION_PASS' if reference == observed else 'FAIL',
                  scope='All eight compact stages, lane 0; physical bank/row/mask/processed bytes/writer type multiset',
                  expected_commits=reference.total(), observed_commits=observed.total(),
                  missing_examples=list((reference - observed).items())[:5], extra_examples=list((observed - reference).items())[:5],
                  executable_sha256=hashlib.sha256(executable.read_bytes()).hexdigest(),
                  reference_manifest_sha256=hashlib.sha256((compact / 'trace_manifest.json').read_bytes()).hexdigest())
    (out / 'calibration.json').write_text(json.dumps(result, indent=2) + '\n')
    if reference != observed:
        raise ValueError('Physical write calibration failed')
    print(result['status'])


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--compact', type=Path, required=True)
    parser.add_argument('--executable', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    calibrate(args.compact.resolve(), args.executable.resolve(), args.output.resolve())
