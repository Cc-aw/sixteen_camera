#!/usr/bin/env python3
"""Run full-system synthesis and retain its input identity, status and logs."""
import argparse
import datetime
import fcntl
import hashlib
import json
import os
from pathlib import Path
import subprocess
import time

ROOT = Path(__file__).resolve().parents[2]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def utc():
    return datetime.datetime.now(datetime.timezone.utc).isoformat()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--project', type=Path, required=True)
    parser.add_argument('--report-dir', type=Path, required=True)
    parser.add_argument('--vivado', default='vivado')
    args = parser.parse_args()
    project = args.project.resolve()
    report = args.report_dir.resolve()
    if not project.is_file():
        raise SystemExit(f'Project missing: {project}')
    report.mkdir(parents=True, exist_ok=True)
    state_path = report / 'state.json'
    if state_path.exists():
        raise SystemExit('Existing synthesis record retained; select a new report directory')
    lock = (ROOT / 'build/video_project.lock').open('w')
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        raise SystemExit('Another build owns the Vivado project lock')
    subprocess.run(['python3', 'tools/check/check_current_product.py'], cwd=ROOT, check=True)
    product = json.loads((ROOT / 'hw/manifests/current.json').read_text())
    context_path = ROOT / product['generation_context']
    context_hash = sha(context_path)
    command = [args.vivado, '-mode', 'batch', '-source',
               str(ROOT / 'tools/build/build_video_synthesis.tcl'),
               '-log', str(report / 'vivado.log'), '-journal', str(report / 'vivado.jou')]
    state = dict(build_state='RUNNING', full_synthesis_state='STARTING', start_utc=utc(),
                 supervisor_pid=os.getpid(), command=command, project=str(project),
                 generation_context_sha256=context_hash, implementation='NOT_RUN',
                 bitstream='NOT_GENERATED', timing_scope='UNPLACED_SYNTHESIS_ESTIMATE')

    def save():
        state['updated_utc'] = utc()
        temp = state_path.with_suffix('.tmp')
        temp.write_text(json.dumps(state, indent=2) + '\n')
        temp.replace(state_path)

    save()
    env = dict(os.environ, VIVADO_PROJECT=str(project), SOC_VARIANT=product['hardware_alias'],
               SYNTHESIS_REPORT_DIR=str(report))
    print(f'FULL_SYSTEM_SYNTHESIS_LAUNCH state={state_path}', flush=True)
    with (report / 'console.log').open('w') as output:
        proc = subprocess.Popen(command, cwd=report, env=env, stdout=output, stderr=subprocess.STDOUT)
        state['vivado_pid'] = proc.pid
        save()
        while proc.poll() is None:
            phase = report / 'phase.txt'
            if phase.exists():
                state['full_synthesis_state'] = phase.read_text().strip()
            save()
            time.sleep(5)
    state['exit_code'] = proc.returncode
    state['ended_utc'] = utc()
    result = report / 'result.txt'
    passed = (proc.returncode == 0 and result.exists() and
              'SYNTHESIS=PASS' in result.read_text() and sha(context_path) == context_hash)
    state['build_state'] = 'PASS' if passed else 'FAIL'
    state['full_synthesis_state'] = 'COMPLETE' if passed else 'FAILED'
    if passed:
        values = dict(line.split('=', 1) for line in result.read_text().splitlines() if '=' in line)
        checkpoint = Path(values['CHECKPOINT'])
        state['checkpoint'] = str(checkpoint)
        state['checkpoint_sha256'] = sha(checkpoint)
        state['result_sha256'] = sha(result)
    save()
    print(f"FULL_SYSTEM_SYNTHESIS={state['build_state']}", flush=True)
    return 0 if passed else 1


if __name__ == '__main__':
    raise SystemExit(main())
