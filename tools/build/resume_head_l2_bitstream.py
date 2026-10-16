#!/usr/bin/env python3
"""Resume bitstream export from the existing routed DCP, without timing repair."""
import argparse
import datetime
import fcntl
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
REPORT = ROOT / 'build/reports/head_l2_urgent'
STATE = REPORT / 'implementation_state.json'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def utc():
    return datetime.datetime.now(datetime.timezone.utc).isoformat()


def save(state):
    temp = STATE.with_suffix('.tmp')
    temp.write_text(json.dumps(state, indent=2) + '\n')
    temp.replace(STATE)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--vivado', default=os.environ.get('VIVADO_BIN', shutil.which('vivado')))
    parser.add_argument('--checkpoint', type=Path, default=ROOT / 'build/projects/triple32_v3_tensor/sixteen_camera.runs/impl_1/top_wrapper_routed.dcp')
    args = parser.parse_args()
    if not args.vivado or not shutil.which(args.vivado):
        raise SystemExit('BLOCKED: set --vivado to Vivado 2023.2')
    source = args.checkpoint.resolve()
    if not source.is_file():
        raise SystemExit('BLOCKED: routed checkpoint unavailable')
    REPORT.mkdir(parents=True, exist_ok=True)
    lock = (ROOT / 'build/video_project.lock').open('a')
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        raise SystemExit('BLOCKED: another build owns the Vivado project lock')
    stamp = datetime.datetime.now().strftime('%Y%m%d_%H%M%S_%f')
    dest = ROOT / 'build/bitstream/triple32_v3_tensor' / ('resume_routed_' + stamp)
    dest.mkdir(parents=True, exist_ok=False)
    if STATE.exists():
        previous = json.loads(STATE.read_text())
        history = REPORT / 'history'
        history.mkdir(exist_ok=True)
        shutil.copy2(STATE, history / (stamp + '_implementation_state.json'))
    else:
        previous = {}
    bit = dest / 'video_triple32_v3_tensor_timing_unmet.bit'
    command = [args.vivado, '-mode', 'batch', '-source', str(ROOT / 'tools/build/resume_head_l2_bitstream.tcl'),
               '-log', str(dest / 'build.log'), '-journal', str(dest / 'build.jou'),
               '-tclargs', str(source), str(bit)]
    state = dict(command=command, start_utc=utc(), build_state='RUNNING',
                 operation='RESUME_ROUTED_EXPORT_NO_TIMING_REPAIR', synthesis_state='COMPLETE',
                 synthesis_dcp=previous.get('synthesis_dcp'), project_runs=previous.get('project_runs'),
                 source_checkpoint=str(source), source_checkpoint_sha256=sha(source),
                 results_directory=str(dest), log=str(dest / 'console.log'),
                 previous_build_log=previous.get('log'), BOARD_RUN='NOT_RUN',
                 MODEL_THROUGHPUT='NOT_MEASURED', SPEEDUP_2P8_OR_3P0='NOT_CLAIMED')
    save(state)
    print('ROUTED_EXPORT_STARTED=' + str(dest), flush=True)
    with (dest / 'console.log').open('w') as log:
        result = subprocess.run(command, cwd=dest, stdout=log, stderr=subprocess.STDOUT)
    state.update(exit_code=result.returncode, ended_utc=utc())
    status_file = dest / 'final_status.txt'
    if result.returncode == 0 and status_file.is_file() and bit.is_file():
        values = dict(line.split('=', 1) for line in status_file.read_text().splitlines() if '=' in line)
        state.update(bitstream=str(bit), bitstream_sha256=sha(bit), bitstream_bytes=bit.stat().st_size,
                     bitstream_state='GENERATED', timing_state='PASS' if values['TIMING_MET'] == '1' else 'FAIL',
                     build_state=values['BUILD'], wns_ns=float(values['WNS_NS']), whs_ns=float(values['WHS_NS']))
        print('BITSTREAM_GENERATED=' + str(bit), flush=True)
        print('TIMING=' + state['timing_state'], flush=True)
    else:
        state.update(build_state='FAIL', bitstream_state='NOT_GENERATED')
    save(state)
    return result.returncode if state['bitstream_state'] == 'GENERATED' else (result.returncode or 1)


if __name__ == '__main__':
    sys.exit(main())
