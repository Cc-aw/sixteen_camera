#!/usr/bin/env python3
"""Evaluate the frozen G0 byte gate; do not promote G0 into physical GO."""
import argparse
import hashlib
import json
from pathlib import Path
import platform
import subprocess
import sys

FEATURE = Path(__file__).resolve().parents[1]


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def read(path):
    return json.loads(path.read_text()) if path.is_file() else None


def decide(run, workload, rtl_build, calibration='calibration_full', single='single_residency', parallel='parallel_residency'):
    policy = read(run / 'decision_policy.json')
    reference_policy = read(FEATURE / 'manifests/decision_policy.json')
    if policy != reference_policy or policy['physical_implementation_authorized']:
        raise ValueError('Missing or changed preregistered simulation-only policy')
    build = read(run / rtl_build / 'build_manifest.json')
    coverage = read(run / 'workload_coverage.json')
    compact = read(run / calibration / 'calibration.json')
    control = read(run / single / 'opportunity_summary.json')
    network = read(run / parallel / 'opportunity_summary.json')
    elision = read(run / parallel / 'elision_model.json')
    missing = []
    if not build or build.get('status') != 'FULL_GEMMINI_RTL_BUILT':
        missing.append('Hash-bound complete C0 RTL build')
    else:
        for name, expected in build['sha256'].items():
            if not Path(name).is_file() or digest(Path(name)) != expected:
                raise ValueError('Build source hash mismatch: ' + name)
    if not coverage or coverage['status'] != 'WHOLE_NATIVE_WORKLOAD_COVERAGE_PASS':
        missing.append('Full native Conv/WS/memory-kernel command coverage')
    if not compact or compact['status'] != 'FULL_RTL_COMPACT_WRITE_CALIBRATION_PASS':
        missing.append('Physical bank/row/mask/processed-byte calibration against XSim')
    for name, summary, lanes in [('single', control, 1), ('parallel', network, 3)]:
        if not summary or summary['status'] != 'FULL_RTL_LIFECYCLE_PASS' or len(summary['lanes']) != lanes:
            missing.append(name + ': complete double-frame physical read/write/credit/epoch audit')
        elif not summary.get('zero_write_ownership_proven'):
            missing.append(name + ': real zero-write owner capture')
        else:
            for path, expected in summary['analysis_sources_sha256'].items():
                if digest(Path(path)) != expected:
                    raise ValueError('Auditor changed after analysis: ' + path)
            for record in summary['lanes']:
                if digest(Path(record['trace'])) != record['trace_sha256']:
                    raise ValueError('Audited physical trace hash mismatch')
    if not elision or elision['status'] != 'FIXED_TIMELINE_WHOLE_LOAD_ELISION_MODEL_PASS' or not elision['complete_native_command_workload']:
        missing.append('Independent whole-Load deletion replay preserving every real SRAM read and original completion token')
    else:
        if elision['summary_sha256'] != digest(run / parallel / 'opportunity_summary.json'):
            raise ValueError('Deletion replay belongs to a different physical audit')
        if elision['validator_sha256'] != digest(Path(elision['validator_source'])):
            raise ValueError('Deletion validator changed after replay')
    byte_fraction = None
    g0 = 'INSUFFICIENT_EVIDENCE'
    decision = 'INSUFFICIENT_EVIDENCE'
    reason = 'FULL_BASELINE_EVIDENCE_INCOMPLETE'
    if not missing:
        actual = network['totals']['all_tl_get_bytes']
        eligible = network['totals']['eligible_exact_get_bytes']
        if not actual or eligible > actual:
            raise ValueError('Invalid actual/eligible TL byte totals')
        byte_fraction = eligible / actual
        if byte_fraction >= policy['g0']['exact_dma_read_fraction_min']:
            g0 = 'PASS'
            reason = 'QUALIFIED_WHOLE_LOAD_BYTE_GATE_MET'
        elif network['totals']['eligible_exact_mvin_commands'] == 0:
            g0 = 'NO_GO'
            decision = 'NO_GO'
            reason = 'NO_GO_DUPLICATE_LOAD_NOT_FOUND_FOR_EXACT_SIGNATURE_PROFILE'
        else:
            reason = 'BYTE_GATE_NOT_MET_AND_WHOLE_SYSTEM_HOTSPOT_GATE_UNPROVEN'
            missing.append('Full-network time weights and a demonstrated recoverable input-stall hotspot; functional direct-memory cycles alone do not establish this gate')
    g0_reason = reason
    physical_missing = []
    if g0 == 'PASS':
        reason = 'G0_PASS_CANDIDATE_G1_G2_NOT_RUN'
        physical_missing = ['G1: implemented candidate, numerical outputs and completion/fault/reset proof',
                            'G2: matched candidate cycle A/B, shared-system timing and throughput evidence']
    result = dict(schema=1, feature='CSC-R1', base_repository_commit=(run / 'repo_head.txt').read_text().strip(),
        base_candidate_build_id=build['build_id'] if build else None, csc_r1_enabled=False,
        g0=dict(status=g0, reason=g0_reason, missing_evidence=missing,
                eligible_exact_bytes_pct=None if byte_fraction is None else byte_fraction * 100,
                input_exact_bytes_pct=None if not network else network['totals']['input_eligible_exact_get_bytes'] / network['totals']['all_tl_get_bytes'] * 100,
                weight_exact_bytes_pct=None if not network else network['totals']['weight_eligible_exact_get_bytes'] / network['totals']['all_tl_get_bytes'] * 100,
                byte_threshold_pct=policy['g0']['exact_dma_read_fraction_min'] * 100,
                hotspot_gate='NOT_REQUIRED_BYTE_GATE_MET' if g0 == 'PASS' else 'NOT_PROVEN', native_workload='166 stages, 462 Conv + 224 WS packets and 5 memory kernels per lane/frame',
                proof_scope='Whole-Load exact signatures in the functional C0 baseline; actual SPAD bytes, source versions, pending writers and retirement'),
        g1=dict(status='NOT_RUN', bit_exact=None, deadlocks=None),
        g2=dict(status='NOT_RUN', whole_network_rtl_cycle_accurate=False,
                measured_stage_cycle_coverage=None, absolute_throughput_gain_pct=None),
        decision=decision, reason=reason, missing_evidence=missing + physical_missing,
        single_control_reuses_lane0=bool(control and network and control['lanes'][0]['trace_sha256'] == network['lanes'][0]['trace_sha256']),
        next_action='Implement and validate C1a Input exact reuse first; evaluate C1b separately only if justified' if g0 == 'PASS' else 'Keep R1 disabled; resolve remaining gate evidence before any candidate implementation',
        bitstream_generated=False, board_tested=False)
    for name in ('decision.json', 'decision.md', 'evidence_manifest.json'):
        if (run / name).exists():
            raise ValueError('Decision output already exists: ' + name)
    (run / 'decision.json').write_text(json.dumps(result, indent=2) + '\n')
    lines = ['# CSC-R1 full G0 feasibility evaluation', '',
             f'G0: **{g0}**. Final physical-prototype decision: **{decision}**.', '',
             f'Reason: `{reason}`.', '',
             'The baseline is frozen streaming + ASRAM C0. Existing LoopConv input reuse, native null-operand retention, WS/B reuse and A1 request grouping are already included. No candidate skip controller is enabled.', '']
    if network:
        t = network['totals']
        lines += [f"Full trace: {t['all_mvin_commands']:,} Mvin, {t['all_tl_get_bytes']:,} actual TL Get bytes; "
                  f"{t['eligible_exact_mvin_commands']:,} qualified whole-Load opportunities and {t['eligible_exact_get_bytes']:,} attributed Get bytes.", '',
                  f"Eligible read fraction: {100 * network['eligible_exact_bytes_fraction']:.6f}% (preregistered byte gate: 5%).", '',
                  'These are baseline residency opportunities, not measured candidate savings or a throughput improvement. An unbounded descriptor catalogue is used; a small hardware implementation may realize less.', '']
    lines += ['The functional harness executes actual C0 RS/EX/DMA/FP16/SPAD logic with private physical-memory services. '
              'All three lane identities and native activation aliases are retained. It does not model shared DDR/ASRAM timing, CPU instruction cost or PPU completion. '
              'Stage cycle and operand-wait counters are accelerator-only diagnostics and cannot establish full-system FPS.', '',
              'The default native 10,000-cycle pipeline watchdog rejected a legal SPPF pool5 operation. '
              'An isolated native replay completed with `+gemmini_timeout=60000`; all RTL assertions remain enabled. '
              'Failed default-timeout and interrupted diagnostic runs are excluded from accepted comparisons.', '',
              'Whole descriptors require matching source bytes/generations, shape/layout/scale and physical target bytes, full prior SRAM commit/credit/ROB completion, '
              'no pending or intervening overlapping writer, and individually idempotent candidate commits. Frames invalidate descriptors. '
              'HOST pad and actual masked Put writes update physical-byte generations. Same-source/different-destination remains an R2 diagnostic.', '',
              'G1 replacement completion semantics, whole-network numerical oracle, fault/reset behavior, descriptor hardware cost and G2 matched A/B cycles remain untested. '
              'G0 PASS would authorize further simulation implementation only; it never authorizes a physical build.', '']
    if missing or physical_missing:
        lines += ['Remaining evidence:', ''] + ['- ' + item for item in missing + physical_missing] + ['']
    lines += ['No synthesis, implementation, bitstream generation or FPGA access was performed.', '']
    (run / 'decision.md').write_text('\n'.join(lines))
    inputs = [run / 'decision_policy.json', run / 'workload_coverage.json', run / workload / 'workload.json',
              run / workload / 'native_commands.txt', run / rtl_build / 'build_manifest.json',
              run / calibration / 'calibration.json']
    for scope in (single, parallel):
        inputs += sorted((run / scope).glob('*')) if (run / scope).exists() else []
    for filename in ('full_trace_schema.md', 'full_lifecycle.py', 'analyze_full.py', 'validate_workload.py'):
        inputs.append(FEATURE / 'analysis' / filename)
    inputs += [Path(__file__), run / 'decision.json', run / 'decision.md']
    evidence = {str(p): digest(p) for p in inputs if p.is_file()}
    (run / 'evidence_manifest.json').write_text(json.dumps(dict(schema=1, files=evidence,
        raw_trace_digests='Bound in each audited opportunity_summary lane record and the functional aggregation manifest'), indent=2) + '\n')
    environment = dict(python=sys.version, platform=platform.platform(),
        verilator=subprocess.check_output(['verilator', '--version'], text=True).strip(),
        rtl_threads=build.get('verilator_threads') if build else None,
        runtime_mode='read_assembled', pipeline_watchdog=60000,
        physical_memory_service='Independent deterministic private services; no shared-system timing')
    (run / 'simulator_environment.json').write_text(json.dumps(environment, indent=2) + '\n')
    print('G0=' + g0, 'decision=' + decision)
    return 0 if g0 in ('PASS', 'NO_GO') else 2


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--run', type=Path, required=True)
    parser.add_argument('--workload', default='whole_workload')
    parser.add_argument('--rtl-build', default='full_rtl')
    parser.add_argument('--calibration', default='calibration_full')
    parser.add_argument('--single', default='single_residency')
    parser.add_argument('--parallel', default='parallel_residency')
    args = parser.parse_args()
    sys.exit(decide(args.run.resolve(), args.workload, args.rtl_build, args.calibration, args.single, args.parallel))
