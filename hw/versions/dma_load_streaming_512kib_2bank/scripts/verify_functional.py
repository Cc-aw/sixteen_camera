#!/usr/bin/env python3
"""Gate the private bitstream on real A1 functional evidence; timing is delegated."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import sys

FEATURE = Path(__file__).resolve().parents[1]
ROOT = FEATURE.parents[2]
sys.path.insert(0, str(ROOT / 'tools/build'))
from verify_dma_load import integration


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--context', type=Path, required=True)
    parser.add_argument('--units', type=Path, required=True)
    parser.add_argument('--integration', type=Path, required=True)
    parser.add_argument('--spad', type=Path, help='Override the SPAD result directory')
    parser.add_argument('--fault', type=Path, help='Override the fault result directory')
    parser.add_argument('--firmware', type=Path, required=True)
    parser.add_argument('--trace-manifest', type=Path, required=True)
    parser.add_argument('--combining', type=Path, required=True)
    parser.add_argument('--micro', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    context = json.loads(args.context.read_text())
    origins=FEATURE/'manifests/SOURCE_ORIGINS.json'
    if context.get('feature_source_origins_sha256')!=hashlib.sha256(origins.read_bytes()).hexdigest():
        raise ValueError('Candidate feature source provenance changed')
    if (context.get('hardware_variant') != 'dma_load_streaming_512kib_2bank' or
            not context.get('dma_load_streaming_enable') or
            context.get('dma_load_pipeline_version') != 'row_ready_v1' or
            context.get('dma_load_cross_command_write_combining_enable') or
            len(context.get('dma_load_supported_modes', [])) != 4):
        raise ValueError('Wrong streaming candidate')
    dirs = {name: args.integration / name for name in ('first', 'layers', 'spad', 'fault', 'memory')}
    if args.spad:
        dirs['spad'] = args.spad
    if args.fault:
        dirs['fault']=args.fault
    report = integration(args.context, dirs)
    hashes = report['sha256']

    def record(path):
        path = Path(path).resolve()
        hashes[str(path)] = hashlib.sha256(path.read_bytes()).hexdigest()
        return path

    # The simulator project lists translation units, while includes and input
    # memories also determine the executed workload. Freeze those for the
    # synthesis handoff, including nested feature/ConvWorkload.svh files.
    for directory in [*dirs.values(), args.trace_manifest.resolve().parent]:
        for path in Path(directory).rglob('*'):
            if path.is_file() and path.suffix in ('.svh', '.vh', '.mem', '.hex'):
                record(path)

    units = json.loads(record(args.units / 'unit_evidence.json').read_text())
    if units['status'] != 'SOURCE_UNIT_PASS':
        raise ValueError('Source units did not pass')
    tested = {Path(name).name for name in units['source_sha256']}
    if not {'GemminiConfigs.scala', 'Configs.scala', 'DMA.scala', 'Scratchpad.scala',
            'DmaLoadGroup.scala', 'DmaLoadStreamingTest.scala'} <= tested:
        raise ValueError('Changed definitions/callers were resolved from an old jar')
    for name, expected in units['source_sha256'].items():
        if hashlib.sha256(record(ROOT / name).read_bytes()).hexdigest() != expected:
            raise ValueError('Tested source changed: ' + name)
    jar = record(Path(units['workspace']) / '.classpath_cache/chipyard_fpga.jar')
    if hashes[str(jar)] != units['classpath_jar_sha256']:
        raise ValueError('Unit dependency jar changed')
    for name, markers in [('unit.log', ('PLANNER', 'ASSEMBLER', 'GROUP', 'BANK_QUEUE', 'COUNTER_ABI', 'CONTROL')),
                          ('reader.log', ('READER',)), ('streaming.log', ('STREAMING',))]:
        log = record(args.units / name).read_text()
        if re.search(r'Assertion failed:|Exception|Fatal:', log):
            raise ValueError('Failed source unit log')
        if any('DMA_LOAD_' + marker + '_PASS,' not in log for marker in markers):
            raise ValueError('Missing source unit coverage')
    stream = (args.units / 'streaming.log').read_text()
    cases = re.findall(r'DMA_LOAD_STREAMING_CASE_PASS,streaming=(true|false),mode=(\d),c=(\d+),fault=(\d),early_rows=(\d+)', stream)
    expected = {(on, mode, c, fault) for on in ('true', 'false') for mode in (1, 2, 3)
                for c in (3, 12) for fault in range(5 if on == 'true' else 1)}
    if {(on, int(mode), int(c), int(fault)) for on, mode, c, fault, _ in cases} != expected:
        raise ValueError('Incomplete delayed-return/late-fault matrix')
    if any((int(early) > 0) != (on == 'true') for on, _, _, _, early in cases):
        raise ValueError('Streaming/buffered controls did not differ at the return barrier')
    spad = (dirs['spad'] / 'result.log').read_text()
    early = re.findall(r'DMA_STREAMING_SPAD_PASS,lane=(\d),mode=(\d),case=(\d),early_rows=(\d+),early_sram_writes=(\d+)', spad)
    if len(early) != 18 or {(int(l), int(m), int(c)) for l, m, c, _, _ in early} != {
            (l, m, c) for l in range(3) for m in (1, 2, 3) for c in (0, 3)}:
        raise ValueError('Missing real early-SPAD-write proof')
    if any(int(rows) <= 0 or int(writes) <= 0 for _, _, _, rows, writes in early):
        raise ValueError('Real SPAD remained behind the all-return barrier')
    if (dirs['fault']/'result.log').read_text().count('partial_sram_delta=checked')!=2:
        raise ValueError('Both fault kinds must follow actual new partial SRAM writes')
    firmware = json.loads(record(args.firmware).read_text())
    if firmware.get('status') != 'ELF_AUDIT_PASS' or firmware.get('build_id') != context['dma_load_build_id']:
        raise ValueError('Wrong diagnostic ELF identity')
    for field in ('sha256', 'files'):
        for name, expected in firmware.get(field, {}).items():
            expected = expected['sha256'] if isinstance(expected, dict) else expected
            if hashlib.sha256(record(name).read_bytes()).hexdigest() != expected:
                raise ValueError('Diagnostic input changed')
    micro=json.loads(record(args.micro).read_text())
    if micro.get('status')!='RTL_MICRO_COMPARISON_PASS' or micro.get('streaming_build_id')!=context['dma_load_build_id']:
        raise ValueError('Missing/wrong identical-work RTL micro comparison')
    for name,expected in micro['sha256'].items():
        if hashlib.sha256(record(name).read_bytes()).hexdigest()!=expected:
            raise ValueError('Micro comparison source/result changed')
    trace_manifest = json.loads(record(args.trace_manifest).read_text())
    combining = json.loads(record(args.combining).read_text())
    trace = record(trace_manifest['trace'])
    trace_dir=args.trace_manifest.resolve().parent
    for field,path in (('probe_sha256',FEATURE/'scripts/spad_trace.py'),
                       ('simulation_project_sha256',trace_dir/'simulation.prj'),
                       ('workload_sha256',trace_dir/'feature/ConvWorkload.svh')):
        if hashlib.sha256(record(path).read_bytes()).hexdigest()!=trace_manifest[field]:
            raise ValueError('Trace capture source changed: '+str(path))
    trace_log=record(trace_dir/'result.log').read_text()
    if 'REAL_TRACE_LAYERS_PASS,mode_ids=0/2,lanes=3' not in trace_log:
        raise ValueError('Trace workload did not finish')
    trace_project=(trace_dir/'simulation.prj').read_text()
    for name in re.findall(r'^sv work "([^\"]+)"$',trace_project,re.M):
        record(name)
    if (trace_manifest['build_id'] != context['dma_load_build_id'] or
            trace_manifest['trace_sha256'] != hashes[str(trace)] or
            combining.get('status') != 'FINITE_WINDOW_ANALYSIS_PASS' or
            combining.get('trace_sha256') != hashes[str(trace)] or
            combining.get('decision') != 'DEFER_B2'):
        raise ValueError('Wrong/incomplete trace opportunity evidence')
    record(origins)
    for name in ('scripts/build_soc.py','scripts/verify_functional.py','scripts/audit.py','scripts/spad_trace.py','scripts/analyze_combining.py'):
        record(FEATURE/name)
    report.update(status='READY_FOR_BITSTREAM', full_chip_timing_proven=False,
                  timing_validation='DELEGATED_BY_USER', board_run='NOT_RUN',
                  scope='A1 four-mode real RTL, early SRAM writes, late faults, source units, audited ELFs, compact trace and finite-window analysis',
                  a2='DEFERRED_PENDING_PERFORMANCE_EVIDENCE', b2='DEFERRED_INVESTMENT_GATE_NOT_MET')
    args.output.write_text(json.dumps(report, indent=2) + '\n')
    print('STREAMING_FUNCTIONAL_ACCEPTANCE_PASS build_id=' + context['dma_load_build_id'])


if __name__ == '__main__':
    main()
