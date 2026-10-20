#!/usr/bin/env python3
"""Run frozen parent RTL regressions with experiment-local simulation adapters."""
import argparse
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
from full_gemmini_rtl import vivado_executable

ROOT = Path(__file__).resolve().parents[4]
BASE = ROOT / 'hw/versions/dma_load_streaming_asram_512kib_2bank'
FEATURE = Path(__file__).resolve().parents[1]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def trace_probe():
    spec = importlib.util.spec_from_file_location('parent_spad_trace', BASE / 'scripts/spad_trace.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    text = module.probe().replace('ID==0', 'ID<3')
    text = text.replace('$fopen("spad_events_lane0.csv","w")',
                        '$fopen($sformatf("spad_events_lane%0d.csv",ID),"w")')
    # Separate CSV preserves every raw field rather than guessing instruction packing.
    text += r'''
integer lifecycle_fd,lifecycle_seq=0,packet_seq=0;
initial lifecycle_fd=$fopen($sformatf("lifecycle_lane%0d.csv",ID),"w");
always @(posedge clock)if(!reset && trace_on)begin
  if(cmd_valid && cmd_ready)begin
    if(cmd_funct==15)packet_seq=packet_seq+1;
    $fdisplay(lifecycle_fd,"%0d,%0d,%0d,%0d,%0d,CMD,%0d,%h,%h",
      lifecycle_seq,cycles,layer_case,dma_load_mode,packet_seq,cmd_funct,cmd_rs1,cmd_rs2);
    lifecycle_seq=lifecycle_seq+1;
  end
  if(g_a_valid && g_a_ready)begin
    $fdisplay(lifecycle_fd,"%0d,%0d,%0d,%0d,%0d,TL_A,%0d,%0d,%0d,%h,%h,%h",
      lifecycle_seq,cycles,layer_case,dma_load_mode,packet_seq,g_a_opcode,g_a_source,g_a_size,g_a_address,g_a_mask,g_a_data);
    lifecycle_seq=lifecycle_seq+1;
  end
  if(g_d_valid && g_d_ready)begin
    $fdisplay(lifecycle_fd,"%0d,%0d,%0d,%0d,%0d,TL_D,%0d,%0d,%0d,%0d,%0d,%h",
      lifecycle_seq,cycles,layer_case,dma_load_mode,packet_seq,g_d_opcode,g_d_source,g_d_size,g_d_denied,g_d_corrupt,g_d_data);
    lifecycle_seq=lifecycle_seq+1;
  end
end
'''
    return text


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--suite', choices=('layers', 'asram', 'fault'), required=True)
    parser.add_argument('--context', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--memory-latency', choices=('1', '7'), default='7')
    args = parser.parse_args()
    out = args.output.resolve()
    if out.exists():
        parser.error('Output must be a new directory')
    context = args.context.resolve()
    identity = json.loads(context.read_text())
    if identity.get('hardware_variant') != BASE.name or not identity.get('dma_load_streaming_enable'):
        parser.error('Expected the streaming + ASRAM C0 generation context')
    # Read-only audit fails on any mismatched generated file or source identity.
    subprocess.run([sys.executable, '-B', str(BASE / 'scripts/audit.py'), '--context', str(context)], check=True)
    out.mkdir(parents=True)
    entry = BASE / 'tests' / ('test_layers.py' if args.suite == 'layers' else 'test_asram.py')
    source = entry.read_text()
    adaptations = []
    if args.suite == 'asram':
        # Parent's string insertion has two over-indented lines and also indents
        # the following mode_count statement. Fix the generated Python only.
        old = "        body=body.replace('    $display"
        assert source.count(old) == 1
        source = source.replace(old, "    body=body.replace('    $display")
        old = "    '''+source[pos:]"
        assert source.count(old) == 1
        source = source.replace(old, "'''+source[pos:]")
        adaptations.append('Repair indentation in parent-generated ASRAM driver; no RTL/workload changes')
    if args.suite == 'layers':
        spec = importlib.util.spec_from_file_location('spad_trace', BASE / 'scripts/spad_trace.py')
        probe = importlib.util.module_from_spec(spec)
        probe.probe = trace_probe
        sys.modules['spad_trace'] = probe
        # Trace mode normally runs only legacy/read_assembled. Retain all four
        # modes here so output comparisons and row/Get closure cover the matrix.
        source = source.replace('active=(0,2) if trace else tuple(range(count))', 'active=tuple(range(count))')
        source = source.replace("'runtime_mode=runtime_mode+2'", "'runtime_mode=runtime_mode+1'")
        source = source.replace(".replace('runtime_mode<4','runtime_mode<3')", ".replace('runtime_mode<4','runtime_mode<4')")
        # Keep the ordinary completion marker understood by the Get-closure tool.
        source = source.replace('REAL_TRACE_LAYERS_PASS,mode_ids=0/2,lanes=3', 'REAL_CLUSTER_PASS,DMA_LAYERS=8,modes=4,lanes=3')
        adaptations.append('Three-lane SPAD + physical TL probes, read_assembled trace; four-mode output comparison')
    adapted = out / 'adapted_driver.py'
    adapted.write_text(source)
    tracked = [context, entry, Path(__file__), BASE / 'scripts/spad_trace.py',
               BASE / 'tests/test_real_gemmini.py', BASE / 'tests/asram_sim.py']
    inputs = dict(schema=1, build_id=identity['dma_load_build_id'], adaptations=adaptations,
                  sources={str(p.relative_to(ROOT)): sha(p) for p in tracked},
                  adapted_driver_sha256=sha(adapted), csc_r1_enabled=False,
                  full_model_executed=False, physical_implementation=False)
    (out / 'adapter_manifest.json').write_text(json.dumps(inputs, indent=2) + '\n')
    sys.argv = [str(entry), '--rtl', str(context.parent / 'gen-collateral'), '--output', str(out / 'simulation')]
    if args.suite == 'layers':
        sys.argv += ['--native', str(ROOT / 'sw/board_tests/dma_load_streaming_asram_512kib_2bank/model'),
                     '--trace', '--memory-latency', args.memory_latency]
    elif args.suite == 'fault':
        sys.argv += ['--fault']
    os.environ.setdefault('VIVADO_BIN', str(vivado_executable()))
    namespace = dict(__name__='__main__', __file__=str(entry))
    exec(compile(source, str(adapted), 'exec'), namespace)
    if args.suite == 'layers':
        sim = out / 'simulation'
        traces = [sim / f'{kind}_lane{lane}.csv' for kind in ('spad_events', 'lifecycle') for lane in range(3)]
        if not all(p.is_file() and p.stat().st_size for p in traces):
            raise ValueError('Missing three-lane traces')
        manifest = dict(inputs, scope='Compact eight stages, all four modes, trace mode 2, three lanes; DDR fixture',
                        traces={p.name: sha(p) for p in traces}, probe_sha256=hashlib.sha256(trace_probe().encode()).hexdigest())
        (sim / 'trace_manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
        subprocess.run([sys.executable, '-B', str(ROOT / 'tests/model/dma_load/analyze_traces.py'), str(sim)], check=True)


if __name__ == '__main__':
    main()
