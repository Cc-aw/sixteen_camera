#!/usr/bin/env python3
"""Rebuild this independent S1 version from its complete local Scala snapshot."""
import argparse
import datetime
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

from common import ROOT, baseline, source_root, prepared_sources, build_inputs, copy_tree, hashes, identity, new_output, scala_hashes, sha


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--workspace', type=Path, required=True)
    parser.add_argument('--output', type=Path)
    parser.add_argument('--prepare-only', action='store_true')
    parser.add_argument('--resume', action='store_true', help='Reuse a source-identical private workspace after interruption')
    args = parser.parse_args()
    workspace = args.workspace.resolve()
    if ROOT / 'build' not in workspace.parents or (workspace.exists() and not args.resume):
        raise ValueError('Use a new workspace below this version build/')
    output = None if args.prepare_only else new_output(args.output or ROOT / 'generated')
    if workspace == source_root() or source_root() in workspace.parents:
        raise ValueError('Source reconstruction cache cannot be used as a mutable generation workspace')
    sources = scala_hashes(source_root())
    complete_inputs = build_inputs()
    source_inputs = {name.removeprefix('source/chipyard/'): value for name, value in complete_inputs.items() if name.startswith('source/chipyard/')}
    if not workspace.exists():
        copy_tree(source_root(), workspace)
    if (hashes(workspace, source_inputs) != source_inputs or scala_hashes(workspace) != sources or
            sha(workspace / 'build.sbt') != sha(source_root() / 'build.sbt')):
        raise ValueError('Prepared source hashes differ')
    # The frozen source snapshot omits Git administration. SBT uses .git only
    # as an initialization marker when discovering the included generators.
    for generator in (workspace / 'generators').iterdir():
        if generator.is_dir():
            (generator / '.git').mkdir(exist_ok=True)
    if args.prepare_only:
        print('BATCH4_WORKSPACE_PREPARED ' + str(workspace))
        return
    java = Path(os.environ['JAVA_HOME'])
    launcher = Path(os.environ['SBT_LAUNCH'])
    riscv = Path(os.environ['RISCV'])
    if not (java / 'bin/java').is_file() or not launcher.is_file():
        raise ValueError('Configure JAVA_HOME, SBT_LAUNCH and RISCV')
    for variable, target in (
            ('COURSIER_CACHE_SEED', '.coursier/v1'),
            ('SBT_BOOT_SEED', '.sbt/boot'), ('IVY_CACHE_SEED', '.ivy2/cache')):
        if os.environ.get(variable):
            if args.resume and (workspace / target).is_dir():
                continue
            print('COPY_DEPENDENCY_CACHE ' + variable, flush=True)
            copy_tree(Path(os.environ[variable]), workspace / target)
    digest = identity(sources)
    env = dict(os.environ, ACTIVATION_SRAM_ENABLED='1', DMA_LOAD_STREAMING='1',
               DMA_LOAD_BUILD_ID=digest[:16], COURSIER_CACHE=str(workspace / '.coursier/v1'),
               CHISEL_FIRTOOL_PATH=str(riscv / 'bin'))
    for key in ('USE_CHISEL7', 'JAVA_OPTS', 'SBT_OPTS'):
        env.pop(key, None)
    env['PATH'] = ':'.join(map(str, (java / 'bin', riscv / 'bin', java.parents[1] / 'bin'))) + ':' + env['PATH']
    env['JAVA_TOOL_OPTIONS'] = (
        f'-Xmx16G -Xss8M -XX:ActiveProcessorCount=8 -Djava.io.tmpdir={workspace}/.java_tmp '
        f'-Dsbt.global.base={workspace}/.sbt -Dsbt.boot.directory={workspace}/.sbt/boot '
        f'-Dsbt.ivy.home={workspace}/.ivy2 -Dsbt.server.autostart=false '
        '-Dsbt.server.forcestart=true -Dsbt.supershell=false')
    (workspace / '.java_tmp').mkdir(exist_ok=True)
    (workspace / 'generators/gemmini/software/gemmini-rocc-tests/include').mkdir(parents=True, exist_ok=True)
    original = baseline()['baseline_context']
    config = original['config'].rsplit('.', 1)[1]
    # Supply the complete prerequisite lists once; repeated find -L over this
    # network-mounted snapshot is much slower than SBT's actual compilation.
    inventory = [name.removeprefix('source/chipyard/') for name in complete_inputs
                 if name.startswith('source/chipyard/')]
    prerequisites = []
    for suffix, variables in ((('.scala',), ('CHIPYARD_SCALA_SOURCES', 'TAPEOUT_SCALA_SOURCES')),
                              (('.sv', '.v'), ('CHIPYARD_VLOG_SOURCES', 'TAPEOUT_VLOG_SOURCES')),
                              (('.sbt', '.properties'), ('SBT_SOURCES',))):
        listing = workspace / ('.inputs_' + variables[0])
        listing.write_text(' '.join(str(workspace / name) for name in inventory
                                    if name.endswith(suffix)) + '\n')
        prerequisites += [name + ' := $(file <' + str(listing) + ')' for name in variables]
    inputs_make = workspace / '.build_inputs.mk'
    inputs_make.write_text('\n'.join('override ' + line for line in prerequisites) + '\n')
    print('BATCH4_FULL_SOURCE_BUILD hardware_id=' + digest[:16], flush=True)
    # SBT's Unix socket path must stay below the platform's 108-byte limit.
    with tempfile.TemporaryDirectory(prefix='s1b4-') as runtime:
        env['XDG_RUNTIME_DIR'] = runtime
        subprocess.run(['make', '-C', str(workspace / 'fpga'), '-f', str(inputs_make),
                    '-f', 'Makefile', 'verilog', 'SUB_PROJECT=taihang_soc',
                    'SBT_PROJECT=chipyard_fpga', 'MODEL=TaihangSoCFPGATestHarness',
                    'VLOG_MODEL=TaihangSoCFPGATestHarness', 'MODEL_PACKAGE=tsmcchip.fpga.taihangsoc',
                    'CONFIG_PACKAGE=tsmcchip.fpga.taihangsoc', 'CONFIG=' + config,
                    'GENERATOR_PACKAGE=chipyard', 'TOP=ChipTop', 'TB=none',
                    'build_dir=' + str(output), 'SBT=' + str(java / 'bin/java') + ' -jar ' + str(launcher)],
                       env=env, check=True)
    rtl = output / 'gen-collateral'
    raw = hashes(rtl, (str(p.relative_to(rtl)) for p in rtl.rglob('*') if p.is_file()))
    for name in ('apply_xcvu13p_gemmini_32x32_acc256_wide_uram.sh',
                 'apply_xcvu13p_soc_cache_bram.sh', 'apply_result_bram.sh'):
        subprocess.run(['bash', str(ROOT / 'source/postprocess' / name), str(rtl)], env=env, check=True)
    include = rtl / 'include'
    include.mkdir(exist_ok=True)
    for lane in range(3):
        name = f'gemmini_params_32x32_ws_dual_int8_dsp_inference_ram_custom{lane}_xcvu13p.h'
        header = workspace / 'generators/gemmini/software/gemmini-rocc-tests/include' / name
        if sha(header) != original['final_rtl_sha256']['include/' + name]:
            raise ValueError('Mathematical Gemmini ABI changed: ' + name)
        shutil.copyfile(header, include / name)
    shutil.copyfile(ROOT / 'tests/abi/activation_sram_map.h', include / 'activation_sram_map.h')
    if hashes(workspace, source_inputs) != source_inputs or build_inputs() != complete_inputs:
        raise ValueError('Scala changed during generation')
    context = dict(original, hardware_variant=ROOT.name, effective_scala=sources,
                   source_workspace=str(workspace), source_identity_sha256=digest,
                   build_inputs_sha256=complete_inputs,
                   dma_load_build_id=digest[:16], build_method='FULL_SOURCE_SBT',
                   source_recipe_sha256=prepared_sources().recipe_sha256,
                   generated_at_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
                   command_fifo_depth=16, command_fetch_entries=4, command_logical_max_get_bytes=128,
                   command_physical_max_get_bytes=64, raw_rtl_sha256=raw,
                   final_rtl_sha256=hashes(rtl, (str(p.relative_to(rtl)) for p in rtl.rglob('*') if p.is_file())),
                   whole_design_pnr='NOT_RUN', board_validation='NOT_RUN')
    (output / 'GENERATION_CONTEXT.json').write_text(json.dumps(context, indent=2) + '\n')
    if output == ROOT / 'generated':
        hardware = dict(schema=1, package_variant=ROOT.name,
                        artifact_origin='GENERATED_FROM_LOCAL_S1_SOURCES',
                        hardware_build_id=digest[:16], config=original['config'],
                        baseline_hardware_build_id='e037701c8d7cfc59',
                        generation_context='generated/GENERATION_CONTEXT.json',
                        generation_context_sha256=sha(output / 'GENERATION_CONTEXT.json'),
                        part='xcvu13p-fhga2104-2-i', clock_hz=100000000,
                        command_fifo_depth=16, command_fetch_entries=4,
                        command_record_bytes=32, command_logical_max_get_bytes=128,
                        command_physical_max_get_bytes=64, command_source_id=31,
                        dma_fixed_mode=2, dma_capability_word='0x00010004',
                        l2_banks=2, l2_capacity_kib=512,
                        physical_bytes_per_asram_bank=2359296,
                        bitstream=None, whole_design_pnr='NOT_RUN', board_validation='NOT_RUN',
                        software_compatibility='S1 ABI preserved; update hardware identity and bitstream binding')
        (ROOT / 'manifests/hardware.json').write_text(json.dumps(hardware, indent=2) + '\n')
    print('BATCH4_FULL_ELABORATION=PASS hardware_id=' + digest[:16] + ' output=' + str(output))


if __name__ == '__main__':
    main()
