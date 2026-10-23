#!/usr/bin/env python3
"""Run the source-level DMA planner/group/streaming regressions in isolation."""
import os
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]


def main():
    workspace = Path(os.environ.get('S3_WORKSPACE', str(ROOT / 'build/timing_workspace'))).resolve()
    if ROOT / 'build' not in workspace.parents:
        raise ValueError('Use the private generated S3 workspace')
    java = Path(os.environ['JAVA_HOME'])
    riscv = Path(os.environ['RISCV'])
    launcher = Path(os.environ['SBT_LAUNCH'])
    env = dict(os.environ, JAVA_HOME=str(java),
        COURSIER_CACHE=str(workspace / '.coursier/v1'),
        CHISEL_FIRTOOL_PATH=str(riscv / 'bin'))
    env['PATH'] = str(java / 'bin') + ':' + str(riscv / 'bin') + ':' + str(java.parents[1] / 'bin') + ':' + env['PATH']
    env['LD_LIBRARY_PATH'] = str(java.parents[1] / 'lib') + ':' + env.get('LD_LIBRARY_PATH', '')
    env['JAVA_TOOL_OPTIONS'] = (
        f'-Xmx12G -Xss8M -XX:ActiveProcessorCount=4 -Dsbt.global.base={workspace}/.sbt '
        f'-Dsbt.boot.directory={workspace}/.sbt/boot -Dsbt.ivy.home={workspace}/.ivy2 '
        '-Dsbt.server.autostart=false -Dsbt.server.forcestart=true -Dsbt.supershell=false')
    files = [ROOT / 'tests/merged_dma' / name for name in ('DmaLoadTest.scala', 'DmaLoadStreamingTest.scala')]
    files.append(ROOT / 'tests/timing/DmaLoadIngressTest.scala')
    sources = ','.join('file("' + str(path) + '")' for path in files)
    with tempfile.TemporaryDirectory(prefix='s2dma-') as runtime:
        env['XDG_RUNTIME_DIR'] = runtime
        subprocess.run([str(java / 'bin/java'), '-jar', str(launcher),
            'set chipyard_fpga / Compile / unmanagedSources ++= Seq(' + sources + ')',
            'chipyard_fpga/runMain gemmini.DmaLoadIngressTest',
            'chipyard_fpga/runMain gemmini.DmaLoadTest',
            'chipyard_fpga/runMain gemmini.DmaLoadStreamingTest'],
            cwd=workspace, env=env, check=True)
    print('S3_SOURCE_DMA_INGRESS_GROUP_STREAMING_PASS')


if __name__ == '__main__':
    main()
