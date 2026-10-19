#!/usr/bin/env python3
"""Check frozen streaming artifacts and analyze their board UART recordings."""
import argparse
import hashlib
import json
from pathlib import Path

from analyze_dma_load import parse_first_short, parse_short


def sha(path):
    digest = hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(block)
    return digest.hexdigest()


def check(args):
    record = json.loads(args.record.read_text())
    context = json.loads(args.context.read_text())
    manifest = json.loads((args.firmware/'dma_load_manifest.json').read_text())
    identity = record['build_id']
    if (record['status'] != 'BITSTREAM_GENERATED_TIMING_UNMET_BOARD_PENDING'
            or context['dma_load_build_id'] != identity
            or not context.get('dma_load_streaming_enable')
            or len(context['dma_load_supported_modes']) != 4
            or manifest['status'] != 'ELF_AUDIT_PASS' or manifest['build_id'] != identity
            or manifest['modes'] != 4 or manifest['schema'] != 2):
        raise ValueError('Artifact identity is not the audited four-mode streaming candidate')
    if sha(args.bitstream) != record['bitstream_sha256']:
        raise ValueError('Bitstream differs from the recovery record')
    if sha(args.context) != manifest['sha256'][str(args.context.resolve())]:
        raise ValueError('Generation context differs from the audited firmware context')
    expected = record['matching_firmware_sha256']
    for kind in ('first', 'model'):
        elf = args.firmware/f'yolov5_dma_load_{kind}.elf'
        hashes = [digest for path, digest in expected.items() if Path(path).name == elf.name]
        if (len(hashes) != 1 or sha(elf) != hashes[0]
                or hashes[0] != manifest['sha256'][str(elf.resolve())]):
            raise ValueError('ELF differs from the recovery record: '+kind)
    print('STREAMING_BOARD_ARTIFACTS=PASS build_id='+identity+' board_accessed=0')
    return record, manifest


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=('check', 'analyze'))
    for name in ('record', 'context', 'firmware', 'bitstream'):
        parser.add_argument('--'+name, type=Path, required=True)
    parser.add_argument('--log', type=Path)
    parser.add_argument('--test', choices=('first', 'model'))
    args = parser.parse_args()
    record, manifest = check(args)
    if args.action == 'check':
        return
    if args.log is None or args.test is None:
        parser.error('analyze requires --log and --test')
    raw = args.log.read_text(errors='replace')
    prefix = 'DMALF1' if args.test == 'first' else 'DMAL1'
    starts = [line for line in raw.splitlines() if line.startswith(prefix+',BUILD,')]
    if not starts:
        raise ValueError('Missing '+prefix+' BUILD')
    fields = dict(field.split('=', 1) for field in starts[-1].split(',')[2:])
    if fields.get('package_build') != manifest['software_build_id']:
        raise ValueError('UART log is from another software build')
    if fields.get('schema') != '2' or fields.get('modes' if args.test == 'first' else 'load_modes') != '4':
        raise ValueError('Expected all four modes with schema 2')
    parse = parse_first_short if args.test == 'first' else parse_short
    report = parse(raw, int(record['build_id'], 16))
    report.update(source=str(args.log.resolve()), sha256=sha(args.log),
                  software_build_id=manifest['software_build_id'],
                  bitstream_sha256=record['bitstream_sha256'], timing_met=record['timing_met'])
    args.log.with_suffix('.json').write_text(json.dumps(report, indent=2)+'\n')
    lines = ['STREAMING_BOARD_LOG=PASS test='+args.test]
    for row in report['aggregate']:
        lines.append(f'{row["mode"]}: scaling={row["scaling"]:.4f} '
                     f'serial_gain={row["serial_gain"]:.4f} parallel_gain={row["parallel_gain"]:.4f}')
    args.log.with_suffix('.txt').write_text('\n'.join(lines)+'\n')
    print('\n'.join(lines))


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError, KeyError) as error:
        raise SystemExit('STREAMING_BOARD_FAIL: '+str(error))
