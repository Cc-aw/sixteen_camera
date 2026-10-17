#!/usr/bin/env python3
"""Analyze a local UART recording against this package's audited ELF."""
import argparse
import json
from pathlib import Path

from analyze_dma_load import parse
from package import BUILD, check, local, sha, write_json


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('log', type=Path)
    args = parser.parse_args()
    manifest = check()
    path = local(args.log)
    raw = path.read_text(errors='replace')
    starts = [line for line in raw.splitlines() if line.startswith(('DMAL1,BUILD,', 'DMALF1,BUILD,'))]
    if not starts:
        raise ValueError('Missing DMA BUILD')
    fields = dict(field.split('=', 1) for field in starts[-1].split(',')[2:])
    if fields.get('package_build') != manifest['build_id']:
        raise ValueError('UART log is from another software build')
    report = parse(raw, int(manifest['target']['hardware_build_id'], 16))
    kind = 'first' if report['scope'] == 'first_conv' else 'model'
    receipt = path.parent / (kind + '.load.json')
    if receipt.exists():
        loaded = json.loads(receipt.read_text())
        if loaded['build_id'] != manifest['build_id'] or loaded['elf_sha256'] != manifest['artifacts'][kind]['sha256']:
            raise ValueError('Load receipt does not match this ELF')
    else:
        loaded = None
    report.update(source=str(path), sha256=sha(path), software_build_id=manifest['build_id'],
                  elf_sha256=manifest['artifacts'][kind]['sha256'], host_load_receipt=loaded,
                  bitstream_timing_met=manifest['target']['timing_met'])
    write_json(path.with_suffix('.json'), report)
    text = ['DMA_BOARD_LOG=PASS test=' + kind]
    for row in report['aggregate']:
        text.append(f'{row["mode"]}: scaling={row["scaling"]:.4f} '
                    f'serial_gain={row["serial_gain"]:.4f} parallel_gain={row["parallel_gain"]:.4f}')
    path.with_suffix('.txt').write_text('\n'.join(text) + '\n')
    print('\n'.join(text))


if __name__ == '__main__':
    main()
