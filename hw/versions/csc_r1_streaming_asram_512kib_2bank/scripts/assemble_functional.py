#!/usr/bin/env python3
"""Assemble completed private-memory functional lanes without retiming events."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re


def assemble(source, output):
    manifest = json.loads((source / 'execution_manifest.json').read_text())
    lanes = manifest['lanes']
    if lanes not in ([0], [0, 1, 2]):
        raise ValueError('Expected a single control or all three functional lanes')
    for name, digest in manifest['sha256'].items():
        if hashlib.sha256(Path(name).read_bytes()).hexdigest() != digest:
            raise ValueError('Functional execution input changed: ' + name)
    records, log = [], ''
    for lane in lanes:
        text = (source / f'lane{lane}.log').read_text()
        if not re.search(rf'^FULL_GEMMINI_RTL_PASS lane={lane} ', text, re.M) or re.search(r'Assertion failed|%Error|Aborting', text):
            raise ValueError('Incomplete/faulted functional lane ' + str(lane))
        markers = re.findall(rf'^FULL_RTL_STAGE lane={lane} frame=(\d+) stage=(\d+) cycle=', text, re.M)
        if [(int(f), int(s)) for f, s in markers] != [(f, s) for f in range(2) for s in range(166)]:
            raise ValueError('Missing/duplicate native frame/stage coverage')
        path = source / f'lane{lane}/full_lane{lane}.csv.gz'
        records.append(dict(lane=lane, source=str(path), sha256=hashlib.sha256(path.read_bytes()).hexdigest()))
        log += text
    output.mkdir(parents=True, exist_ok=False)
    for record in records:
        os.link(record['source'], output / f'full_lane{record["lane"]}.csv.gz')
    (output / 'simulation.log').write_text(log)
    (output / 'aggregation_manifest.json').write_text(json.dumps(dict(schema=1,
        status='FULL_FUNCTIONAL_LANES_ASSEMBLED', shared_memory_timing_model=False,
        source_manifest_sha256=hashlib.sha256((source / 'execution_manifest.json').read_bytes()).hexdigest(),
        trace_files=records), indent=2) + '\n')
    print('FULL_FUNCTIONAL_LANES_ASSEMBLED', lanes)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    assemble(args.source.resolve(), args.output.resolve())
