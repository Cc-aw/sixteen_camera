#!/usr/bin/env python3
"""Build C1a OFF/ON in the same complete real Gemmini simulation binary."""
import argparse
import json
from pathlib import Path
import shutil
import subprocess
import sys

from candidate_rtl import sha, once
from full_command_rtl import closure, FEATURE
from full_gemmini_rtl import wrapper


def build(context, reference, out):
    candidate = json.loads(context.read_text())
    baseline = json.loads((reference / 'build_manifest.json').read_text())
    if candidate['parent_build_id'] != baseline['build_id']:
        raise ValueError('Wrong reference RTL build')
    rtl = context.parent / 'gen-collateral'
    for name, digest in candidate['final_rtl_sha256'].items():
        if sha(rtl / name) != digest:
            raise ValueError('Candidate snapshot changed: ' + name)
    for name, digest in candidate['overlay_sources_sha256'].items():
        if sha(Path(name)) != digest:
            raise ValueError('Overlay source changed; prepare a new candidate: ' + name)
    primitive = reference / 'RAMB36E2_functional.v'
    glbl = next(Path(p) for p in baseline['sha256'] if p.endswith('/glbl.v'))
    for path in (primitive, glbl):
        if sha(path) != baseline['sha256'][str(path)]:
            raise ValueError('Reference primitive changed: ' + str(path))
    out.mkdir(parents=True, exist_ok=False)
    top = out / 'FullGemmini.sv'
    text = wrapper(rtl)
    text = once(text, 'module FullGemmini(', '''module FullGemmini(
input wire csc_enabled,
input wire csc_clear,
output wire csc_accept,csc_skip,csc_done,csc_supported,csc_half,csc_wait,
output wire [231:0] csc_key,
output wire [14:0] csc_rows,
''')
    for name in ('csc_enabled', 'csc_clear'):
        text = once(text, f'.{name}(\'0)', f'.{name}({name})')
    text = once(text, 'endmodule', '''assign csc_accept=dut.mod.csc_accepted;
assign csc_skip=dut.mod.csc_skipped;
assign csc_done=dut.mod.csc_completion;
assign csc_supported=dut.mod.csc_supported;
assign csc_half=dut.mod.csc_addr_start[13];
assign csc_key=dut.mod.csc_key;
assign csc_rows=dut.mod.csc_row_count[14:0];
assign csc_wait=dut.mod.csc_wait;
endmodule''')
    top.write_text(text)
    original_driver = FEATURE / 'tests/csc_gemmini_driver.cpp'
    driver = out / original_driver.name
    shutil.copyfile(original_driver, driver)
    sources = closure(rtl, ('Gemmini',)) + [primitive, glbl]
    # The closure scanner intentionally matches simple generated instantiations;
    # our source module uses the same style, without a parameter override.
    if rtl / 'CscR1InputResidency.sv' not in sources:
        raise ValueError('Missing CSC RTL in closure')
    prefix = Path(sys.executable).resolve().parents[1]
    cflags, ldflags = '-O2 -std=c++17', '-lz'
    if (prefix / 'include/zlib.h').is_file():
        cflags += ' -I' + str(prefix / 'include')
        ldflags = f'-L{prefix}/lib -Wl,-rpath,{prefix}/lib -lz'
    command = ['verilator', '--cc', '--exe', '--build', '--assert', '--timing', '-Wno-fatal',
               '--top-module', 'FullGemmini', '--Mdir', str(out / 'obj'), '-j', '4',
               '-CFLAGS', cflags, '-LDFLAGS', ldflags, str(top), *map(str, sources), str(driver)]
    (out / 'compile_command.json').write_text(json.dumps(command, indent=2) + '\n')
    with (out / 'compile.log').open('w') as log:
        subprocess.run(command, stdout=log, stderr=subprocess.STDOUT, check=True)
    inputs = [context, reference / 'build_manifest.json', top, driver, original_driver,
              Path(__file__).resolve(), *sources]
    (out / 'build_manifest.json').write_text(json.dumps(dict(
        schema=1, status='C1A_FULL_RTL_BUILT', build_id=candidate['parent_build_id'],
        csc_runtime_switch=True, performance_model=False, production_export=False,
        sha256={str(p): sha(p) for p in inputs}), indent=2) + '\n')
    print('CSC_C1A_FULL_RTL_BUILT', out)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--context', type=Path, required=True)
    parser.add_argument('--reference-build', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    build(args.context.resolve(), args.reference_build.resolve(), args.output.resolve())
