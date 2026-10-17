#!/usr/bin/env python3
"""Explicit DMA candidate tests; never substitute the production RTL."""
import argparse
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('dma_generator', ROOT / 'tools/soc/build_triple32_v3_tensor.py')
generator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(generator)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--workspace', type=Path, required=True)
    parser.add_argument('--rtl', type=Path)
    parser.add_argument('--mode', choices=('legacy', 'read_coalesced', 'read_assembled', 'all'), default='all')
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--unit-only', action='store_true', help='Source-level Chisel unit tests, not candidate RTL acceptance')
    parser.add_argument('--reuse-integrations',type=Path,help='Validate existing first/layers/spad/fault result directories instead of rerunning them')
    args = parser.parse_args()
    cy, out = args.workspace.resolve(), args.output.resolve()
    generator.validate_workspace_sources(cy)
    context = None
    if not args.unit_only:
        if args.rtl is None:
            parser.error('--rtl is mandatory for candidate acceptance')
        rtl = args.rtl.resolve()
        context_file = rtl.parent / 'GENERATION_CONTEXT.json'
        context = json.loads(context_file.read_text())
        if (context['source_workspace'] != str(cy) or context['l2_banks'] != 2 or
                not context.get('dma_load_runtime_enable')):
            raise SystemExit('Incorrect DMA candidate identity')
        for relative, sha in context['final_rtl_sha256'].items():
            if generator.digest(rtl / relative) != sha:
                raise SystemExit('Candidate RTL hash mismatch: ' + relative)
        for relative,sha in context['effective_scala'].items():
            if generator.digest(cy/relative)!=sha:
                raise SystemExit('Candidate Scala snapshot mismatch: '+relative)
    out.mkdir(parents=True, exist_ok=False)
    classes = out / 'classes'
    classes.mkdir()
    env = generator.environment(cy)
    env.pop('JAVA_TOOL_OPTIONS', None)
    env['CHISEL_FIRTOOL_PATH'] = str(cy / '.conda-env/riscv-tools/bin')
    env['LD_LIBRARY_PATH'] = str(cy / '.conda-env/lib') + ':' + env.get('LD_LIBRARY_PATH', '')
    jar = cy / '.classpath_cache/chipyard_fpga.jar'
    java = cy / '.conda-env/lib/jvm/bin/java'
    cache = cy / '.coursier/v1/https/repo1.maven.org/maven2'
    compiler = cache / 'org/scala-lang/scala-compiler/2.13.16/scala-compiler-2.13.16.jar'
    plugin = cache / 'org/chipsalliance/chisel-plugin_2.13.16/6.7.0/chisel-plugin_2.13.16-6.7.0.jar'

    def run(command, name):
        with (out / name).open('w') as log:
            subprocess.run(list(map(str, command)), cwd=out, env=env, stdout=log,
                           stderr=subprocess.STDOUT, check=True, timeout=900)

    # Compile the tested implementations from the validated source snapshot,
    # so a previously assembled jar cannot hide local source changes.
    sources = [ROOT / 'hw/soc/source/shell/npu100_video/src/main/scala/gemmini' / name
               for name in ('CounterFile.scala', 'DmaLoadReadPlanner.scala', 'DmaLoadRowAssembler.scala', 'DmaLoadGroup.scala')]
    sources.append(ROOT / 'tests/rtl/scala/DmaLoadTest.scala')
    sources.append(ROOT / 'hw/soc/source/command_frontend/scala/CommandFrontend.scala')
    sources.append(ROOT / 'tests/rtl/scala/DmaLoadReaderTest.scala')
    run([java, '-Xmx4G', '-cp', f'{compiler}:{jar}', 'scala.tools.nsc.Main',
         '-classpath', jar, f'-Xplugin:{plugin}', '-language:reflectiveCalls',
         '-d', classes, *sources], 'compile.log')
    run([java, '-Xmx6G', '-XX:ActiveProcessorCount=4', '-cp', f'{classes}:{jar}',
         'gemmini.DmaLoadTest'], 'unit.log')
    run([java, '-Xmx6G', '-XX:ActiveProcessorCount=4', '-cp', f'{classes}:{jar}',
         'gemmini.DmaLoadReaderTest'], 'reader.log')
    for name in ('unit.log','reader.log'):
        if 'Assertion failed:' in (out/name).read_text():
            raise SystemExit('RTL assertion fired: '+str(out/name))
    report = dict(status='SOURCE_UNIT_PASS', candidate_rtl_accepted=False,
                  source_sha256={str(p.relative_to(ROOT)): generator.digest(p) for p in sources},
                  workspace=str(cy), mode=args.mode, classpath_jar_sha256=generator.digest(jar),
                  generation_context=None if context is None else dict(build_id=context['dma_load_build_id'],
                      path=str(context_file),sha256=generator.digest(context_file)))
    (out / 'unit_evidence.json').write_text(json.dumps(report, indent=2) + '\n')
    print((out / 'unit.log').read_text())
    if not args.unit_only:
        integration_dir=args.reuse_integrations.resolve() if args.reuse_integrations else out/'integration'
        if args.mode!='all':
            if args.reuse_integrations:parser.error('Reused acceptance requires --mode all')
            child=[sys.executable,str(ROOT/'tests/model/first_layer_s2d/test_real_gemmini.py'),
                '--rtl',str(rtl),'--output',str(integration_dir/'first'),'--dma-load-mode',args.mode]
            subprocess.run(child,check=True)
            print('CANDIDATE_SINGLE_MODE_SMOKE_PASS; all-mode acceptance not claimed')
            return
        if not args.reuse_integrations:
            integrations=[('first',ROOT/'tests/model/first_layer_s2d/test_real_gemmini.py',['--dma-load-mode','all']),
                ('layers',ROOT/'tests/model/dma_load/test_layers.py',[]),
                ('spad',ROOT/'tests/model/dma_load/test_spad.py',['--matrix']),
                ('fault',ROOT/'tests/model/dma_load/test_fault.py',[]),
                ('memory',ROOT/'tests/rtl/command_frontend/test_memory_widths.py',[])]
            for name,script,extra in integrations:
                subprocess.run([sys.executable,str(script),'--rtl',str(rtl),'--output',str(integration_dir/name),*extra],check=True)
        subprocess.run([sys.executable,str(ROOT/'tests/model/dma_load/analyze_traces.py'),str(integration_dir/'layers')],check=True)
        sys.path.insert(0,str(ROOT/'tools/build'))
        from verify_dma_load import integration
        evidence=integration(context_file,{k:integration_dir/k for k in ('first','layers','spad','fault','memory')})
        evidence['sha256'][str(out/'unit_evidence.json')]=generator.digest(out/'unit_evidence.json')
        (out/'integration_evidence.json').write_text(json.dumps(evidence,indent=2)+'\n')
        print('CANDIDATE_INTEGRATION_PASS build_id='+context['dma_load_build_id'])


if __name__ == '__main__':
    main()
