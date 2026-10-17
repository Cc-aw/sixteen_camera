#!/usr/bin/env python3
"""Check complete package UART logs; retain raw four-bank counters."""
import argparse
import json
from pathlib import Path
import statistics

from package import ROOT, BUILD, check, local, write_json
from analyze_log import parse as parse_workload, report as report_workload


def require(condition, message):
    if not condition:
        raise ValueError(message)


def decode(line):
    family, kind, *fields = line.strip().split(',')
    row = {}
    for item in fields:
        key, sep, value = item.partition('=')
        require(sep and key not in row and value, 'Invalid or duplicate log field')
        row[key] = int(value) if value.isdecimal() else value
    return family, kind, row


def smoke(lines):
    windows, blocks, passed = {}, {}, set()
    geometry = final = None
    expected_names = ['fill', 'stream_read', 'byte_write_verify', 'same_set_conflict']
    expected_geometry = dict(abi='1.2', banks=4, bytes=1048576, bank_mask=12288, blocks=16,
                             data_bits=512, ordinary_mshrs=32, soc_hz=100000000, ddr_hz=300000000)
    order = []
    for line in lines:
        if not line.startswith('L2BTEST,'):
            continue
        _, kind, row = decode(line)
        if kind == 'BUILD':
            continue
        if kind == 'GEOMETRY':
            require(geometry is None and not windows, 'Duplicate or late geometry')
            require(row == expected_geometry, 'Four-bank geometry mismatch')
            geometry = row
        elif kind == 'WINDOW':
            require(geometry and final is None and set(row) == {'id', 'name', 'cycles', 'blocks', 'sequence'}, 'Invalid window')
            index = row['id']; require(index == len(windows) and (index == 0 or index - 1 in passed), 'Window order/incomplete previous window')
            require(index < 4 and row['name'] == expected_names[index] and row['cycles'] > 0 and row['blocks'] == 16, 'Window fields differ')
            if index:
                require(row['sequence'] == (windows[index - 1]['sequence'] + 1) % 2**32, 'Snapshot sequence changed')
            windows[index] = row; blocks[index] = {}; order.append(('window', index))
        elif kind == 'BLOCK':
            index, block = row.get('window'), row.get('id')
            require(index in windows and index == len(windows) - 1 and index not in passed, 'Block outside active window')
            require(set(row) == {'window', 'id'} | {f'c{s:02}' for s in range(32)}, 'Counter slot coverage differs')
            require(block == len(blocks[index]) and block < 16, 'Duplicate/missing/out-of-order block')
            require(all(isinstance(row[f'c{s:02}'], int) and 0 <= row[f'c{s:02}'] < 2**64 for s in range(32)), 'Counter outside uint64')
            blocks[index][block] = row
        elif kind == 'WINDOW_PASS':
            index = row.get('id')
            require(row == dict(id=index, banks_exercised=4, snapshot_stable=1) and index in windows and index not in passed, 'Invalid window pass')
            require(len(blocks[index]) == 16, 'Missing raw counter blocks')
            for bank, block in enumerate((5, 6, 14, 15)):
                require(blocks[index][block]['c01'] > 0, 'L2 bank not exercised')
                require(blocks[index][3][f'c{(11,12,14,15)[bank]:02}'] > 0, 'CPU bank not exercised')
                require(blocks[index][block]['c11'] <= 32, 'MSHR peak exceeds 32')
            passed.add(index)
        elif kind == 'PASS':
            require(final is None and passed == set(range(4)), 'Incomplete or duplicate smoke pass')
            require(row == dict(test='smoke', windows=4, buffer_bytes=2097152, banks_exercised=4, marker='ALL_SMOKE_COMPLETE'), 'Invalid completion marker')
            final = row
        else:
            raise ValueError('Unexpected smoke record: ' + kind)
    require(geometry and final, 'Incomplete smoke log')
    return dict(geometry=geometry, windows=list(windows.values()), blocks=blocks, complete=True)


