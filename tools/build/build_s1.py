#!/usr/bin/env python3
"""Reconstruct/build the selected S1 project without replacing the validated bit."""
import argparse
import os
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools/check'))
from current_product import local_path, product


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('stage', choices=['elaborate', 'synth', 'bitstream'])
    parser.add_argument('--project', type=Path, required=True)
    parser.add_argument('--jobs', type=int, default=8)
    args = parser.parse_args()
    p = product()
    hw = local_path(p['hardware_directory'])
    directory = args.project.resolve()
    if (hw / 'build').resolve() not in directory.parents or args.jobs < 1:
        raise ValueError('Use a project below the selected hardware build/ and positive JOBS')
    subprocess.run([sys.executable, '-B', str(ROOT / 'tools/check/check_current_product.py')], check=True)
    project = directory / 's1.xpr'
    if not project.exists():
        subprocess.run(['make', '-C', str(hw), 'project', 'PROJECT_OUTPUT=' + str(directory)], check=True)
    env = dict(os.environ, S1_BUILD_PROJECT=str(project), S1_BUILD_STAGE=args.stage,
               S1_BUILD_JOBS=str(args.jobs), S1_HARDWARE_DIRECTORY=str(hw))
    subprocess.run([os.environ.get('VIVADO_BIN', 'vivado'), '-mode', 'batch', '-nojournal',
                    '-log', str(directory / (args.stage + '.vivado.log')), '-source',
                    str(ROOT / 'tools/build/build_s1.tcl')], cwd=directory, env=env, check=True)


if __name__ == '__main__':
    main()
