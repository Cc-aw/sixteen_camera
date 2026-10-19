#!/usr/bin/env python3
"""Compile local source closure and elaborate a diagnostic three-Gemmini SoC.

This explicit cached-jar diagnostic does not replace the prepared-workspace
production generator or claim a deliverable candidate/CPU execution result.
"""
import argparse
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess

FEATURE = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--workspace', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--disabled', action='store_true')
    args = parser.parse_args()
    cy, out = args.workspace.resolve(), args.output.resolve()
    out.mkdir(parents=True, exist_ok=False)
    classes = out / 'classes'; classes.mkdir()
    spec = importlib.util.spec_from_file_location('asram_generator', FEATURE / 'scripts/build_soc.py')
    generator = importlib.util.module_from_spec(spec); spec.loader.exec_module(generator)
    sources = sorted((FEATURE / 'activation_sram/scala').glob('*.scala'))
    sources += sorted((FEATURE / 'command_frontend/scala').glob('*.scala'))
    sources += sorted((FEATURE / 'command_frontend/integration').rglob('*.scala'))
    sources += sorted((FEATURE / 'soc_shell/npu100_video/src/main/scala/gemmini').glob('*.scala'))
    sources += sorted((FEATURE / 'soc_shell/memory_parallel_v3/scala').glob('*.scala'))
    hashes = {str(p.relative_to(FEATURE)): generator.digest(p) for p in sources}
    resource = classes / 'vsrc'; resource.mkdir()
    store = FEATURE / 'activation_sram/resources/activation_sram_store.sv'
    shutil.copy2(store, resource)
    jar = cy / '.classpath_cache/chipyard_fpga.jar'
    jar_hash = generator.digest(jar)
    identity = hashlib.sha256(json.dumps(dict(sources=hashes, dependency_jar=jar_hash,
        store=generator.digest(store), enabled=not args.disabled), sort_keys=True).encode()).hexdigest()
    env = generator.environment(cy); env.pop('JAVA_TOOL_OPTIONS', None)
    env.update(ACTIVATION_SRAM_ENABLED='0' if args.disabled else '1', DMA_LOAD_BUILD_ID=identity[:16])
    java = cy / '.conda-env/lib/jvm/bin/java'
    cache = cy / '.coursier/v1/https/repo1.maven.org/maven2'
    compiler = cache / 'org/scala-lang/scala-compiler/2.13.16/scala-compiler-2.13.16.jar'
    plugin = cache / 'org/chipsalliance/chisel-plugin_2.13.16/6.7.0/chisel-plugin_2.13.16-6.7.0.jar'
    report = dict(status='RUNNING', scope='DIAGNOSTIC_SOURCE_OVERRIDE_ELABORATION',
                  candidate_accepted=False, cpu_rvv_executed=False, enabled=not args.disabled,
                  source_sha256=hashes, dependency_jar_sha256=jar_hash, diagnostic_build_id=identity[:16])
    commands = [
        ('compile', [java, '-Xmx6G', '-XX:ActiveProcessorCount=4', '-cp', f'{compiler}:{jar}',
                     'scala.tools.nsc.Main', '-classpath', jar, f'-Xplugin:{plugin}',
                     '-language:reflectiveCalls', '-d', classes, *sources]),
        ('elaboration', [java, '-Xmx16G', '-Xss8M', '-XX:ActiveProcessorCount=4',
                         '-cp', f'{classes}:{jar}', 'chipyard.Generator', '--target-dir', out,
                         '--name', generator.NAME, '--top-module', 'tsmcchip.fpga.taihangsoc.TaihangSoCFPGATestHarness',
                         '--legacy-configs', 'tsmcchip.fpga.taihangsoc:' + generator.CONFIG])]
    for name, command in commands:
        with (out / (name + '.log')).open('w') as log:
            result = subprocess.run(list(map(str, command)), cwd=out, env=env,
                                    stdout=log, stderr=subprocess.STDOUT, timeout=1200)
        report[name] = dict(command=list(map(str, command)), exit_code=result.returncode)
        if result.returncode:
            report['status'] = name.upper() + '_FAIL'
            (out / 'evidence.json').write_text(json.dumps(report, indent=2) + '\n')
            print((out / (name + '.log')).read_text()[-9000:])
            raise SystemExit(result.returncode)
    report['status'] = 'DIAGNOSTIC_ELABORATION_PASS'
    (out / 'evidence.json').write_text(json.dumps(report, indent=2) + '\n')
    print('ASRAM_THREE_GEMMINI_ELABORATION=PASS diagnostic_only=1 enabled=' + str(not args.disabled))


if __name__ == '__main__':
    main()
