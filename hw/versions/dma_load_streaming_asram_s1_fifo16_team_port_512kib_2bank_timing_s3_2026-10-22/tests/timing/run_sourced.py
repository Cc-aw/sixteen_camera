#!/usr/bin/env python3
"""Production L2 SourceD/BankedStore data, ordering, hazards and throughput."""
import json
import os
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'scripts'))
from common import selected_output, sha
from rtl_support import module_closure, ports


def main():
    generated, context = selected_output(Path(os.environ.get('S3_GENERATED_OUTPUT', str(ROOT / 'build/timing_generated_final'))))
    rtl = generated / 'gen-collateral'
    out = ROOT / 'build/s3_sourced_bankedstore'
    out.mkdir(parents=True, exist_ok=True)
    declarations, instances, bindings = [], [], []
    auto = {'io_pb_beat_data', 'io_pb_beat_mask', 'io_rel_beat_data'}
    auto.update(n for d, w, n in ports(rtl / 'SourceD.sv') if n.startswith('io_bs_'))
    for direction, width, name in ports(rtl / 'SourceD.sv'):
        wire = direction == 'output' or name in auto
        declarations.append(f'{"wire" if wire else "reg"} {width} {name}' + (';' if wire else ' = 0;'))
        bindings.append(f'.{name}({name})')
    instances.append('SourceD dut(' + ','.join(bindings) + ');')
    bindings = []
    for direction, width, name in ports(rtl / 'BankedStore.sv'):
        value = name
        if name == 'clock':
            pass
        elif name.startswith('io_sourceD_'):
            value = name.replace('io_sourceD_', 'io_bs_')
        else:
            declarations.append(f'{"reg" if direction == "input" else "wire"} {width} {name}' +
                                (' = 0;' if direction == 'input' else ';'))
        bindings.append(f'.{name}({value})')
    instances.append('BankedStore store(' + ','.join(bindings) + ');')
    body = ROOT / 'tests/timing/tb_sourced_s3_body.sv'
    tb = out / 'tb.sv'
    tb.write_text('`timescale 1ns/1ps\nmodule tb;\n' + '\n'.join(declarations + instances) + '\n' + body.read_text() + '\nendmodule\n')
    files = module_closure(rtl, ['SourceD', 'BankedStore']) + [tb]
    command = [os.environ.get('VERILATOR', 'verilator'),
               '--binary', '--timing', '--assert', '-Wno-fatal', '-j', '4',
               '--top-module', 'tb', '--Mdir', str(out / 'obj'), *map(str, files)]
    with (out / 'compile.log').open('w') as log:
        subprocess.run(command, stdout=log, stderr=subprocess.STDOUT, check=True)
    result = subprocess.run([str(out / 'obj/Vtb')], capture_output=True, text=True, timeout=120)
    (out / 'result.log').write_text(result.stdout + result.stderr)
    assert result.returncode == 0 and 'SOURCED_BANKEDSTORE_PASS' in result.stdout, result.stdout
    (out / 'evidence.json').write_text(json.dumps(dict(status='SOURCED_BANKEDSTORE_PASS',
        build_id=context['dma_load_build_id'], requests=656,
        sources={str(p.relative_to(ROOT)):sha(p) for p in files + [body]}), indent=2) + '\n')
    print(result.stdout)


if __name__ == '__main__':
    main()
