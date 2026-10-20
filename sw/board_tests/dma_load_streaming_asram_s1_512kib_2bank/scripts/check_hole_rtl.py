#!/usr/bin/env python3
"""Check explicitly supplied frozen bitstream RTL; never connect to hardware."""
import argparse
import json
from pathlib import Path
import re
import subprocess

from build import ROOT, BUILD, sha, write


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--rtl', required=True, type=Path)
    parser.add_argument('--build-input', required=True, type=Path)
    args = parser.parse_args()
    rtl = args.rtl.resolve()
    frozen = json.loads(args.build_input.read_text())
    output = BUILD / 'hole_rtl'
    output.mkdir(parents=True, exist_ok=True)
    hashes = {}

    def collect(name, result):
        path = rtl / (name + '.sv')
        if path in result:
            return
        if frozen.get(str(path)) != sha(path):
            raise ValueError('RTL differs from bitstream build input: ' + str(path))
        hashes[str(path)] = sha(path)
        result.add(path)
        for module in re.findall(r'^\s*(\w+)\s+\w+\s*\(', path.read_text(), re.M):
            if (rtl / (module + '.sv')).is_file():
                collect(module, result)

    # Audit the exact CPU RTL too; this small simulation executes the ASRAM
    # endpoint and its real queues, not the CPU or the physical URAM primitive.
    cache = rtl / 'DCache.sv'
    if frozen.get(str(cache)) != sha(cache):
        raise ValueError('DCache RTL differs from bitstream build input')
    hashes[str(cache)] = sha(cache)
    for lane, name in enumerate(('ActivationSramPort', 'ActivationSramPort_2', 'ActivationSramPort_4')):
        sources = set()
        collect(name, sources)
        executable = output / ('lane_' + str(lane))
        subprocess.run(['iverilog', '-g2012', '-s', 'tb_hole_port', '-DDUT=' + name,
                        '-Ptb_hole_port.BASE=' + str(0x20000000 + lane * 0x400000),
                        '-o', str(executable), str(ROOT / 'tests/tb_hole_port.sv'),
                        *map(str, sorted(sources))], check=True, capture_output=True, text=True)
        result = subprocess.run(['vvp', str(executable)], check=True, capture_output=True,
                                text=True, timeout=20)
        (output / ('lane_' + str(lane) + '.log')).write_text(result.stdout + result.stderr)
        if 'FROZEN_HOLE_PORT_PASS' not in result.stdout:
            raise ValueError('Missing simulation PASS')
        print(result.stdout.strip())
    write(output / 'evidence.json', dict(status='FROZEN_PORT_HOLE_RTL_PASS', cases=18,
          denied_hole_probes=12, cpu_executed=False, board_accessed=False,
          vendor_primitive_simulated=False, rtl_sha256=hashes,
          build_input_sha256=sha(args.build_input)))


if __name__ == '__main__':
    main()
