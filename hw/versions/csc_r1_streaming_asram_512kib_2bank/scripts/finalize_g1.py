#!/usr/bin/env python3
"""Fail-closed acceptance of the recorded C1a functional prototype evidence.

G1 functional evidence never grants a physical GO or a G2 throughput result.
"""
import argparse
import csv
import json
from pathlib import Path
import re
import sys

from candidate_rtl import sha

FEATURE=Path(__file__).resolve().parents[1]


def finalize(run,g0,context,build):
    if any((run/name).exists() for name in ('g1_summary.json','g1_decision.json','g1_decision.md','g1_evidence_manifest.json')):
        raise FileExistsError('Final G1 evidence already exists; use a new output root')
    evidence={}
    def read(path,status=None,verify=True):
        result=json.loads(path.read_text())
        if status is not None and result.get('status')!=status:
            raise ValueError('Missing/failed evidence: '+str(path))
        if verify:
            for name,digest in result.get('sha256',{}).items():
                if sha(Path(name))!=digest:raise ValueError('Evidence input changed: '+name)
        evidence[str(path)]=sha(path)
        return result
    policy=read(run/'decision_policy.json')
    if policy!=json.loads((FEATURE/'manifests/decision_policy.json').read_text()):
        raise ValueError('Pre-registered policy changed')
    previous=read(g0/'decision.json')
    if previous['g0']['status']!='PASS':raise ValueError('G0 did not pass')
    candidate=read(context)
    if candidate['parent_build_id']!=previous['base_candidate_build_id']:
        raise ValueError('Wrong frozen C0 identity')
    if sha(Path(candidate['parent_context']))!=candidate['parent_context_sha256']:
        raise ValueError('Parent generation context changed')
    for name,digest in candidate['parent_rtl_sha256'].items():
        if sha(Path(name))!=digest:raise ValueError('Parent RTL changed: '+name)
    for name,digest in candidate['overlay_sources_sha256'].items():
        if sha(Path(name))!=digest:raise ValueError('Candidate generator source changed: '+name)
    read(build/'build_manifest.json','C1A_FULL_RTL_BUILT')
    unit=(run/'unit_checks_03.log').read_text()
    if 'CSC_R1_UNIT_PASS checks=302' not in unit or 'Ran 6 tests' not in unit or '\nOK\n' not in unit:
        raise ValueError('Missing directed RTL/comparator unit checks')
    evidence[str(run/'unit_checks_03.log')]=sha(run/'unit_checks_03.log')
    ledger_unit=(run/'transaction_unit_checks.log').read_text()
    if 'Ran 11 tests' not in ledger_unit or '\nOK\n' not in ledger_unit:
        raise ValueError('Missing protocol-negative controls')
    evidence[str(run/'transaction_unit_checks.log')]=sha(run/'transaction_unit_checks.log')
    read(run/'generator_02/result.json','PASS')
    disabled=read(run/'final_disabled_identity.json','PASS')
    if disabled['events_compared']!=411621 or not disabled['exact_cycles']:
        raise ValueError('Disabled cycle identity incomplete')
    matrix=[]
    for mode in range(4):
        for label in ('off','on'):
            directory=run/f'directed_mode{mode}_{label}'
            execution=read(directory/'execution_manifest.json')
            if execution['lanes']!=[0,1,2] or execution['frames']!=3 or execution['dma_load_mode']!=mode:
                raise ValueError('Incomplete lane/frame/mode matrix')
            read(directory/'execution_result.json','PASS')
        for lane in range(3):
            result=read(run/f'directed_mode{mode}_comparison_lane{lane}/comparison.json','PASS')
            if result['candidate']['tiles']!=12 or result['candidate']['skipped']!=9:
                raise ValueError('Missing real cold/warm/epoch transitions')
            matrix.append(dict(case='whole_tile_reuse_and_frame_epoch',mode=mode,lane=lane,
                frames=3,skipped_tiles=9,status='PASS'))
    for label in ('off','on'):
        read(run/f'config_hazard_{label}/execution_manifest.json')
        read(run/f'config_hazard_{label}/execution_result.json','PASS')
    for lane in range(3):
        result=read(run/f'config_hazard_comparison_lane{lane}/comparison.json','PASS')
        if result['candidate']['skipped']!=3:raise ValueError('Raw writer quarantine was not tested')
        matrix.append(dict(case='raw_config_restore_and_spad_writer',lane=lane,status='PASS'))
    for mode in (0,2):
        read(run/f'mode_switch_{mode}/result.json','PASS')
        for label in ('off','on'):
            read(run/f'mode_switch_{mode}/{label}/execution_manifest.json')
            read(run/f'mode_switch_{mode}/{label}/execution_result.json','PASS')
        for lane in range(3):read(run/f'mode_switch_{mode}/comparison_lane{lane}/comparison.json','PASS')
        matrix.append(dict(case='isolated_mode_change_invalidation',start_mode=mode,lanes=3,status='PASS'))
    faults=[]
    for kind in ('denied','corrupt'):
        read(run/f'fault_{kind}/execution_manifest.json')
        result=read(run/f'fault_{kind}/fault_result.json','PASS')
        if not result['late_fault_detected'] or not result['reset_recovery']:
            raise ValueError('Incomplete real late fault/reset')
        read(run/f'fault_{kind}/numerical_recovery/comparison.json','PASS')
        faults.append(dict(kind=kind,late_second_beat=True,after_real_hits=True,
            reset_recovery_byte_exact=True,status='PASS'))
    accumulator=[]
    for name in ('acc_directed_comparison.json','acc_fullsize_comparison.json'):
        result=read(run/name,'PASS');accumulator.append(result)
    fullsize=read(run/'fullsize_final_comparison/comparison.json','PASS')
    if fullsize['candidate']['skipped']<=0:raise ValueError('No full-size actual Input reuse')
    for label in ('off','on'):
        read(run/f'acc_fullsize_{label}/execution_manifest.json')
        read(run/f'acc_fullsize_{label}/execution_result.json','PASS')
    full_exec=read(run/'full_network_final_on/execution_manifest.json')
    if full_exec['lanes']!=[0,1,2] or full_exec['frames']!=1 or full_exec['last_stage']!=165:
        raise ValueError('Incomplete full native workload execution')
    read(run/'full_network_final_on/execution_result.json','PASS')
    full=[]
    for lane in range(3):
        numerical=read(run/f'full_comparison_lane{lane}/comparison.json','PASS')
        transactions=read(run/f'transactions_lane{lane}/transactions.json','PASS')
        log=(run/f'full_network_final_on/lane{lane}.log').read_text()
        stages=re.findall(r'FULL_RTL_STAGE lane=\d+ frame=0 stage=(\d+) ',log)
        if list(map(int,stages))!=list(range(166)) or 'native_words=11049 ' not in log:
            raise ValueError('Missing native stage/final completion')
        for key,expected in (('reads',3813916),('stores',526200)):
            if numerical['candidate'][key]!=expected:raise ValueError('Incomplete full numerical result')
        full.append(dict(lane=lane,numerical=numerical,transactions=transactions))
    for path in (run/'parent_check.log',run/'g0_regression.log'):
        evidence[str(path)]=sha(path)
    total_baseline=sum(item['numerical']['baseline']['get_bytes'] for item in full)
    total_candidate=sum(item['numerical']['candidate']['get_bytes'] for item in full)
    saved=total_baseline-total_candidate
    if saved<=0:raise ValueError('No actual physical traffic suppression')
    baseline_cycles={lane:0 for lane in range(3)}
    with (g0/'parallel_residency/per_stage_opportunity.csv').open() as source:
        for row in csv.DictReader(source):
            if int(row['frame'])==0:
                baseline_cycles[int(row['lane'])]+=int(row.get('functional_stage_cycles') or 0)
    diagnostic=[]
    for item in full:
        lane=item['lane'];before=baseline_cycles[lane]
        after=item['transactions']['totals']['functional_cycles']
        diagnostic.append(dict(lane=lane,baseline_functional_cycles=before,candidate_functional_cycles=after,
            added_cycles=after-before,cycle_change_pct=100*(after-before)/before))
    summary=dict(schema=1,status='PASS',candidate='C1a',
        functional_gate_scope='Complete real Gemmini datapath with deterministic private physical-memory services',
        full_network=dict(lanes=3,frames_per_lane=1,stages_per_lane=166,
            accepted_spad_reads_compared=sum(item['numerical']['candidate']['reads'] for item in full),
            tl_store_beats_compared=sum(item['numerical']['candidate']['stores'] for item in full),
            input_tiles_skipped=sum(item['numerical']['candidate']['skipped'] for item in full),
            baseline_get_bytes=total_baseline,candidate_get_bytes=total_candidate,saved_get_bytes=saved,
            saved_get_pct=100*saved/total_baseline),
        four_mode_three_lane_three_frame_matrix=matrix,
        accumulator_bytes_compared=sum(item['bytes_compared'] for item in accumulator),
        late_fault_reset=faults,disabled_event_cycle_identity=disabled['events_compared'],
        protocol_errors=0,deadlocks=0,
        assumptions=['Bare-metal identity address mapping',
            'Explicit drained HOST/DRAIN/frame invalidation interface',
            'No shared DDR/ASRAM arbitration, CPU/RVV or PPU timing in this functional model'],
        production_frontend_integrated=False,physical_timing_measured=False,
        throughput_gain_measured=False)
    summary['functional_timing_diagnostic']=dict(scope='Private low-latency functional memory only; not G2 or system throughput',
        lanes=diagnostic,interpretation='Global load/store/generator drains can erase the traffic benefit')
    (run/'g1_summary.json').write_text(json.dumps(summary,indent=2)+'\n')
    decision=dict(schema=1,feature='CSC-R1',candidate='C1a',
        base_repository_commit=previous['base_repository_commit'],
        base_candidate_build_id=previous['base_candidate_build_id'],
        candidate_context_sha256=sha(context),csc_r1_enabled=True,weight_reuse_enabled=False,
        g0=previous['g0'],g1=dict(status='PASS',bit_exact=True,protocol_errors=0,deadlocks=0,
            scope=summary['functional_gate_scope'],production_frontend_integrated=False),
        g2=dict(status='INSUFFICIENT_EVIDENCE',whole_network_rtl_cycle_accurate=False,
            absolute_throughput_gain_pct=None,shared_memory_contention_measured=False,
            fixed_seed_matrix_complete=False),
        decision='INSUFFICIENT_EVIDENCE',reason='G1_FUNCTIONAL_PROTOTYPE_PASS_G2_SYSTEM_TIMING_NOT_ESTABLISHED',
        bitstream_generated=False,board_tested=False,
        missing_evidence=['Production frontend boundary wiring and translated-address policy',
            'Matched single/three-lane realistic latency/backpressure/shared-memory G2, at least three fixed seeds',
            'Credible full-network throughput or calibrated conservative >=5% lower bound',
            'Physical resource/critical-path evaluation only in a separately authorized physical task'])
    (run/'g1_decision.json').write_text(json.dumps(decision,indent=2)+'\n')
    text=f'''# CSC-R1 C1a：G1 功能原型验证

**G1：PASS（下述功能模型契约内）；物理实现决策：INSUFFICIENT_EVIDENCE。**

两条物理 Input 半区描述符只省略完整同址 tile 的 Mvin，保留原配置命令、真实 RS 完成路径及关闭回退。没有增加数据 SRAM，没有启用 Weight 复用。

三路各一帧、每帧 166 个原生 stage：逐字节比较 {summary['full_network']['accepted_spad_reads_compared']:,} 次 SPAD 读取、{summary['full_network']['tl_store_beats_compared']:,} 个输出写回 beat，全部一致。原生命令、DMA row/credit、ROB、TL source 和真实 bank 接收/提交账本全部闭合。Accumulator 在原生 fence 边界共比较 {summary['accumulator_bytes_compared']:,} 字节。

四模式三路三帧、不同输入/换帧、双 slot/物理地址覆盖、原始配置恢复、SPAD 写入失效、隔离模式切换、真实晚到 denied/corrupt 和复位恢复通过。关闭 CSC 后 {disabled['events_compared']:,} 条 C0 事件连同周期完全一致。

实际少发 {saved:,} 字节 Get，占完整 C0 流量 **{100*saved/total_baseline:.4f}%**。这是本有界实现的流量结果，不是 G0 无界机会或吞吐提升。保守排空会增加控制等待；原尺寸功能模型已显示这种开销，不能仅凭省 Get 推进 bitstream。

低延迟私有内存诊断中，第 0 路功能窗口从 {diagnostic[0]['baseline_functional_cycles']:,} 增至 {diagnostic[0]['candidate_functional_cycles']:,} 周期（增加 {diagnostic[0]['added_cycles']:,}，{diagnostic[0]['cycle_change_pct']:.4f}%）。此数只说明当前保守控制的开销；它不包含真实共享访存和 HOST/PPU 时间，不是系统吞吐测量。应先收窄排空依赖、保留关闭回退，再做 G2，当前不建议物理实现。

模型使用实际 RS/EX/FP16/存储/DMA RTL，外存由私有确定性物理内存服务替代，HOST padding 按原生操作执行；尚未接入生产 frontend 的失效接口，也没有共享 DDR/ASRAM 争用、CPU/RVV/PPU 周期或物理时序证据。G2 仍为 INSUFFICIENT_EVIDENCE，不报告系统 FPS，不执行综合、布局布线、bitstream 或上板。
'''
    (run/'g1_decision.md').write_text(text)
    evidence.update({str(run/name):sha(run/name) for name in ('g1_summary.json','g1_decision.json','g1_decision.md')})
    (run/'g1_evidence_manifest.json').write_text(json.dumps(dict(schema=1,sha256=evidence),indent=2)+'\n')
    print('CSC_C1A_G1_FUNCTIONAL_PASS_G2_INSUFFICIENT_EVIDENCE',summary['full_network'])


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--run',type=Path,required=True)
    parser.add_argument('--g0-run',type=Path,required=True)
    parser.add_argument('--context',type=Path,required=True)
    parser.add_argument('--build',type=Path,required=True)
    args=parser.parse_args()
    finalize(args.run.resolve(),args.g0_run.resolve(),args.context.resolve(),args.build.resolve())
