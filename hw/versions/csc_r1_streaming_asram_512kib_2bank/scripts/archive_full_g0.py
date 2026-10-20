#!/usr/bin/env python3
"""Archive reviewable full-G0 results and hashes; keep large traces in build/."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil

FEATURE = Path(__file__).resolve().parents[1]
ROOT = FEATURE.parents[2]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def archive(run, output, execution, rtl_build, calibration, workload):
    decision = json.loads((run / 'decision.json').read_text())
    summary = json.loads((run / 'parallel_residency/opportunity_summary.json').read_text())
    if summary['status'] != 'FULL_RTL_LIFECYCLE_PASS' or not summary['three_lane_coverage']:
        raise ValueError('Only a completed full native audit can enter this archive')
    if decision['csc_r1_enabled'] or decision['bitstream_generated'] or decision['board_tested']:
        raise ValueError('Unexpected candidate/physical state in a G0 archive')
    output.mkdir(parents=True, exist_ok=False)
    copies = {
        'decision.json': 'decision.json', 'decision.md': 'decision.md',
        'decision_policy.json': 'decision_policy.json',
        'evidence_manifest.json': 'evidence_manifest.json',
        'simulator_environment.json': 'simulator_environment.json',
        'workload_coverage.json': 'native_workload_coverage.json',
        'address_coverage.json': 'declared_source_addresses.json',
        'reference_tests.log': 'reference_tests.log',
        'final_parent_check.log': 'parent_source_check.log',
        'address_model_summary.json': 'address_model_summary.json',
        f'{rtl_build}/build_manifest.json': 'full_rtl_build.json',
        f'{execution}/execution_manifest.json': 'execution_manifest.json',
        f'{calibration}/calibration.json': 'compact_physical_write_calibration.json',
        'calibration_commands/calibration.json': 'compact_command_calibration.json',
        'pool75_timeout60000/execution_manifest.json': 'pool75_execution.json',
        'pool75_timeout60000/simulation.log': 'pool75_timeout60000.log',
    }
    for name in ('opportunity_summary.json', 'per_stage_opportunity.csv', 'candidate_examples.csv',
                 'qualified_loads.csv', 'invalidation_reasons.csv', 'elision_model.json'):
        copies['parallel_residency/' + name] = name
    for source, target in copies.items():
        shutil.copyfile(run / source, output / target)
    shutil.copyfile(run / 'single_residency/opportunity_summary.json', output / 'single_control_summary.json')
    shutil.copyfile(output / 'invalidation_reasons.csv', output / 'lifetime_invalidation.csv')
    build = json.loads((run / rtl_build / 'build_manifest.json').read_text())
    (output / 'source_rtl_sha256.json').write_text(json.dumps(build['sha256'], indent=2) + '\n')
    inputs = dict(schema=1, run_directory=str(run), base_commit=decision['base_repository_commit'],
                  initial_state={p.name: sha(p) for p in (run / 'repo_head.txt', run / 'git_status.txt',
                      run / 'dirty.patch', run / 'initial_worktree_sha256.json')},
                  source_blob_manifest=str(run / workload / 'workload.json'),
                  source_blob_manifest_sha256=sha(run / workload / 'workload.json'),
                  functional_memory_blob_sha256=sha(run / 'functional_memory.bin'),
                  source_snapshots=str(run / 'initial_files'))
    (output / 'inputs_manifest.json').write_text(json.dumps(inputs, indent=2) + '\n')
    (output / 'provenance.json').write_text(json.dumps(dict(schema=1,
        raw_traces=summary['lanes'], source_build_manifest=str(run / rtl_build / 'build_manifest.json'),
        runtime_execution_manifest=str(run / execution / 'execution_manifest.json'),
        single_control_reused_from_lane0=decision['single_control_reuses_lane0'],
        accepted_scope='Complete native Gemmini functional work; independent private physical-memory services',
        shared_system_timing_model=False, hardware_sources_modified=False), indent=2) + '\n')
    attempts = []
    for name, reason in (
        ('full_network_single', 'Native default watchdog 10000 rejects legal stage-75 pool5; excluded'),
        ('full_network_parallel', 'Interrupted after diagnosing the default-watchdog issue; excluded'),
        ('full_independent_lanes', 'Interrupted default-watchdog diagnostic lanes; excluded'),
        ('pool75_default', 'Expected default-watchdog reproduction; excluded'),
    ):
        log = run / (name + '.log')
        attempts.append(dict(directory=str(run / name), reason=reason,
                             log_sha256=sha(log) if log.exists() else None))
    (output / 'excluded_attempts.json').write_text(json.dumps(attempts, indent=2) + '\n')
    origins_path = FEATURE / 'manifests/G0_FULL_SOURCE_ORIGINS.json'
    sources = {str(p.relative_to(ROOT)): sha(p) for p in sorted(FEATURE.rglob('*'))
               if p.is_file() and p != origins_path and 'validation' not in p.relative_to(FEATURE).parts
               and '__pycache__' not in p.parts and p.suffix != '.pyc'}
    origins = dict(schema=1, feature='CSC-R1', phase='G0_FULL_NATIVE_FUNCTIONAL',
                   baseline_build_id=decision['base_candidate_build_id'], files=sources)
    origins_path.write_text(json.dumps(origins, indent=2) + '\n')
    shutil.copyfile(origins_path, output / 'current_source_origins.json')
    t = summary['totals']
    recommendation = ('建议下一阶段先验证最小 C1a Input 原型；有界描述符能覆盖多少机会及真实周期收益仍须 G1/G2。'
                      if decision['g0']['status'] == 'PASS' else
                      'G0 未过门槛，保持 R1 关闭；按 decision.md 补齐证据或停止该原型方向。')
    text = f'''# CSC-R1 完整 G0 仿真评估

基线：`{decision['base_candidate_build_id']}`，HEAD：`{decision['base_repository_commit']}`。

**G0：{decision['g0']['status']}。物理实现决策：{decision['decision']}；G1/G2 尚未执行。**

- 三路、每路连续两帧，原生 166 个非终止阶段；每路每帧 462 个 Conv 包、224 个 WS 包及 5 个 memory kernel。
- 实际 Mvin：{t['all_mvin_commands']:,}；实际 Get：{t['all_tl_get_requests']:,} 次、{t['all_tl_get_bytes']:,} 字节。
- 通过源版本、完整提交、同址同布局和无覆盖核验的完整 Load：{t['eligible_exact_mvin_commands']:,}；对应 Get 字节 {t['eligible_exact_get_bytes']:,}，占 {decision['g0']['eligible_exact_bytes_pct']:.6f}%。
- Input 单独对应 {decision['g0']['input_exact_bytes_pct']:.6f}%，Weight 对应 {decision['g0']['weight_exact_bytes_pct']:.6f}%；零填充命中不计入 Get 字节。
- 独立固定时序删除模型省略全部合格 Load 的写入后，每次真实 SRAM 读仍逐字节一致；原信用/完成时间保留。

这些是 C0 中已证明的数据复用机会，尚非候选 RTL 的实际省略数或周期提速。
功能内存服务为每路私有，不包含共享 DDR/ASRAM 仲裁、CPU/RVV 与 PPU 时间；不报告 FPS。
lane 0 同时作为单路功能对照，明确复用同一证据，不构成单路/三路吞吐对照。

原生 `gemmini_timeout=10000` 会拒绝合法长池化；隔离复现以现有
`+gemmini_timeout=60000` 正常完成，保留所有 RTL 断言。失败/中止诊断均被排除。
原 96 项四模式紧凑层、288 项实际 ASRAM/URAM 及晚到错误/复位证据仍在 `../g0/`，不改写旧归档。

{recommendation}
未综合、未布局布线、未生成 bitstream、未访问 FPGA，也未修改正式 SoC 或父候选。

完整决策见 [decision.md](decision.md)，逐阶段统计见 [per_stage_opportunity.csv](per_stage_opportunity.csv)。
原始日志、输入、生成包装及完整 trace 保留在 `{run.relative_to(ROOT) if run.is_relative_to(ROOT) else run}`。
`archive_sha256.json` 绑定本目录；`current_source_origins.json` 对应完整 G0 源码，
原 `manifests/SOURCE_ORIGINS.json` 保留首轮紧凑检查点的历史身份。
'''
    (output / 'README.md').write_text(text)
    (output / 'archive_sha256.json').write_text(json.dumps({p.name: sha(p) for p in sorted(output.iterdir()) if p.is_file()}, indent=2) + '\n')
    print('FULL_G0_ARCHIVED', output)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--run', type=Path, required=True)
    parser.add_argument('--output', type=Path, default=FEATURE / 'validation/g0_full')
    parser.add_argument('--execution', default='full_complete_lanes')
    parser.add_argument('--rtl-build', default='full_rtl_complete_serial')
    parser.add_argument('--calibration', default='calibration_serial_complete')
    parser.add_argument('--workload', default='workload_05')
    args = parser.parse_args()
    archive(args.run.resolve(), args.output.resolve(), args.execution, args.rtl_build, args.calibration, args.workload)
