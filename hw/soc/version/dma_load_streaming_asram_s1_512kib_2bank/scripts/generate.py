#!/usr/bin/env python3
"""Prepare a private local S1 source workspace; regenerate without replacing the imported bit."""
import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess

ROOT=Path(__file__).resolve().parents[1]


def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--workspace',type=Path,required=True)
    p.add_argument('--output',type=Path)
    p.add_argument('--prepare-only',action='store_true')
    args=p.parse_args();workspace=args.workspace.resolve();allowed=(ROOT/'build').resolve()
    if allowed not in workspace.parents:raise ValueError('Use a new workspace below this version build/')
    if workspace.exists():raise ValueError('Workspace exists; choose a new directory')
    frozen=ROOT/'source/chipyard'
    shutil.copytree(frozen,workspace)
    (workspace/'generators/gemmini/software/gemmini-rocc-tests/include').mkdir(parents=True,exist_ok=True)
    original=json.loads((ROOT/'generated/GENERATION_CONTEXT.json').read_text())
    sources={str(f.relative_to(workspace)):sha(f) for folder in ('generators','fpga/src')
             for f in (workspace/folder).rglob('*.scala')}
    if sources!=original['effective_scala']:raise ValueError('Prepared sources differ')
    if args.prepare_only:
        print('S1_PRIVATE_WORKSPACE_PREPARED '+str(workspace));return
    if args.output is None:raise ValueError('Set a new --output')
    output=args.output.resolve()
    if allowed not in output.parents or output.exists():raise ValueError('Output must be new below build/')
    java=Path(os.environ['JAVA_HOME']);launcher=Path(os.environ['SBT_LAUNCH']);riscv=Path(os.environ['RISCV'])
    if not (java/'bin/java').is_file() or not launcher.is_file():raise ValueError('Configure JAVA_HOME, SBT_LAUNCH, RISCV')
    identity=hashlib.sha256(json.dumps(dict(config=original['config'],activation_sram_enabled=True,
        dma_load_streaming_enable=True,effective_scala=sources,build_sbt_sha256=sha(workspace/'build.sbt')),sort_keys=True).encode()).hexdigest()
    env=dict(os.environ,ACTIVATION_SRAM_ENABLED='1',DMA_LOAD_STREAMING='1',DMA_LOAD_BUILD_ID=identity[:16],
             COURSIER_CACHE=str(workspace/'.coursier/v1'),XDG_RUNTIME_DIR=str(workspace/'.runtime'))
    for k in ('USE_CHISEL7','JAVA_OPTS','SBT_OPTS'):env.pop(k,None)
    env['PATH']=str(java/'bin')+':'+str(riscv/'bin')+':'+str(java.parents[1]/'bin')+':'+env['PATH']
    env['JAVA_TOOL_OPTIONS']=f'-Xmx16G -Xss8M -XX:ActiveProcessorCount=8 -Djava.io.tmpdir={workspace}/.java_tmp -Dsbt.global.base={workspace}/.sbt -Dsbt.ivy.home={workspace}/.ivy2'
    for name in ('.runtime','.java_tmp'):(workspace/name).mkdir()
    config=original['config'].rsplit('.',1)[1]
    subprocess.run(['make','-C',str(workspace/'fpga'),'verilog','SUB_PROJECT=taihang_soc',
        'SBT_PROJECT=chipyard_fpga','MODEL=TaihangSoCFPGATestHarness','VLOG_MODEL=TaihangSoCFPGATestHarness',
        'MODEL_PACKAGE=tsmcchip.fpga.taihangsoc','CONFIG_PACKAGE=tsmcchip.fpga.taihangsoc','CONFIG='+config,
        'GENERATOR_PACKAGE=chipyard','TOP=ChipTop','TB=none','build_dir='+str(output),
        'SBT='+str(java/'bin/java')+' -jar '+str(launcher)],env=env,check=True)
    rtl=output/'gen-collateral'
    raw={str(f.relative_to(rtl)):sha(f) for f in rtl.rglob('*') if f.is_file()}
    for name in ('apply_xcvu13p_gemmini_32x32_acc256_wide_uram.sh','apply_xcvu13p_soc_cache_bram.sh','apply_result_bram.sh'):
        subprocess.run(['bash',str(ROOT/'source/postprocess'/name),str(rtl)],env=env,check=True)
    # Parameter generation is audited against the frozen mathematical ABI.
    include=rtl/'include';include.mkdir(exist_ok=True)
    for lane in range(3):
        pattern=f'gemmini_params_32x32*custom{lane}_xcvu13p.h'
        headers=list((workspace/'generators/gemmini/software/gemmini-rocc-tests/include').glob(pattern))+list(workspace.glob(pattern))
        if not headers:raise ValueError('Missing fresh generated parameter header '+str(lane))
        frozen=next((ROOT/'generated/gen-collateral/include').glob(pattern))
        if any(f.read_bytes()!=frozen.read_bytes() for f in headers):raise ValueError('Generated Gemmini ABI changed')
        shutil.copyfile(headers[0],include/frozen.name)
    shutil.copyfile(ROOT/'generated/gen-collateral/include/activation_sram_map.h',include/'activation_sram_map.h')
    after={str(f.relative_to(workspace)):sha(f) for folder in ('generators','fpga/src') for f in (workspace/folder).rglob('*.scala')}
    if after!=sources:raise ValueError('Source changed during generation')
    context=dict(original,generated_at_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
        source_workspace=str(workspace),source_identity_sha256=identity,dma_load_build_id=identity[:16],
        raw_rtl_sha256=raw,final_rtl_sha256={str(f.relative_to(rtl)):sha(f) for f in rtl.rglob('*') if f.is_file()},
        whole_design_pnr='NOT_RUN_THIS_REGENERATION',board_validation='NOT_RUN_THIS_REGENERATION')
    (output/'GENERATION_CONTEXT.json').write_text(json.dumps(context,indent=2)+'\n')
    print('S1_PRIVATE_SOC_GENERATED hardware_id='+identity[:16]+' output='+str(output))

if __name__=='__main__':main()
