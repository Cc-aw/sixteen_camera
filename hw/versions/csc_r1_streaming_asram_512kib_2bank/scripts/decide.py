#!/usr/bin/env python3
"""Publish the G0 baseline checkpoint; incomplete network evidence fails closed."""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import platform
import re
import sys

ROOT = Path(__file__).resolve().parents[4]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load(path):
    return json.loads(path.read_text()) if path.is_file() else None


def decide(out, context, layers_directory='baseline_layers'):
    policy = load(out / 'decision_policy.json')
    if not policy or policy['physical_implementation_authorized']:
        raise ValueError('Missing pre-registered simulation-only decision policy')
    ctx = load(context)
    inventory = load(out / 'g0/inventory/inventory.json')
    summary = load(out / 'g0/residency/opportunity_summary.json')
    baseline = {}
    for suite, directory, expected in (
        ('layers', layers_directory, 'TRACE_WORKLOAD_PASS'),
        ('asram', 'baseline_asram_retry', 'REAL_GEMMINI_ASRAM_FOUR_ROUTES_PASS'),
        ('fault', 'baseline_fault', 'REAL_GEMMINI_ASRAM_LATE_FAULT_RECOVERY_PASS'),
    ):
        sim = out / directory / 'simulation'
        evidence = load(sim / 'evidence.json')
        log = (sim / 'result.log') if suite == 'layers' else sim / 'simulation/result.log'
        passed = bool(evidence and evidence['status'] == expected and evidence['build_id'] == ctx['dma_load_build_id']
                      and log.is_file() and sha(log) == evidence['log_sha256'])
        baseline[suite] = dict(status='PASS' if passed else 'INCOMPLETE', evidence=evidence)
    missing = [
        'Full-size full-network emitted Mvin/SPAD/EX trace and physical source-generation lifetimes',
        'Single-lane lifecycle trace and native prepared-WS/HOST/Head/PPU boundaries',
        'Legal whole-command exact-resident opportunities and full-network actual DMA denominator',
        'Candidate RTL correctness and same-workload cycle A/B (conditional on G0 PASS)',
    ]
    decision = dict(schema=1, feature='CSC-R1', phase='G0_BASELINE_SIMULATION_CHECKPOINT',
                    base_repository_commit=(out / 'repo_head.txt').read_text().strip(),
                    base_candidate_build_id=ctx['dma_load_build_id'], csc_r1_enabled=False,
                    baseline_simulation=baseline,
                    g0=dict(status='INSUFFICIENT_EVIDENCE', eligible_exact_bytes_pct=None,
                            inventory_status=inventory['status'] if inventory else 'NOT_RUN',
                            lifecycle_status=summary['status'] if summary else 'NOT_RUN',
                            compact_value_only_commands=summary['loads_value_resident_at_issue_without_intervening_writer'] if summary else None),
                    g1=dict(status='NOT_RUN', bit_exact=None, deadlocks=None),
                    g2=dict(status='NOT_RUN', same_workload=None, whole_network_rtl_cycle_accurate=False,
                            measured_stage_cycle_coverage=None, serial_cycles_baseline=None,
                            serial_cycles_candidate=None, parallel_cycles_baseline=None,
                            parallel_cycles_candidate=None, absolute_throughput_gain_pct=None,
                            parallel_scaling_baseline=None, parallel_scaling_candidate=None),
                    missing_evidence=missing, decision='INSUFFICIENT_EVIDENCE',
                    bitstream_generated=False, board_tested=False)
    (out / 'decision.json').write_text(json.dumps(decision, indent=2) + '\n')
    lines = ['# CSC-R1 baseline simulation checkpoint', '',
             '**Decision: INSUFFICIENT_EVIDENCE. G0 has not passed; no candidate RTL is enabled.**', '',
             f"C0 build `{ctx['dma_load_build_id']}`; repository `{decision['base_repository_commit']}`.", '',
             '## Evidence', '']
    lines += [f"- {suite}: {item['status']}" for suite, item in baseline.items()]
    if inventory:
        lines += [f"- Native roundtrip: {inventory['ordinary_stage_count']} ordinary stages, "
                  f"{inventory['ordinary_packets_per_worker']} packets/worker; "
                  f"{inventory['prepared_stage_count']} prepared stage inventories."]
    if summary:
        lines += [f"- Compact trace: {summary['all_mvin_commands']} Mvin commands; "
                  f"{summary['all_tl_get_bytes']} actual TL Get bytes; three lanes, eight stages, read_assembled.",
                  f"- Same-value-at-commit diagnostic: {summary['same_value_bytes_at_commit']} bytes. "
                  'This is not a legal whole-command skip count.',
                  f"- Stable value-at-issue diagnostic: {summary['loads_value_resident_at_issue_without_intervening_writer']} "
                  'commands across three lanes. Source epochs and native dependencies remain unproven; '
                  'this is not a count of eligible skips.']
    lines += ['', '## Scope and decision', '',
              'Existing LoopConv Input loading has no output-channel iterator. Weight COMPUTE_AND_STAY, '
              'native null-operand retention and A1 row grouping are baseline reuse. None is credited to CSC-R1.', '',
              'Compact layers preserve native channels/weights/packing but shrink spatial dimensions. '
              'Their deterministic synthetic inputs do not replay native interstage producer dependencies. '
              'The ASRAM matrix exercises real generated TL controllers and vendor URAM primitives. '
              'These runs do not execute whole-SoC CPU/RVV or the complete model.', '',
              'The parent ASRAM driver initially failed before simulation due to generated Python indentation. '
              'The experiment adapter fixes only the generated driver; the failed attempt is retained.', '',
              'Input/Weight exact-resident counts, full-network TL/SPAD totals and legal saved bytes are unmeasured. '
              'Candidate cycle reductions, FPS, timing and resource changes are unmeasured. '
              'Candidate correctness, new bank conflicts and deadlock behavior have not been assessed.', '',
              '## Remaining evidence', '']
    lines += ['- ' + item for item in missing]
    lines += ['', 'Physical implementation is not justified by this checkpoint. No synthesis, implementation, '
              'bitstream generation or board access was performed.', '']
    (out / 'decision.md').write_text('\n'.join(lines))
    # Bind all compiled sources, including simulation wrappers and vendor models.
    compiled = {}
    environment = dict(python=sys.version, platform=platform.platform(), simulators=[])
    for project in out.rglob('simulation.prj'):
        for name in re.findall(r'"([^\"]+)"', project.read_text()):
            path = Path(name)
            compiled[str(path)] = sha(path)
        options = load(project.parent / 'simulation_options.json')
        xelab_log = project.parent / 'xelab.log'
        warnings = Counter(re.findall(r'WARNING: \[([^]]+)\]', xelab_log.read_text())) if xelab_log.exists() else {}
        version = xelab_log.read_text().splitlines()[0] if xelab_log.exists() else None
        lane_source = project.parent / 'MemoryLane.sv'
        delay_expressions = re.findall(r'response_delay<=([^;]+);', lane_source.read_text()) if lane_source.exists() else []
        environment['simulators'].append(dict(project=str(project), options=options, simulator_version=version,
                                             xelab_warning_codes=dict(warnings), functional_test_only=True,
                                             response_delay_expressions=delay_expressions))
    (out / 'source_rtl_sha256.json').write_text(json.dumps(compiled, indent=2) + '\n')
    (out / 'simulator_environment.json').write_text(json.dumps(environment, indent=2) + '\n')
    (out / 'inputs_manifest.json').write_text(json.dumps(dict(context=str(context), context_sha256=sha(context),
        initial_worktree_sha256=load(out / 'initial_worktree_sha256.json'), policy_sha256=sha(out / 'decision_policy.json')),
        indent=2) + '\n')
    extensions = {'.json', '.csv', '.log', '.py', '.sv', '.svh', '.prj', '.txt', '.md', '.patch', '.c', '.h', '.mem', '.inc'}
    evidence = {str(p.relative_to(out)): sha(p) for p in sorted(out.rglob('*'))
                if p.is_file() and p.suffix in extensions and p.name != 'evidence_manifest.json'
                and 'xsim.dir' not in p.parts}
    (out / 'evidence_manifest.json').write_text(json.dumps(dict(schema=1, sha256=evidence), indent=2) + '\n')
    print('INSUFFICIENT_EVIDENCE: G0 full-network legal residency evidence remains incomplete')
    return 2


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--context', type=Path, required=True)
    parser.add_argument('--layers-directory', default='baseline_layers')
    args = parser.parse_args()
    sys.exit(decide(args.output.resolve(), args.context.resolve(), args.layers_directory))