def parse(text, manifest):
    lines = [line.strip() for line in text.splitlines()]
    builds = [decode(line)[2] for line in lines if line.startswith('L2BTEST,BUILD,')]
    require(len(builds) == 1, 'Capture exactly one complete test boot per log')
    build = builds[0]
    require(set(build) == {'schema', 'test', 'build_id', 'source'} and build['schema'] == 1, 'Package build schema differs')
    require(build['build_id'] == manifest['build_id'] and build['source'] == manifest['source_revision'], 'Log and local build identity differ')
    kind = build['test']; require(kind in manifest['artifacts'], 'Unknown test')
    for line in lines:
        require(not line.startswith(('L2BTEST,FAIL,', 'L2BTEST,TRAP,', 'L2BTEST,DATA_MISMATCH,', 'L2BTEST,REGISTER_MISMATCH,',
                                     'ATSOFT1,FAIL,', 'ATSOFT1,TRAP,', 'ATSOFT1,PPU_DIFF,')), 'Firmware reports a failure: ' + line)
    if kind == 'smoke':
        result = smoke(lines)
    else:
        errors, sessions = parse_workload(text)
        require(not errors and len(sessions) == 1, 'Workload parser: ' + '; '.join(errors))
        session = sessions[0]
        require(session['build']['diagnostics'] == (2 if kind == 'diagnostic' else 0), 'Diagnostic/formal mode differs')
        if kind == 'diagnostic':
            devices = [decode(l)[2] for l in lines if l.startswith('ATSOFT1,MEM_DEVICE,')]
            require(len(devices) == 1 and devices[0]['available'] == 1 and devices[0]['abi'] == 0x4d50563300010002 and devices[0]['blocks'] == 16, 'Four-bank diagnostics are unavailable')
        result = dict(sessions=sessions, text_report=report_workload(sessions), complete=True)
    return dict(schema=1, valid=True, test=kind, build_id=build['build_id'], elf_sha256=manifest['artifacts'][kind]['sha256'],
                source_revision=build['source'], elf_identity='LOCAL_MANIFEST_DECLARATION',
                board_identity='Host receipt or operator declaration; no on-board bitstream fingerprint', result=result)


def compare(reports):
    require(len(reports) >= 2, 'At least two reference reports required')
    reference = reports[0]
    require(all(r['valid'] and r['test'] == 'reference' and r['elf_sha256'] == reference['elf_sha256'] and
                r.get('elf_identity') == 'DOWNLOAD_RECEIPT_VERIFIED' for r in reports),
            'Compare only the exact same reference ELF with verified download receipts')
    groups = {}
    for row in reports:
        group = row.get('comparison_group')
        require(isinstance(group, str) and group, 'Each report requires --group for comparison')
        groups.setdefault(group, []).append(row['result']['sessions'][0]['modes'][2]['summary']['cycles'])
    require(len(groups) == 2, 'Use exactly two named hardware groups')
    return dict(groups={k:dict(samples=v, median_cycles=statistics.median(v), min_cycles=min(v), max_cycles=max(v)) for k, v in groups.items()},
                elf_sha256=reference['elf_sha256'], scope='Whole-system same-ELF board observations; not isolated L2 attribution; timing-unmet candidate')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('log', type=Path, nargs='?')
    parser.add_argument('--group', help='Explicit hardware label, for example new_4bank or old_2bank')
    parser.add_argument('--compare', nargs='+', type=Path)
    args = parser.parse_args()
    if args.compare:
        result = compare([json.loads(local(p).read_text()) for p in args.compare])
        print(json.dumps(result, indent=2)); return
    require(args.log is not None, 'Provide a UART log')
    path = local(args.log)
    result = parse(path.read_text(errors='replace'), check())
    if args.group:
        result['comparison_group'] = args.group
    receipt = path.with_suffix('.load.json')
    if receipt.exists():
        record = json.loads(receipt.read_text())
        require(record['build_id'] == result['build_id'] and record['test'] == result['test'] and record['elf_sha256'] == result['elf_sha256'], 'ELF download receipt mismatch')
        result['download_receipt'] = record
        result['elf_identity'] = 'DOWNLOAD_RECEIPT_VERIFIED'
    write_json(path.with_suffix('.json'), result)
    report = result['result'].get('text_report', 'Four-bank smoke passed: geometry, 2 MiB data, byte writes, same-set conflicts, four complete 16x32 snapshots.')
    path.with_suffix('.txt').write_text(report + '\nL2_BOARD_LOG=PASS\n')
    print(report + '\nL2_BOARD_LOG=PASS')


if __name__ == '__main__':
    main()
