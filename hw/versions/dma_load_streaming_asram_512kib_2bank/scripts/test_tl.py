#!/usr/bin/env python3
"""Compile actual ASRAM/TileLink sources against explicit Chipyard dependencies."""
import argparse
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
    args = parser.parse_args()
    cy, out = args.workspace.resolve(), args.output.resolve()
    out.mkdir(parents=True, exist_ok=False)
    classes = out / 'classes'; classes.mkdir()
    spec = importlib.util.spec_from_file_location('asram_generator', FEATURE / 'scripts/build_soc.py')
    generator = importlib.util.module_from_spec(spec); spec.loader.exec_module(generator)
    env = generator.environment(cy)
    env.pop('JAVA_TOOL_OPTIONS', None)
    env['CHISEL_FIRTOOL_PATH'] = str(cy / '.conda-env/riscv-tools/bin')
    env['LD_LIBRARY_PATH'] = str(cy / '.conda-env/lib') + ':' + env.get('LD_LIBRARY_PATH', '')
    jar = cy / '.classpath_cache/chipyard_fpga.jar'
    java = cy / '.conda-env/lib/jvm/bin/java'
    cache = cy / '.coursier/v1/https/repo1.maven.org/maven2'
    compiler = cache / 'org/scala-lang/scala-compiler/2.13.16/scala-compiler-2.13.16.jar'
    plugin = cache / 'org/chipsalliance/chisel-plugin_2.13.16/6.7.0/chisel-plugin_2.13.16-6.7.0.jar'
    sources = sorted((FEATURE / 'activation_sram/scala').glob('*.scala'))
    sources.append(FEATURE / 'tests/ActivationSramTest.scala')
    resource = classes / 'vsrc'; resource.mkdir()
    store = FEATURE / 'activation_sram/resources/activation_sram_store.sv'
    # Only this simulation resource selects the byte model; production files
    # and generated candidates always instantiate the vendor primitive.
    (resource / store.name).write_text('`define ASRAM_BEHAVIORAL\n' + store.read_text())

    def run(command, name):
        with (out / name).open('w') as log:
            result = subprocess.run(list(map(str, command)), cwd=out, env=env,
                                    stdout=log, stderr=subprocess.STDOUT, timeout=900)
        if result.returncode:
            print((out / name).read_text()[-12000:])
            raise SystemExit(result.returncode)

    run([java, '-Xmx4G', '-cp', f'{compiler}:{jar}', 'scala.tools.nsc.Main',
         '-classpath', jar, f'-Xplugin:{plugin}', '-language:reflectiveCalls',
         '-d', classes, *sources], 'compile.log')
    run([java, '-Xmx6G', '-XX:ActiveProcessorCount=4', '-cp', f'{classes}:{jar}',
         'freechips.rocketchip.tile.commandfrontend.ActivationSramTest'], 'simulation.log')
    log = (out / 'simulation.log').read_text()
    if log.count('ASRAM_REAL_TL_BEHAVIORAL_STORE_PASS') != 3 or 'Assertion failed:' in log:
        raise SystemExit('ASRAM TL simulation did not finish cleanly')
    report = dict(status='REAL_TL_BEHAVIORAL_STORE_PASS', seed=171016,
                  banks_tested=3, cases=1767, cpu_rvv_executed=False, gemmini_executed=False,
                  vendor_primitive_simulated=False, three_lane_integration=False,
                  source_sha256={str(p.relative_to(FEATURE)): generator.digest(p) for p in sources + [store]},
                  dependency_jar_sha256=generator.digest(jar))
    (out / 'evidence.json').write_text(json.dumps(report, indent=2) + '\n')
    print(log[-3000:])


if __name__ == '__main__':
    main()
