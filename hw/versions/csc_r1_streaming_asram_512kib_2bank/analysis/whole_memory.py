#!/usr/bin/env python3
"""Initialize the relocated functional memory with frozen weights and inputs."""
import argparse
import hashlib
import json
from pathlib import Path
import struct
import sys

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT / 'sw/benchmarks/frontend/scripts'))
from first_layer_s2d_prepare import array


def generate(workload, output):
    manifest = json.loads(workload.read_text())
    for name, digest in manifest['sources_sha256'].items():
        if hashlib.sha256((ROOT / name).read_bytes()).hexdigest() != digest:
            raise ValueError('Frozen model changed: ' + name)
    params = next((ROOT / 'sw/board_tests/dma_load_streaming_asram_512kib_2bank/model').glob('*profile_params.h'))
    text = params.read_text()
    with output.open('xb') as handle:
        for name, item in manifest['weight_symbols'].items():
            values = array(text, name)
            data = bytes(v & 255 for v in values) if item['kind'] == 'elem_t' else b''.join(struct.pack('<i', v) for v in values)
            if len(data) != item['bytes']:
                raise ValueError('Parameter size mismatch: ' + name)
            handle.write(struct.pack('<QI', item['base'], len(data)))
            handle.write(data)
        # Full original input tensor: 480x640x3. This deterministic functional
        # fixture is not a board image or a claimed numerical network oracle.
        for lane in range(3):
            data = bytes(((i * 13 + i // 3 * 7 + lane * 3) % 63 - 31) & 255 for i in range(480 * 640 * 3))
            handle.write(struct.pack('<QI', 0xb0000000 + lane * 0x1000000, len(data)))
            handle.write(data)
    print('FROZEN_PARAMETER_MEMORY_READY', output.stat().st_size)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--workload', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    generate(args.workload, args.output)
