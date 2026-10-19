#!/usr/bin/env python3
"""Expose only an audited, ASRAM-enabled private candidate to Vivado."""
import argparse
import json
from pathlib import Path
import subprocess
import sys

FEATURE = Path(__file__).resolve().parents[1]
REPO = FEATURE.parents[2]
sys.path.insert(0, str(REPO / 'tools/soc'))
from dma_load_candidate import validate  # noqa: E402


def checked_candidate(path):
    path = Path(path).resolve()
    if REPO / 'build/experiments/dma_stream_asram' not in path.parents:
        raise ValueError('ASRAM collateral must be in its private experiment tree')
    context, rtl = validate(path)
    if (context.get('hardware_variant') != FEATURE.name or
            context.get('activation_sram_enabled') is not True or
            context.get('dma_load_streaming_enable') is not True or
            context.get('dma_load_pipeline_version') != 'row_ready_v1' or
            context.get('dma_load_supported_modes') !=
            ['legacy', 'read_coalesced', 'read_assembled', 'spad_assembled']):
        raise ValueError('Expected enabled three-bank ASRAM / four-mode DMA RTL')
    subprocess.run([sys.executable, '-B', str(FEATURE / 'scripts/audit.py'),
                    '--context', str(path)], check=True, stdout=subprocess.PIPE, text=True)
    return context, rtl


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--context', type=Path, required=True)
    parser.add_argument('--tcl', action='store_true')
    args = parser.parse_args()
    context, rtl = checked_candidate(args.context)
    values = dict(hardware_alias=FEATURE.name, soc_config=context['config'],
                  collateral_directory=str(rtl))
    if args.tcl:
        for key, value in values.items():
            if any(c in value for c in '{}\n\r'):
                raise ValueError('Unsupported Tcl path')
            print(key, '{' + value + '}')
    else:
        print(json.dumps(values, indent=2))


if __name__ == '__main__':
    main()
