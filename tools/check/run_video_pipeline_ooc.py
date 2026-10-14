#!/usr/bin/env python3
"""Synthesize video timing boundaries without full SoC synthesis or implementation."""
from pathlib import Path
import argparse
import os
import re
import subprocess

ROOT = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--output', type=Path, required=True)
parser.add_argument('--targets', nargs='+', choices=['ui-return', 'mosaic', 'dvp', 'tensor-dma', 'perf-reset', 'camera'],
    default=['ui-return', 'mosaic', 'dvp', 'tensor-dma', 'perf-reset', 'camera'])
args = parser.parse_args()
output = args.output.resolve()
output.mkdir(parents=True, exist_ok=False)
common = ['hw/rtl/interfaces/axi4_if.sv']
cases = {
    'ui-return': common + ['hw/rtl/bus/cdc_payload_fifo.sv', 'hw/rtl/bus/axi4_ui_read_cdc.sv',
        'tests/rtl/benches/timing/ui_return_synthesis_top.sv'],
    'mosaic': common + ['hw/rtl/interfaces/axis_video_if.sv', 'hw/rtl/video/display/rgb565_to_rgb888.sv',
        'hw/rtl/video/display/mosaic_rgb565_reader.sv'],
    'dvp': ['hw/rtl/video/camera/dvp_event_bridge.sv'],
    'tensor-dma': common + ['hw/rtl/ai/preprocess/yolov5nu_tensor_stream_packer.sv',
        'hw/rtl/ai/preprocess/yolov5nu_multi_channel_tensor_dma.sv'],
    'perf-reset': common + ['hw/rtl/memory/memory_perf_counters.sv', 'hw/rtl/memory/memory_perf_external.sv'],
}
# Derive camera dependencies from current handwritten modules; include packages
# before modules. XPM primitives are supplied by Vivado, as in the project flow.
modules = {}
for path in (ROOT / 'hw/rtl').rglob('*'):
    if path.suffix in ('.sv', '.v'):
        for module in re.findall(r'^module\s+(\w+)', path.read_text(errors='replace'), re.M):
            modules[module] = path
seen = set()
def visit(module):
    path = modules[module]
    if path in seen:
        return
    seen.add(path)
    for child in re.findall(r'^\s+(\w+)\s+(?:#\s*\(.*?\)\s*)?\w+\s*\(',
            path.read_text(errors='replace'), re.M | re.S):
        if child in modules:
            visit(child)
visit('ov7670_frontend')
cases['camera'] = [str(p.relative_to(ROOT)) for p in sorted((ROOT / 'hw/rtl/pkg').glob('*.sv'))] + [
    str(p.relative_to(ROOT)) for p in sorted((ROOT / 'hw/rtl/interfaces').glob('*.sv'))] + [
    str(p.relative_to(ROOT)) for p in sorted(seen)] + [
    "tests/rtl/benches/timing/camera_frontend_synthesis_top.sv"]
for name in args.targets:
    sources = cases[name]
    out = output / name
    out.mkdir()
    filelist = out / 'sources.txt'
    filelist.write_text(''.join(str(ROOT / path) + '\n' for path in sources))
    with (out / 'console.log').open('w') as log:
        subprocess.run([os.environ.get('VIVADO_BIN', 'vivado'), '-mode', 'batch', '-source',
            str(ROOT / 'tools/check/synth_video_pipeline_ooc.tcl'), '-tclargs', name, str(out), str(filelist)],
            cwd=out, stdout=log, stderr=subprocess.STDOUT, check=True)
    print((out / 'result.txt').read_text().strip(), flush=True)
