#!/usr/bin/env python3
"""Start the standard complete bitstream flow; retain durable synthesis status."""
import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[2]
REPORT = ROOT / 'build/reports/head_l2_urgent'
STATE = REPORT / 'implementation_state.json'
PROJECT = ROOT / 'build/projects/triple32_v3_tensor/sixteen_camera.runs'


def utc():
    return datetime.datetime.now(datetime.timezone.utc).isoformat()


def save(state):
    temp = STATE.with_suffix('.tmp')
    temp.write_text(json.dumps(state, indent=2) + '\n')
    temp.replace(STATE)


def worker():
    log = REPORT / 'logs/full_implementation.log'
    state = dict(command='make bitstream', start_utc=utc(), start_epoch=time.time(),
                 supervisor_pid=os.getpid(), build_state='RUNNING', synthesis_state='WAITING',
                 log=str(log), project_runs=str(PROJECT), board_run='NOT_RUN',
                 model_throughput='NOT_MEASURED', speedup_2p8_or_3p0='NOT_CLAIMED')
    inputs = REPORT / 'input_manifest.json'
    if inputs.is_file():
        state['input_manifest'] = str(inputs)
        state['input_manifest_sha256'] = hashlib.sha256(inputs.read_bytes()).hexdigest()
    save(state)
    with log.open('w') as output:
        proc = subprocess.Popen(['make', 'bitstream'], cwd=ROOT, stdout=output, stderr=subprocess.STDOUT)
        state['build_pid'] = proc.pid
        save(state)
        while True:
            synth = PROJECT / 'synth_1'
            runlog = synth / 'runme.log'
            end = synth / '.vivado.end.rst'
            dcp = synth / 'top_wrapper.dcp'
            if runlog.exists() and runlog.stat().st_mtime >= state['start_epoch']:
                body = runlog.read_text(errors='replace')
                state['synthesis_state'] = 'RUNNING'
                if (end.exists() and end.stat().st_mtime >= state['start_epoch'] and
                    dcp.exists() and dcp.stat().st_mtime >= state['start_epoch'] and
                    'synth_design completed successfully' in body):
                    if 'synthesis_completed_utc' not in state:
                        state['synthesis_completed_utc'] = utc()
                    state['synthesis_state'] = 'COMPLETE'
                    state['synthesis_dcp'] = str(dcp)
                    state['synthesis_log'] = str(runlog)
                elif state.get('synthesis_completed_utc'):
                    state['synthesis_state'] = 'COMPLETE'
            state['updated_utc'] = utc()
            save(state)
            rc = proc.poll()
            if rc is not None:
                state['exit_code'] = rc
                state['build_state'] = 'PASS' if rc == 0 else 'FAIL'
                state['ended_utc'] = utc()
                text = log.read_text(errors='replace')
                # The standard script may produce a timing-unmet bitstream;
                # such an artifact must never be labeled an accepted candidate.
                if rc == 0 and 'TARGET_MET=1' not in text:
                    state['build_state'] = 'FAIL'
                    state['reason'] = 'Full-flow timing acceptance marker absent'
                if state['build_state'] == 'PASS':
                    lines = [line for line in text.splitlines() if line.startswith('VIDEO_BITSTREAM=')]
                    if lines:
                        bit = Path(lines[-1].split('=', 1)[1])
                        state['bitstream'] = str(bit)
                        state['bitstream_sha256'] = hashlib.sha256(bit.read_bytes()).hexdigest()
                save(state)
                return rc
            time.sleep(5)


def main():
    global REPORT, STATE
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--report-dir', type=Path, default=REPORT,
                        help='Independent durable record directory; an existing record is never overwritten')
    parser.add_argument('--worker', action='store_true')
    parser.add_argument('--status', action='store_true')
    args = parser.parse_args()
    REPORT = args.report_dir.resolve()
    STATE = REPORT / 'implementation_state.json'
    REPORT.mkdir(parents=True, exist_ok=True)
    (REPORT / 'logs').mkdir(exist_ok=True)
    if args.status:
        print(STATE.read_text() if STATE.exists() else 'NOT_RUN')
        return 0
    if args.worker:
        return worker()
    if STATE.exists():
        old = json.loads(STATE.read_text())
        if old['build_state'] == 'RUNNING':
            raise SystemExit('Candidate implementation already running; use --status')
        raise SystemExit('Existing implementation record retained; archive it before a new launch')
    # Never terminate another Vivado job. The actual build also obtains this lock.
    lock = subprocess.run(['flock', '-n', str(ROOT / 'build/video_project.lock'), 'true'])
    if lock.returncode:
        raise SystemExit('BLOCKED: another build owns the Vivado project lock')
    print(f'COMPLETE_IMPLEMENTATION_LAUNCH state={STATE}', flush=True)
    # Keep this supervisor attached to the long-running execution session.
    # Sandboxed command runners may reap a detached child when its caller exits.
    return worker()



if __name__ == '__main__':
    sys.exit(main())
