#!/usr/bin/env python3
"""Accept and archive the Store-wait regression; never grant a physical GO."""
import argparse
import difflib
import json
from pathlib import Path
import shutil

from candidate_rtl import sha

FEATURE = Path(__file__).resolve().parents[1]


def archive(run, prior, context, build, destination):
    if destination.exists() or (run / 'optimized_decision.json').exists():
        raise FileExistsError('Use a new archive/run; accepted evidence is immutable')
    evidence = {}

    def read(path, status='PASS'):
        value = json.loads(path.read_text())
        if status is not None and value.get('status') != status:
            raise ValueError('Failed or incomplete evidence: ' + str(path))
        for name, digest in value.get('sha256', {}).items():
            if sha(Path(name)) != digest:
                raise ValueError('Evidence input changed: ' + name)
        evidence[str(path)] = sha(path)
        return value

    for suite in ('smoke', 'regression', 'network'):
        value = read(run / (suite + '_result.json'))
        for step in value['steps']:
            if step['returncode'] or sha(Path(step['log'])) != step['log_sha256']:
                raise ValueError('Failed/changed regression step: ' + step['name'])
    candidate = read(context, 'EXPERIMENTAL_C1A_GENERATED_RTL_OVERLAY')
    if candidate['parent_build_id'] != 'abd1c8c87558c7b0':
        raise ValueError('Wrong frozen C0 parent')
    for field in ('parent_rtl_sha256', 'overlay_sources_sha256'):
        for name, digest in candidate[field].items():
            if sha(Path(name)) != digest:
                raise ValueError('Candidate input changed: ' + name)
    if sha(Path(candidate['parent_context'])) != candidate['parent_context_sha256']:
        raise ValueError('Parent context changed')
    read(build / 'build_manifest.json', 'C1A_FULL_RTL_BUILT')
    mirror = read(run / 'build_mirror.json')
    if not mirror['sha256_by_relative_path']:
        raise ValueError('Compiled model was not preserved')
    unit = (run / 'unit_final.log').read_text()
    for expected in ('CSC_R1_UNIT_PASS checks=303', 'CSC_STORE_DISJOINT_PASS checks=18',
                     'Ran 6 tests', 'Ran 11 tests'):
        if expected not in unit:
            raise ValueError('Missing unit check: ' + expected)
    if unit.count('\nOK\n') != 2:
        raise ValueError('Python unit tests did not pass')
    if 'PRODUCTION_MANIFEST=PASS' not in (run / 'parent_check.log').read_text():
        raise ValueError('Production manifest check did not pass')
    if (run / 'g0_regression.log').read_text().count('\nOK\n') != 3:
        raise ValueError('G0 reference regressions did not pass')
    read(run / 'generator/result.json')
    contract = read(run / 'store_bound_contract.json')
    if sum(case['native_conv_packets'] for case in contract['cases']) != 2938:
        raise ValueError('Frozen output-channel bound coverage incomplete')
    disabled = read(run / 'disabled_identity.json')
    if disabled['events_compared'] != 411621 or not disabled['exact_cycles']:
        raise ValueError('Disabled identity is incomplete')
    fullsize = read(run / 'fullsize_comparison/comparison.json')
    if fullsize['candidate']['skipped'] <= 0:
        raise ValueError('No actual full-size reuse')
    acc = [read(run / (name + '_acc_comparison.json')) for name in ('fullsize', 'directed')]
    mapping = {
        'candidate_context.json': context, 'rtl_build.json': build / 'build_manifest.json',
        'unit_checks.log': run / 'unit_final.log', 'parent_check.log': run / 'parent_check.log',
        'g0_regression.log': run / 'g0_regression.log', 'generator.json': run / 'generator/result.json',
        'disabled_identity.json': run / 'disabled_identity.json',
        'fullsize_numerical.json': run / 'fullsize_comparison/comparison.json',
        'fullsize_simulation.log': run / 'fullsize_on/lane0.log',
        'fullsize_execution.json': run / 'fullsize_on/execution_manifest.json',
        'accumulator_fullsize.json': run / 'fullsize_acc_comparison.json',
        'accumulator_directed.json': run / 'directed_acc_comparison.json',
        'store_hazard_fixture.json': run / 'store_hazard_fixture/fixture.json',
        'previous_summary.json': prior / 'g1_summary.json',
        'whole_execution.json': run / 'network_on/execution_manifest.json',
        'whole_execution_result.json': run / 'network_on/execution_result.json',
        'compile_environment.json': run / 'compile_environment.json',
        'initial_snapshot.json': run / 'initial_snapshot.json',
        'relocation.json': run / 'relocation.json',
        'store_bound_contract.json': run / 'store_bound_contract.json',
        'build_mirror.json': run / 'build_mirror.json',
    }
    for mode in range(4):
        read(run / f'mode{mode}_on/execution_result.json')
        read(run / f'mode{mode}_on/execution_manifest.json', None)
        for lane in range(3):
            path = run / f'mode{mode}_comparison_lane{lane}/comparison.json'
            value = read(path)
            if value['candidate']['skipped'] != 9 or value['candidate']['tiles'] != 12:
                raise ValueError('Incomplete four-mode coverage')
            mapping[f'mode{mode}_lane{lane}.json'] = path
    for lane in range(3):
        for case, skips in (('config_hazard', 3), ('store_hazard', 0)):
            path = run / f'{case}_comparison_lane{lane}/comparison.json'
            value = read(path)
            if value['candidate']['tiles'] != 12 or value['candidate']['skipped'] != skips:
                raise ValueError('Missing hazard coverage: ' + case)
            mapping[f'{case}_lane{lane}.json'] = path
        path = run / f'store_hazard_identity_lane{lane}.json'
        read(path)
        mapping[path.name] = path
    for start in (0, 2):
        path = run / f'mode_switch_{start}/result.json'
        read(path)
        mapping[f'mode_switch_{start}.json'] = path
    for kind in ('denied', 'corrupt'):
        path = run / f'fault_{kind}/fault_result.json'
        value = read(path)
        if not value['late_fault_detected'] or not value['reset_recovery']:
            raise ValueError('Fault/reset coverage missing')
        mapping[f'fault_{kind}.json'] = path
        path = run / f'fault_{kind}_comparison/comparison.json'
        read(path)
        mapping[f'fault_{kind}_numerical.json'] = path
        mapping[f'fault_{kind}.log'] = run / f'fault_{kind}/simulation.log'
    old_archive = FEATURE / 'validation/g1'
    old_sha = json.loads((old_archive / 'archive_sha256.json').read_text())
    for name, digest in old_sha.items():
        if sha(old_archive / name) != digest:
            raise ValueError('Previous G1 archive changed: ' + name)
    if sha(prior / 'g1_summary.json') != old_sha['summary.json']:
        raise ValueError('Previous timing summary is not the accepted G1 summary')
    evidence[str(old_archive / 'archive_sha256.json')] = sha(old_archive / 'archive_sha256.json')
    previous = read(prior / 'g1_summary.json')
    lanes, comparisons = [], []
    for lane in range(3):
        path = run / f'network_comparison_lane{lane}/comparison.json'
        value = read(path)
        comparisons.append(value)
        mapping[f'whole_lane{lane}.json'] = path
        path = run / f'transactions_lane{lane}/transactions.json'
        ledger = read(path)
        totals = ledger['totals']
        for counter, observed in (('get_bytes', 'get_bytes'), ('bank_commits', 'commits'),
                                  ('skipped_tiles', 'skipped'), ('replacement_completions', 'completions')):
            if totals[counter] != value['candidate'][observed]:
                raise ValueError('Independent ledgers disagree: ' + counter)
        for key, expected in (('native_words', 11049), ('input_tiles', 462),
                              ('weight_mvin_commands', 3595), ('bias_mvin_commands', 17325),
                              ('weight_get_bytes', 5015808), ('bias_get_bytes', 1857600)):
            if totals[key] != expected:
                raise ValueError('Workload/traffic changed: ' + key)
        before = previous['functional_timing_diagnostic']['lanes'][lane]
        baseline = before['baseline_functional_cycles']
        current = totals['functional_cycles']
        lanes.append(dict(lane=lane, baseline_functional_cycles=baseline,
            previous_functional_cycles=before['candidate_functional_cycles'],
            optimized_functional_cycles=current, delta_vs_c0=current-baseline,
            cycle_change_vs_c0_pct=100*(current-baseline)/baseline,
            saved_cycles_vs_previous=before['candidate_functional_cycles']-current,
            skipped_tiles=value['candidate']['skipped'], get_bytes=value['candidate']['get_bytes']))
        mapping[f'transactions_lane{lane}.json'] = path
        mapping[f'per_stage_lane{lane}.csv'] = run / f'transactions_lane{lane}/per_stage.csv'
    base_bytes = sum(v['baseline']['get_bytes'] for v in comparisons)
    get_bytes = sum(v['candidate']['get_bytes'] for v in comparisons)
    summary = dict(schema=1, status='PASS', candidate='C1a Store-wait optimization',
        scope='Complete real Gemmini functional RTL; deterministic private memory only',
        full_network=dict(lanes=3, frames_per_lane=1, stages_per_lane=166,
            accepted_spad_reads_compared=sum(v['candidate']['reads'] for v in comparisons),
            tl_store_beats_compared=sum(v['candidate']['stores'] for v in comparisons),
            input_tiles_skipped=sum(v['candidate']['skipped'] for v in comparisons),
            baseline_get_bytes=base_bytes, optimized_get_bytes=get_bytes,
            saved_get_bytes=base_bytes-get_bytes, saved_get_pct=100*(base_bytes-get_bytes)/base_bytes),
        functional_timing_diagnostic=lanes, accumulator_bytes_compared=sum(v['bytes_compared'] for v in acc),
        disabled_identity_events=disabled['events_compared'], store_hazard_fallback_cycle_exact=True,
        g2='INSUFFICIENT_EVIDENCE', full_system_performance_model=False,
        production_frontend_integrated=False, bitstream_generated=False, board_tested=False)
    decision = dict(schema=1, decision='INSUFFICIENT_EVIDENCE',
        base_candidate_build_id=candidate['parent_build_id'],
        g1=dict(status='PASS', scope=summary['scope']),
        g2=dict(status='INSUFFICIENT_EVIDENCE',
            reason='Shared DDR/ASRAM arbitration, system service times and G2 seed/sensitivity matrix not measured'),
        bitstream_authorized=False, board_authorized=False)
    (run / 'optimized_summary.json').write_text(json.dumps(summary, indent=2) + '\n')
    (run / 'optimized_decision.json').write_text(json.dumps(decision, indent=2) + '\n')
    destination.mkdir(parents=True)
    mapping.update({'summary.json': run / 'optimized_summary.json',
                    'decision.json': run / 'optimized_decision.json'})
    for suite in ('smoke', 'regression', 'network'):
        mapping[suite + '_result.json'] = run / (suite + '_result.json')
    for name, source in mapping.items():
        shutil.copyfile(source, destination / name)
        evidence[str(source)] = sha(source)
    diff = []
    original = prior / 'candidate_07/gen-collateral'
    for path in sorted((context.parent / 'gen-collateral').iterdir()):
        old = original / path.name
        before = old.read_text().splitlines(True) if old.is_file() else []
        after = path.read_text().splitlines(True)
        if before != after:
            diff.extend(difflib.unified_diff(before, after,
                fromfile='a/gen-collateral/' + path.name if before else '/dev/null',
                tofile='b/gen-collateral/' + path.name))
    (destination / 'change_from_g1.patch').write_text(''.join(diff))
    first = lanes[0]
    full = summary['full_network']
    report = f'''# C1a 写回等待优化仿真

G1 功能回归 **PASS**；G2 / 物理决策 **INSUFFICIENT_EVIDENCE**。

将未发出 Store 的全局排空，改为两个 Loop 槽及独立活动 Store 生成器的完整输出地址不相交证明。推导中的槽采用已配置的完整输出通道上界；未知布局或输入/输出重叠时立即使用原有 Input 加载。已发出的 Store、Load/Weight/Bias、物理提交队列、源写入失效、错误和复位检查保留。

| 第 0 路整网功能窗口 | 周期 |
|---|---:|
| C0 | {first['baseline_functional_cycles']:,} |
| 之前 C1a | {first['previous_functional_cycles']:,} |
| 优化后 C1a | {first['optimized_functional_cycles']:,} |

相对之前减少 **{first['saved_cycles_vs_previous']:,}** 周期；相对 C0 改变 **{first['delta_vs_c0']:+,}（{first['cycle_change_vs_c0_pct']:+.6f}%）**。三路独立功能仿真的逐路结果见 [summary.json](summary.json)，不代表共享访存吞吐或板上 FPS。

三路各一帧、每帧 166 stage，逐路 11,049 个原生命令/边界。全部 **{full['accepted_spad_reads_compared']:,}** 次 SPAD 读取及 **{full['tl_store_beats_compared']:,}** 个输出 beat、最终 SPAD 逐字节一致；原尺寸层和三路多帧 Accumulator 共 **{summary['accumulator_bytes_compared']:,}** 字节一致。全网省略 **{full['input_tiles_skipped']}** 个完整 Input tile，Get 减少 **{full['saved_get_bytes']:,} 字节（{full['saved_get_pct']:.4f}%）**，Weight/Bias 数量及字节保持原值。

四种 DMA 模式 × 三路 × 三帧、原始配置/写入干扰、隔离模式切换、命中后第二 D beat denied/corrupt 与实际复位重放均通过。新增原生输出覆盖输入用例三路三帧均零命中，OFF/ON 事件和周期完全一致，证明不会等待自己的输出。关闭模式 {disabled['events_compared']:,} 条事件及周期与 C0 一致。303 项驻留生命周期、18 项 Store 范围边界检查，以及原有数值/协议负例和 G0 回归通过。

已发出的访存仍采用保守排空，且新增范围算术的面积、时序尚未测量。原型限定于冻结的合法原生 tiling；2,938 个卷积包的完整配置及 tile 通道数不超过 outer 通道上界已独立核对，任意畸形原生指令包不在支持范围。本轮未修改生产 SoC 或父候选，未综合、布局布线、生成 bitstream 或上板。当前仿真不含共享 DDR/ASRAM、CPU/RVV/PPU 周期，不能据此批准物理实现。

复跑入口为 `scripts/test_optimized_regression.py --suite smoke|regression|network`；每次使用新输出目录并准备 `store_hazard_fixture`。完整参数记录在三个 suite 结果、execution manifest 和 [provenance.json](provenance.json)。C0/G1 数值参考按原始 SHA 复用，当前编译的 OFF 周期一致性另行重验。编译曾移到本机 `/tmp` 加速文件访问；实际路径和所有输入 SHA 均保留，其他未完成编译不计为证据。
'''
    (destination / 'README.md').write_text(report)
    (destination / 'decision.md').write_text('功能门槛通过。共享访存与系统周期证据不足，决策为 **INSUFFICIENT_EVIDENCE**。\n\n' +
        '本轮停止于仿真，不授权综合、bitstream 或上板。详见 [仿真结果](README.md)。\n')
    (destination / 'provenance.json').write_text(json.dumps(dict(schema=1, run=str(run),
        prior_g1=str(prior), candidate_context=str(context), accepted_build=str(build),
        reused_baselines='Accepted G0 numerical references and G1 directed OFF/Accumulator references',
        pre_edit_snapshot=str(run / 'pre_edit_feature_sha256.json'),
        relocation=json.loads((run / 'relocation.json').read_text()),
        excluded_attempts=['g1_opt_20261020_01/candidate_01: byte-exact but lost directed hits due to derive-pending fallback'],
        production_export=False, full_system_performance_model=False), indent=2) + '\n')
    sources = [FEATURE / name for name in ('Makefile', 'README.md', 'PLAN.md')]
    for directory in ('rtl', 'analysis', 'scripts', 'tests', 'manifests'):
        sources.extend(p for p in (FEATURE / directory).rglob('*') if p.is_file() and
            p.suffix in ('.py', '.cpp', '.sv', '.md', '.json') and p.name != 'G1_OPT_SOURCE_ORIGINS.json')
    origins = dict(schema=1, scope='Current sources after Store-wait optimization',
        sha256={str(p): sha(p) for p in sorted(set(sources))})
    (FEATURE / 'manifests/G1_OPT_SOURCE_ORIGINS.json').write_text(json.dumps(origins, indent=2) + '\n')
    (destination / 'current_source_origins.json').write_text(json.dumps(origins, indent=2) + '\n')
    (destination / 'evidence_manifest.json').write_text(json.dumps(dict(schema=1, sha256=evidence), indent=2) + '\n')
    (destination / 'archive_sha256.json').write_text(json.dumps(
        {p.name: sha(p) for p in sorted(destination.iterdir()) if p.is_file()}, indent=2) + '\n')
    print('CSC_OPT_ARCHIVE_PASS', destination, flush=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ('run', 'prior', 'context', 'build', 'output'):
        parser.add_argument('--' + name, type=Path, required=True)
    args = parser.parse_args()
    archive(args.run.resolve(), args.prior.resolve(), args.context.resolve(),
            args.build.resolve(), args.output.resolve())
