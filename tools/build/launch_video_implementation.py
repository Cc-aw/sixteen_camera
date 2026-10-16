#!/usr/bin/env python3
"""Queue implementation after a recorded synthesis; retain durable artifact status."""
import argparse
import datetime
import fcntl
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import time

ROOT = Path(__file__).resolve().parents[2]


def utc():
    return datetime.datetime.now(datetime.timezone.utc).isoformat()


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--synthesis-state', type=Path, required=True)
    parser.add_argument('--report-dir', type=Path, required=True)
    parser.add_argument('--vivado', default='vivado')
    args = parser.parse_args()
    synth_path = args.synthesis_state.resolve()
    report = args.report_dir.resolve()
    report.mkdir(parents=True, exist_ok=True)
    state_path = report / 'state.json'
    if state_path.exists():
        raise SystemExit('Existing implementation record retained; select a new directory')
    state = dict(build_state='WAITING_FOR_SYNTHESIS', supervisor_pid=os.getpid(),
                 requested_utc=utc(), synthesis_state=str(synth_path),
                 bitstream='NOT_GENERATED', board_run='NOT_RUN')

    def save():
        state['updated_utc'] = utc()
        temp = state_path.with_suffix('.tmp')
        temp.write_text(json.dumps(state, indent=2) + '\n')
        temp.replace(state_path)

    save()
    print(f'FULL_IMPLEMENTATION_QUEUED state={state_path}', flush=True)
    while True:
        synth = json.loads(synth_path.read_text())
        if synth['build_state'] == 'PASS':
            break
        if synth['build_state'] != 'RUNNING':
            state.update(build_state='BLOCKED_SYNTHESIS_FAILED', ended_utc=utc())
            save()
            return 1
        time.sleep(5)
    with (ROOT / 'build/video_project.lock').open('w') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        project = Path(synth['project'])
        checkpoint = Path(synth['checkpoint'])
        if sha(checkpoint) != synth['checkpoint_sha256']:
            raise RuntimeError('Synthesis checkpoint changed')
        product = json.loads((ROOT / 'hw/manifests/current.json').read_text())
        if sha(ROOT / product['generation_context']) != synth['generation_context_sha256']:
            raise RuntimeError('Official RTL generation changed')
        frozen = json.loads((synth_path.parent / 'source_snapshot.json').read_text())
        for name, digest in frozen['sha256'].items():
            if sha(ROOT / name) != digest:
                raise RuntimeError('Synthesis input changed: ' + name)
        inputs = {str(p.relative_to(ROOT)): sha(p)
                  for directory in ('tools/build/triple32_v3', 'hw/constraints')
                  for p in (ROOT / directory).glob('*.tcl')}
        (report / 'implementation_inputs.json').write_text(json.dumps(inputs, indent=2) + '\n')
        command = [args.vivado, '-mode', 'batch', '-source',
                   str(ROOT / 'tools/build/continue_video_implementation.tcl'),
                   '-log', str(report / 'vivado.log'), '-journal', str(report / 'vivado.jou')]
        state.update(build_state='RUNNING', start_utc=utc(), project=str(project),
                     command=command, synthesis_checkpoint_sha256=sha(checkpoint),
                     generation_context_sha256=synth['generation_context_sha256'])
        save()
        with (report / 'console.log').open('w') as output:
            proc = subprocess.Popen(command, cwd=report, stdout=output, stderr=subprocess.STDOUT,
                                    env=dict(os.environ, VIVADO_PROJECT=str(project),
                                             IMPLEMENTATION_REPORT_DIR=str(report)))
            state['vivado_pid'] = proc.pid
            save()
            run_dir = project.parent / (project.stem + '.runs/impl_1')
            while proc.poll() is None:
                state['completed_steps'] = sorted(p.name for p in run_dir.glob('.*.end.rst'))
                state['failed_steps'] = sorted(p.name for p in run_dir.glob('.*.error.rst'))
                save()
                time.sleep(5)
        state.update(exit_code=proc.returncode, ended_utc=utc())
        result = report / 'result.txt'
        if proc.returncode == 0 and result.exists():
            values = dict(l.split('=', 1) for l in result.read_text().splitlines() if '=' in l)
            bit = Path(values['BITSTREAM'])
            artifact = report / 'video_triple32_v3_tensor_l2_1m_4bank.bit'
            shutil.copyfile(bit, artifact)
            state.update(build_state=('PASS' if values['TARGET_MET'] == '1'
                                      else 'BITSTREAM_TIMING_UNMET'), bitstream=str(artifact),
                         bitstream_sha256=sha(artifact), routed_wns_ns=float(values['WNS_NS']),
                         routed_whs_ns=float(values['WHS_NS']), timing_met=values['TARGET_MET'] == '1')
        else:
            state['build_state'] = 'FAIL'
        save()
        print(f"FULL_IMPLEMENTATION={state['build_state']}", flush=True)
        return proc.returncode


if __name__ == '__main__':
    raise SystemExit(main())
