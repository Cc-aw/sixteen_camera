#!/usr/bin/env python3
"""Generated three-Gemmini/ASRAM numerical test: fixed mode 2, four memory routes."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys

from common import selected_output

ROOT = Path(__file__).resolve().parents[1]
TESTS = ROOT / 'tests/merged_dma'
OUT = ROOT / 'build/rtl_acceptance'
CFG = 'tsmcchip.fpga.taihangsoc.TaihangSoCFPGATestHarness.TaihangSoC1Rocket1RVV3Gemmini32x32MemoryParallelV3TensorIngress2BankDmaLoadConfig'


def main():
    global OUT
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=OUT)
    parser.add_argument('--generated', type=Path, default=ROOT / 'generated')
    args = parser.parse_args()
    OUT = args.output.resolve()
    if (ROOT / 'build').resolve() not in OUT.parents:
        raise ValueError('Use a new output directory below this version build/')
    OUT.mkdir(parents=True, exist_ok=False)
    source = (TESTS / 'test_spad.py').read_text()
    anchor = "    mode_count=len(json.loads((args.rtl.resolve().parent/'GENERATION_CONTEXT.json').read_text())['dma_load_supported_modes'])"
    pos = source.rindex(anchor)
    insert = '''    body=body.replace('    for(runtime_mode=2;', '    for(integer profile=0;profile<4;profile=profile+1)begin\\n      lanes[0].lane.storage_profile=profile;lanes[1].lane.storage_profile=profile;lanes[2].lane.storage_profile=profile;\\n    for(runtime_mode=2;')
    body=body.replace('    $display("REAL_CLUSTER_PASS,DMA_SPAD', '    end\\n    $display("REAL_CLUSTER_PASS,DMA_SPAD')
'''
    # Expansion occurs after the final fixed-mode substitution below.
    anchor2 = "    anchor='(out/\"tb_real_cluster.sv\").write_text(tb)'"
    assert source.count(anchor2) == 1
    source = source.replace(anchor2, insert + anchor2)
    source = source.replace('ROOT=Path(__file__).resolve().parents[2]', f'ROOT=Path({str(ROOT)!r})')
    source = source.replace("(Path(__file__).parent/'test_real_gemmini.py')",
                            f"(Path({str(TESTS)!r})/'test_real_gemmini.py')")
    source = source.replace('\n    write_evidence(out,args.rtl,args.matrix,args.case)\n', '\n')
    driver = OUT / 'driver.py'
    driver.write_text(source)
    generated, context = selected_output(args.generated)
    rtl = generated / 'gen-collateral'
    env = dict(os.environ, STREAM_ASRAM_SIM='1', STREAM_ASRAM_COMPACT='1',
               VIVADO_BIN=os.environ.get('VIVADO_BIN', 'vivado'))
    subprocess.run([sys.executable, str(driver), '--rtl', str(rtl), '--matrix',
                    '--output', str(OUT / 'simulation')], env=env, check=True)
    log = (OUT / 'simulation/result.log').read_text()
    assert not re.search(r'Fatal:|Error:|Assertion failed:', log)
    assert 'REAL_CLUSTER_PASS,DMA_SPAD=1,modes=1,lanes=3' in log
    rows = re.findall(r'ASRAM_REAL_LANE_PASS,lane=(\d+),profile=(\d+)', log)
    assert len(rows) == 4 * 6 * 3
    keys = set()
    profile_by_lane = {}
    for line in log.splitlines():
        if 'ASRAM_REAL_LANE_PASS,' in line:
            f = dict(re.findall(r'(\w+)=(\d+)', line))
            profile_by_lane[int(f['lane'])] = int(f['profile'])
        if 'DMA_SPAD_PASS,' in line:
            f = dict(re.findall(r'(\w+)=(\d+)', line))
            key = (profile_by_lane[int(f['lane'])], int(f['mode']), int(f['case']), int(f['lane']))
            assert key not in keys
            keys.add(key)
    assert keys == {(p, 2, c, l) for p in range(4) for c in range(6) for l in range(3)}
    context = json.loads((rtl.parent / 'GENERATION_CONTEXT.json').read_text())
    (OUT / 'evidence.json').write_text(json.dumps(dict(status='MERGED_GEMMINI_ASRAM_NUMERICAL_PASS',
        build_id=context['dma_load_build_id'], records=len(keys), modes=[2], lanes=3,
        vendor_primitive_simulated=True, cpu_rvv_executed=False, full_model_executed=False,
        log_sha256=hashlib.sha256(log.encode()).hexdigest()), indent=2) + '\n')
    print('MERGED_GEMMINI_ASRAM_NUMERICAL_PASS records=72 mode=read_assembled lanes=3')
    # Exercise actual matmul/LoopConv/SiLU execution as well as the 72 mvin/mvout
    # scale/ASRAM cases above. Use the same fresh production RTL and mode2 ABI.
    compute = OUT / 'compute'
    runner = (TESTS / 'test_real_gemmini.py').read_text()
    runner = runner.replace('feature = Path(__file__).resolve().parent',
        f'feature = Path({str(ROOT / "tests/rtl/command_frontend")!r})')
    runner = runner.replace('project = feature.parents[1]', f'project = Path({str(ROOT)!r})')
    compute_driver = OUT / 'compute_driver.py'
    compute_driver.write_text(runner)
    compute_env = dict(env)
    # Compact numerical initialization references shape variables that the
    # independent matmul/LoopConv fixture does not declare.
    compute_env.pop('STREAM_ASRAM_COMPACT', None)
    subprocess.run([sys.executable, str(compute_driver), '--rtl', str(rtl),
                    '--output', str(compute), '--dma-load-mode', 'all'], env=compute_env, check=True)
    compute_log = (compute / 'result.log').read_text()
    assert not re.search(r'Fatal:|Error:|Assertion failed:', compute_log)
    assert 'REAL_CLUSTER_PASS,dim=32,scale=fp16,conv_chunks=6,silu_lut=checked' in compute_log
    assert 'DMA_LOAD_REAL_RUNTIME_PASS' in compute_log
    (compute / 'evidence.json').write_text(json.dumps(dict(status='BATCH4_REAL_COMPUTE_PASS',
        build_id=context['dma_load_build_id'], lanes=3, conv_chunks_per_lane=6,
        matmul=True, silu_lut=True, host_irq_isolation=True,
        vendor_primitive_simulated=True, cpu_rvv_executed=False, full_model_executed=False,
        log_sha256=hashlib.sha256(compute_log.encode()).hexdigest()), indent=2) + '\n')
    print('BATCH4_REAL_COMPUTE_PASS lanes=3 conv_chunks=6 matmul=1 silu_lut=1')


if __name__ == '__main__':
    main()
