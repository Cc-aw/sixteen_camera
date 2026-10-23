#!/usr/bin/env python3
"""Exercise the production Tensor bridge with Vivado's real async FIFO model."""
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
VIVADO = Path(os.environ.get('VIVADO_BIN', '/mnt/data/Vivado/Vivado/2023.2/bin/vivado')).resolve().parents[1]
OUT = ROOT / 'build/timing_s1_tensor_xpm'


def main():
    OUT.mkdir(parents=True, exist_ok=False)
    sources = [ROOT / name for name in (
        'board/rtl/interfaces/axi4_if.sv', 'board/rtl/bus/cdc_payload_fifo.sv',
        'board/rtl/bus/axi4_ui_write_cdc.sv', 'board/rtl/memory/tensor_coherent_write_cdc.sv',
        'tests/merged_dma/tb_tensor_coherent_write_cdc.sv')]
    sources.append(VIVADO / 'data/verilog/src/glbl.v')
    commands = [
        [str(VIVADO / 'bin/xvlog'), '--sv', *map(str, sources)],
        [str(VIVADO / 'bin/xelab'), 'tb_tensor_coherent_write_cdc', 'glbl', '-L', 'xpm',
         '-L', 'unisims_ver', '--relax', '--mt', '4', '-s', 'tensor_cdc_xpm']]
    for index, command in enumerate(commands):
        with (OUT / f'compile_{index}.log').open('w') as log:
            subprocess.run(command, cwd=OUT, stdout=log, stderr=subprocess.STDOUT,
                           check=True, timeout=240)
    os.environ['VIVADO_ROOT'] = str(VIVADO)
    sys.path.insert(0, str(ROOT / 'tests/rtl'))
    from run_ddr_axi_crossbar_throughput_test import run_snapshot
    result = run_snapshot('tensor_cdc_xpm', OUT)
    (OUT / 'result.log').write_text(result)
    assert 'TENSOR_COHERENT_CDC_PASS writes=48' in result, result
    assert 'Fatal:' not in result and 'Error:' not in result, result
    (OUT / 'evidence.json').write_text(json.dumps(dict(
        status='TENSOR_COHERENT_XPM_CDC_PASS', writes=48,
        actual_vendor_xpm_model=True,
        sources={str(p.relative_to(ROOT)) if p.is_relative_to(ROOT) else str(p):
                 hashlib.sha256(p.read_bytes()).hexdigest() for p in sources}), indent=2) + '\n')
    print('TENSOR_COHERENT_XPM_CDC_PASS writes=48 independent_AW_W_B_backpressure=checked')


if __name__ == '__main__':
    main()
