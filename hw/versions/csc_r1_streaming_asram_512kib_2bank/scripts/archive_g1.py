#!/usr/bin/env python3
"""Archive completed G1 evidence without changing the accepted G0 archives."""
import argparse
import difflib
import json
from pathlib import Path
import shutil

from candidate_rtl import sha

FEATURE=Path(__file__).resolve().parents[1]


def archive(run,g0,context,build,destination):
    decision=json.loads((run/'g1_decision.json').read_text())
    if decision['g1']['status']!='PASS' or decision['decision']!='INSUFFICIENT_EVIDENCE':
        raise ValueError('Expected completed functional G1 and unapproved G2')
    evidence=json.loads((run/'g1_evidence_manifest.json').read_text())
    for name,digest in evidence['sha256'].items():
        if sha(Path(name))!=digest:raise ValueError('Accepted G1 evidence changed: '+name)
    destination.mkdir(parents=True,exist_ok=False)
    mapping={
        'README.md':None,
        'decision.json':run/'g1_decision.json','decision.md':run/'g1_decision.md',
        'summary.json':run/'g1_summary.json','evidence_manifest.json':run/'g1_evidence_manifest.json',
        'decision_policy.json':run/'decision_policy.json','g0_decision.json':g0/'decision.json',
        'candidate_context.json':context,'rtl_build.json':build/'build_manifest.json',
        'disabled_identity.json':run/'final_disabled_identity.json',
        'accumulator_directed.json':run/'acc_directed_comparison.json',
        'accumulator_fullsize.json':run/'acc_fullsize_comparison.json',
        'fullsize_numerical.json':run/'fullsize_final_comparison/comparison.json',
        'generator.json':run/'generator_02/result.json',
        'unit_checks.log':run/'unit_checks_03.log','transaction_unit_checks.log':run/'transaction_unit_checks.log',
        'g0_regression.log':run/'g0_regression.log','parent_check.log':run/'parent_check.log',
        'whole_execution.json':run/'full_network_final_on/execution_manifest.json',
        'whole_execution_result.json':run/'full_network_final_on/execution_result.json',
        'native_directed_fixture.json':run/'directed_fixture_03/fixture.json',
        'raw_config_fixture.json':run/'config_hazard_fixture/fixture.json',
        'fullsize_fixtures.json':run/'fullsize_fixtures/fixtures.json',
    }
    for mode in range(4):
        for lane in range(3):mapping[f'mode{mode}_lane{lane}.json']=run/f'directed_mode{mode}_comparison_lane{lane}/comparison.json'
    for lane in range(3):
        mapping[f'whole_lane{lane}.json']=run/f'full_comparison_lane{lane}/comparison.json'
        mapping[f'transactions_lane{lane}.json']=run/f'transactions_lane{lane}/transactions.json'
        mapping[f'per_stage_lane{lane}.csv']=run/f'transactions_lane{lane}/per_stage.csv'
        mapping[f'raw_config_lane{lane}.json']=run/f'config_hazard_comparison_lane{lane}/comparison.json'
    for mode in (0,2):mapping[f'mode_switch_{mode}.json']=run/f'mode_switch_{mode}/result.json'
    for kind in ('denied','corrupt'):
        mapping[f'fault_{kind}.json']=run/f'fault_{kind}/fault_result.json'
        mapping[f'fault_{kind}_numerical.json']=run/f'fault_{kind}/numerical_recovery/comparison.json'
        mapping[f'fault_{kind}.log']=run/f'fault_{kind}/simulation.log'
    for name,source in mapping.items():
        if source is not None:shutil.copyfile(source,destination/name)
    candidate=json.loads(context.read_text())
    parent=Path(candidate['parent_context']).parent/'gen-collateral'
    generated=context.parent/'gen-collateral'
    diff=[]
    for path in sorted(generated.iterdir()):
        original=parent/path.name
        before=original.read_text().splitlines(True) if original.is_file() else []
        after=path.read_text().splitlines(True)
        if before!=after:
            diff.extend(difflib.unified_diff(before,after,
                fromfile='a/gen-collateral/'+path.name if before else '/dev/null',
                tofile='b/gen-collateral/'+path.name))
    (destination/'rtl_overlay.patch').write_text(''.join(diff))
    sources=[FEATURE/'Makefile',FEATURE/'README.md',FEATURE/'PLAN.md']
    for directory in ('rtl','analysis','scripts','tests','manifests'):
        sources.extend(path for path in (FEATURE/directory).rglob('*') if path.is_file() and
            path.suffix in ('.py','.cpp','.sv','.md','.json') and path.name!='G1_SOURCE_ORIGINS.json')
    origins=dict(schema=1,scope='Current feature sources after G1; consumed build/runtime inputs are separately bound',
        candidate_context_sha256=sha(context),sha256={str(p):sha(p) for p in sorted(set(sources))})
    (FEATURE/'manifests/G1_SOURCE_ORIGINS.json').write_text(json.dumps(origins,indent=2)+'\n')
    shutil.copyfile(FEATURE/'manifests/G1_SOURCE_ORIGINS.json',destination/'current_source_origins.json')
    summary=json.loads((run/'g1_summary.json').read_text())
    d=summary['functional_timing_diagnostic']['lanes'][0]
    full=summary['full_network']
    text=f'''# C1a G1：功能成立，当前控制没有兑现提速

**G1 功能原型：PASS；G2 / 物理实现：INSUFFICIENT_EVIDENCE。**

实际 RTL 两条描述符按物理 SPAD 半区选择，命中完整 Input tile 才省略 Mvin，并保留配置命令及真实完成路径。可关闭；Weight 复用未启用。生产 SoC、两个父候选和用户软件修改均未覆盖。

| 验证 | 结果 |
|---|---|
| 三路各一帧，166 个原生 stage/帧 | 全部完成，逐路 11,049 个原生命令/边界 |
| SPAD 消费值、最终 SPAD、全部输出写回 | {full['accepted_spad_reads_compared']:,} 次读取、{full['tl_store_beats_compared']:,} 个输出 beat 逐字节一致 |
| Accumulator 原生 fence 边界 | {summary['accumulator_bytes_compared']:,} 字节逐项一致 |
| 四模式、三路、三帧、不同数据、双 slot | 每路每模式 12 次请求、9 次新命中，完成 token 全闭合 |
| 原始配置/写入干扰 | 配置恢复及写入失效通过 |
| 隔离模式切换 | 0→1→2 与 2→3→0 通过；测试单独抑制 DRAIN 清空以验证模式失效本身 |
| 晚到 denied/corrupt、真实复位 | 命中后注入第二个 D beat 错误，复位重放逐字节通过 |
| 关闭回退 | {summary['disabled_event_cycle_identity']:,} 条 C0 事件及周期完全一致 |
| 协议及物理账本 | Mvin row/credit/ROB、Get/Put、bank 接收/提交全部闭合 |

三路全网共省略 {full['input_tiles_skipped']} 个完整 Input tile，少发 **{full['saved_get_bytes']:,} 字节 Get（{full['saved_get_pct']:.4f}%）**。每路 16 个 tile、2,088 条实际 Mvin 被省略；原生已有的 54 个空 Input 请求没有重复计功。Weight/Bias 流量保持原值。

当前保守的全局 Load/Store/子生成器排空减少重叠：第 0 路私有低延迟功能窗口从 {d['baseline_functional_cycles']:,} 增至 {d['candidate_functional_cycles']:,} 周期，增加 {d['added_cycles']:,}（{d['cycle_change_pct']:.4f}%）。这不是系统吞吐测试；它说明仅省带宽还不足以推动物理实现。下一步应先收窄到相关写入/源区间的依赖，再做至少三组 seed、单路/三路及真实共享访存压力下的 G2。

模型使用完整真实 Gemmini RS/EX/FP16/SPAD/Accumulator/DMA，外存由私有确定性物理内存服务替代。HOST padding 执行实际原生操作；CPU/RVV/PPU 和共享 DDR/ASRAM 周期没有建模。生产 frontend 的失效接口及可综合导出尚未接入，地址契约限已验证的裸机恒等映射。没有综合、布局布线、bitstream、上板或新 WNS/FPS。

详见 [决策](decision.md)、[机器决策](decision.json)、[实现说明](../../analysis/c1a_design.md) 和 [实际 RTL 差异](rtl_overlay.patch)。原始数据保留在 `{run}`；本目录只归档可审阅结果，原始文件、输入、实际编译 RTL 和脚本 SHA 均绑定在各 manifest。
'''
    (destination/'README.md').write_text(text)
    (destination/'provenance.json').write_text(json.dumps(dict(schema=1,run=str(run),g0_run=str(g0),
        candidate_context=str(context),rtl_build=str(build),production_export=False,
        excluded_attempts=['candidate_01 field-count adapter failure',
            'candidate_02/03 and full_rtl_01/02 incomplete/obsolete prototypes',
            'candidate_04/full_rtl_03 and early fullsize/compact runs before in-flight matching/config preservation',
            'candidate_05/full_rtl_04 interrupted before config-only-path correction',
            'candidate_06/full_rtl_05 and early directed/fault/fullsize diagnostics before generator-drain guards',
            'acc_directed_on/off initial C++ iterator adapter compile failure'],
        final_candidate='candidate_07',final_rtl_build='full_rtl_06'),indent=2)+'\n')
    archive_sha={p.name:sha(p) for p in sorted(destination.iterdir()) if p.is_file()}
    (destination/'archive_sha256.json').write_text(json.dumps(archive_sha,indent=2)+'\n')
    print('CSC_G1_ARCHIVE_COMPLETE',destination,len(archive_sha)+1)


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    for name in ('run','g0-run','context','build','output'):parser.add_argument('--'+name,type=Path,required=True)
    args=parser.parse_args()
    archive(args.run.resolve(),args.g0_run.resolve(),args.context.resolve(),args.build.resolve(),args.output.resolve())
