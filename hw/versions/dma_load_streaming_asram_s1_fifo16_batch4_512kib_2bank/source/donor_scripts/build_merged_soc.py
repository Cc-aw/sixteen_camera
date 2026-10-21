#!/usr/bin/env python3
"""Rebuild S1 from its local merged Chipyard snapshot, never reapply old overlays."""
import datetime
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]
WORK = ROOT / 'soc_shell/chipyard_build'
FEATURE = ROOT / 'hw/versions/dma_load_streaming_asram_512kib_2bank'
CONFIG = 'TaihangSoC1Rocket1RVV3Gemmini32x32MemoryParallelV3TensorIngress2BankDmaLoadConfig'
NAME = 'tsmcchip.fpga.taihangsoc.TaihangSoCFPGATestHarness.' + CONFIG


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def snapshot():
    return {str(p.relative_to(WORK)): sha(p)
            for folder in ('generators', 'fpga/src')
            for p in sorted((WORK / folder).rglob('*.scala')) if 'target' not in p.parts}


def main():
    env = os.environ.copy()
    for key in ('JAVA_OPTS', 'SBT_OPTS', 'USE_CHISEL7'):
        env.pop(key, None)
    java = WORK / '.conda-env/lib/jvm'
    riscv = WORK / '.conda-env/riscv-tools'
    env.update(JAVA_HOME=str(java), RISCV=str(riscv),
               COURSIER_CACHE=str(WORK / '.coursier/v1'), XDG_RUNTIME_DIR=str(WORK / '.runtime'),
               ACTIVATION_SRAM_ENABLED='1', DMA_LOAD_STREAMING='1')
    env['JAVA_TOOL_OPTIONS'] = (f'-Xmx16G -Xss8M -XX:ActiveProcessorCount=8 '
        f'-Djava.io.tmpdir={WORK}/.java_tmp -Dsbt.global.base={WORK}/.sbt '
        f'-Dsbt.boot.directory={WORK}/.sbt/boot -Dsbt.ivy.home={WORK}/.ivy2')
    env['PATH'] = ':'.join(map(str, (java / 'bin', WORK / '.conda-env/bin',
        WORK / '.local/bin', riscv / 'bin'))) + ':' + env['PATH']
    for sub in ('.runtime', '.java_tmp'):
        (WORK / sub).mkdir(exist_ok=True)
    sources = snapshot()
    identity = hashlib.sha256(json.dumps(dict(config=NAME, activation_sram_enabled=True,
        dma_load_streaming_enable=True, effective_scala=sources,
        build_sbt_sha256=sha(WORK / 'build.sbt')), sort_keys=True).encode()).hexdigest()
    env['DMA_LOAD_BUILD_ID'] = identity[:16]
    output = ROOT / 'generated/soc' / NAME
    if output.exists():
        archive = ROOT / 'build/generation_archive'
        archive.mkdir(parents=True, exist_ok=True)
        output.rename(archive / (NAME + '.' + datetime.datetime.now().strftime('%Y%m%dT%H%M%S%f')))
    output.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(['make', '-C', str(WORK / 'fpga'), '-W', str(WORK / 'build.sbt'), 'verilog',
        'SUB_PROJECT=taihang_soc', 'SBT_PROJECT=chipyard_fpga', 'MODEL=TaihangSoCFPGATestHarness',
        'VLOG_MODEL=TaihangSoCFPGATestHarness', 'MODEL_PACKAGE=tsmcchip.fpga.taihangsoc',
        'CONFIG_PACKAGE=tsmcchip.fpga.taihangsoc', 'CONFIG=' + CONFIG, 'GENERATOR_PACKAGE=chipyard',
        'TOP=ChipTop', 'TB=none', 'build_dir=' + str(output)], env=env, check=True)
    rtl = output / 'gen-collateral'
    raw = {str(p.relative_to(rtl)): sha(p) for p in rtl.rglob('*') if p.is_file()}
    for script in ('apply_xcvu13p_gemmini_32x32_acc256_wide_uram.sh',
                   'apply_xcvu13p_soc_cache_bram.sh', 'apply_result_bram.sh'):
        subprocess.run(['bash', str(ROOT / 'soc_shell/npu100_video/fpga/scripts' / script),
                        str(rtl)], env=env, check=True)
    include = rtl / 'include'
    include.mkdir(exist_ok=True)
    shutil.copy2(FEATURE / 'software/include/activation_sram_map.h', include)
    for lane in range(3):
        headers = list((WORK / 'generators/gemmini/software/gemmini-rocc-tests/include').glob(
            f'gemmini_params_32x32*custom{lane}_xcvu13p.h')) + list(WORK.glob(
            f'gemmini_params_32x32*custom{lane}_xcvu13p.h'))
        if not headers:
            raise RuntimeError('Missing generated Gemmini header for lane ' + str(lane))
        shutil.copy2(headers[0], include)
    if snapshot() != sources:
        raise RuntimeError('Scala sources changed during generation')
    context = dict(hardware_variant='s5_dma_streaming_asram_merged_s1', config=NAME,
        generated_at_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
        source_workspace=str(WORK), effective_scala=sources, build_sbt_sha256=sha(WORK / 'build.sbt'),
        source_identity_sha256=identity, dma_load_build_id=identity[:16],
        activation_sram_enabled=True, dma_load_runtime_enable=True, dma_load_streaming_enable=True,
        dma_load_pipeline_version='row_ready_v1', dma_load_reset_mode='read_assembled',
        dma_load_supported_modes=['read_assembled'], dma_load_mode_ids=[2],
        dma_load_capability_word='0x00010004', dma_load_fixed_mode=2,
        l2_banks=2, l2_capacity_kib=512, l2_implementation='s5_cached_heads_predecoded_plans',
        raw_rtl_sha256=raw,
        final_rtl_sha256={str(p.relative_to(rtl)): sha(p) for p in rtl.rglob('*') if p.is_file()},
        whole_design_pnr='NOT_RUN', board_validation='NOT_RUN')
    (output / 'GENERATION_CONTEXT.json').write_text(json.dumps(context, indent=2) + '\n')
    (output / 'EFFECTIVE_SCALA.sha256').write_text(''.join(
        f'{digest}  {rel}\n' for rel, digest in sources.items()))
    topology = next(output.glob('*.activation_sram_topology.json'))
    manifest = dict(json.loads((FEATURE / 'manifests/activation_sram.json').read_text()),
        enabled=True, hardware_generation_digest=identity, source_topology_digest=sha(topology))
    (output / 'activation_sram_manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    subprocess.run(['python3', str(ROOT / 'scripts/check_merged_soc.py'), str(rtl),
        '--l2-banks', '2', '--dma-load-runtime', '--s5-l2'], check=True)
    subprocess.run(['python3', str(FEATURE / 'scripts/check_activation_sram.py'),
        '--rtl', str(rtl), '--report', str(output / 'activation_sram_structure.json')], check=True)
    # Never let firmware expect the donor's old build ID.
    target_path = ROOT / 'sw/board_tests/dma_load_streaming_asram_512kib_2bank/hardware/target.json'
    target = json.loads(target_path.read_text())
    target.update(hardware_build_id=identity[:16], bitstream=None, bitstream_sha256=None,
        artifact_state='RTL_SIMULATION_ONLY', hardware_config=NAME,
        generation_context=str((output / 'GENERATION_CONTEXT.json').relative_to(ROOT)),
        generation_context_sha256=sha(output / 'GENERATION_CONTEXT.json'),
        hardware_variant='s5_dma_streaming_asram_merged_s1',
        dma_modes=['read_assembled'], dma_mode_ids=[2], dma_fixed_mode=2,
        dma_capability_word='0x00010004')
    target_path.write_text(json.dumps(target, indent=2) + '\n')
    print('MERGED_S1_SOC_GENERATED=PASS BUILD_ID=' + identity[:16])


if __name__ == '__main__':
    main()
