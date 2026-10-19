#!/usr/bin/env python3
"""Reconstruct a private ASRAM project with reviewed physical hooks; launch no runs."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys

from physical_candidate import checked_candidate, FEATURE, REPO


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--context', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True, help='New private project/report directory')
    parser.add_argument('--vivado', default='/mnt/data/Vivado/Vivado/2023.2/bin/vivado')
    args = parser.parse_args()
    context, _ = checked_candidate(args.context)
    out = args.output.resolve()
    if not out.is_relative_to(REPO / 'build/experiments/dma_stream_asram') or out.exists():
        raise ValueError('Use a new output directory below build/experiments/dma_stream_asram')
    out.mkdir(parents=True)
    sources = list((FEATURE / 'constraints').rglob('*.tcl'))
    sources += [FEATURE / 'manifests/SOURCE_ORIGINS.json', Path(__file__),
                FEATURE / 'scripts/physical_candidate.py', FEATURE / 'scripts/audit.py',
                REPO / 'hw/vivado/create_project.tcl', REPO / 'hw/vivado/setup_vivado.tcl',
                REPO / 'hw/manifests/soc_manifest.tcl', REPO / 'hw/manifests/rtl_manifest.tcl',
                REPO / 'tools/build/default_video_run_settings.tcl']
    sources += list((REPO / 'hw/constraints').glob('*'))
    before = {str(p.relative_to(REPO)): sha(p) for p in sorted(sources) if p.is_file()}
    env = os.environ.copy()
    env['ASRAM_PYTHON'] = sys.executable
    # Vivado home/cache paths stay in the private output tree.
    env['XILINX_LOCAL_USER_DATA'] = 'no'
    env['XILINX_LOCAL_USER_DATA_USER'] = 'no'
    project = out / 'project/sixteen_camera.xpr'
    command = [args.vivado, '-mode', 'batch', '-source', str(FEATURE / 'constraints/configure_project.tcl'),
               '-log', str(out / 'vivado.log'), '-journal', str(out / 'vivado.jou'), '-tclargs',
               str(args.context.resolve()), str(project), str(out)]
    with (out / 'console.log').open('w') as log:
        subprocess.run(command, cwd=REPO, env=env, stdout=log, stderr=subprocess.STDOUT, check=True)
    if not (out / 'configured.txt').is_file():
        raise ValueError('Vivado did not complete configuration')
    for relative, expected in before.items():
        if sha(REPO / relative) != expected:
            raise ValueError('Physical flow changed during configuration: ' + relative)
    record = dict(schema=1, status='PROJECT_CONFIGURED_NOT_IMPLEMENTED',
                  project=str(project.relative_to(REPO)), generation_context=str(args.context.resolve().relative_to(REPO)),
                  generation_context_sha256=sha(args.context), build_id=context['dma_load_build_id'],
                  physical_input_sha256=before, synthesis_started=False,
                  implementation_started=False, bitstream_timing_gate=False,
                  board_accessed=False)
    (out / 'physical_context.json').write_text(json.dumps(record, indent=2) + '\n')
    print('ASRAM_PROJECT_CONFIGURED=PASS project=' + str(project) + ' runs_launched=0 timing_gate=none')


if __name__ == '__main__':
    main()
