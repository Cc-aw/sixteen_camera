#!/usr/bin/env python3
"""Require disabled C1a to preserve every original C0 event and cycle."""
import argparse
import csv
import gzip
from itertools import zip_longest
import json
from pathlib import Path

from compare_candidate import sha


def events(path):
    with gzip.open(path, 'rt') as source:
        for row in csv.reader(source):
            if row[0] == 'K':
                if row[6] != '0':
                    raise ValueError('Disabled candidate skipped an Input tile')
                continue
            if row[0] == 'N':
                raise ValueError('Disabled candidate created a replacement completion')
            yield row[:5] + row[6:]  # The extra observation events shift sequence numbers only.


def compare(baseline, candidate, output):
    count, mismatch = 0, None
    for left, right in zip_longest(events(baseline), events(candidate)):
        if left != right:
            mismatch = dict(event=count, baseline=left, candidate=right)
            break
        count += 1
    result = dict(schema=1, status='PASS' if mismatch is None else 'FAIL', events_compared=count,
                  exact_cycles=True, mismatch=mismatch,
                  sha256={str(p): sha(p) for p in (baseline, candidate, Path(__file__).resolve())})
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(result, indent=2) + '\n')
    if mismatch:
        raise ValueError('CSC disabled fallback differs: ' + str(mismatch))
    print('CSC_DISABLED_CYCLE_EVENT_IDENTITY_PASS', count)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--baseline', type=Path, required=True)
    parser.add_argument('--candidate', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    compare(args.baseline.resolve(), args.candidate.resolve(), args.output.resolve())
