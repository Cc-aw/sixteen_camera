#!/usr/bin/env python3
"""Bypass destructive post-route optimization for a verified DMA validation build."""
import argparse
import fcntl
import json
import os
from pathlib import Path
import signal
import subprocess
import time

import launch_dma_load_bitstream as build


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--context', type=Path, required=True)
    parser.add_argument('--verification', type=Path, required=True)
    parser.add_argument('--source-report-dir', type=Path, required=True)
    parser.add_argument('--report-dir', type=Path, required=True)
    parser.add_argument('--vivado', default='/mnt/data/Vivado/Vivado/2023.2/bin/vivado')
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    context_path = args.context.resolve()
    context, _ = build.candidate.validate(context_path)
    verification = args.verification.resolve()
    evidence = json.loads(verification.read_text())
    if evidence['status'] != 'READY_FOR_BITSTREAM' or evidence['build_id'] != context['dma_load_build_id']:
        raise ValueError('Functional verification does not match candidate')
    for path, expected in evidence['sha256'].items():
        if build.candidate.sha(Path(path)) != expected:
            raise ValueError('Verification input changed: ' + path)
    source = args.source_report_dir.resolve()
    previous = json.loads((source/'state.json').read_text())
    if (previous['synthesis_state'] != 'PASS'
            or previous['input_integrity'] != 'UNCHANGED_THROUGH_SYNTHESIS'
            or previous['build_id'] != context['dma_load_build_id']
            or previous['generation_context_sha256'] != build.candidate.sha(context_path)):
        raise ValueError('Original synthesis provenance does not match candidate')
    checkpoint = source/'project/sixteen_camera.runs/impl_1/top_wrapper_routed.dcp'
    out = args.report_dir.resolve()
    if (build.ROOT/'build/experiments/dma_load').resolve() not in out.parents:
        raise ValueError('Use an independent directory below build/experiments/dma_load')
    if out.exists():
        raise ValueError('Recovery output must be a new directory')
    if '2023.2' not in subprocess.check_output([args.vivado, '-version'], text=True):
        raise ValueError('Vivado 2023.2 required')
    inputs = {str(path): build.candidate.sha(path) for path in (
        checkpoint, source/'state.json', verification, context_path,
        Path(__file__).resolve(), Path(__file__).with_suffix('.tcl').resolve())}
    if args.check:
        print('DMA_LOAD_RECOVERY_PREFLIGHT_PASS', flush=True)
        return 0
    out.mkdir(parents=True)
    signal.signal(signal.SIGHUP, signal.SIG_IGN)
    (out/'input_sha256.json').write_text(json.dumps(inputs, indent=2)+'\n')
    state = dict(build_state='RUNNING', phase='WAITING_IMPLEMENTATION_LOCK',
                 started_utc=build.utc(), build_id=context['dma_load_build_id'],
                 source_checkpoint=str(checkpoint), source_checkpoint_sha256=inputs[str(checkpoint)],
                 source_build_state=str(source/'state.json'), verification=str(verification),
                 generation_context=str(context_path), supervisor_pid=os.getpid(),
                 change='USE_COMPLETE_ROUTE_SKIP_POST_ROUTE_PHYS_OPT',
                 bitstream='NOT_GENERATED', board_run='NOT_RUN', timing_met=False)

    def save():
        state['updated_utc'] = build.utc()
        temp = out/'state.tmp'
        temp.write_text(json.dumps(state, indent=2)+'\n')
        temp.replace(out/'state.json')

    save()
    print('DMA_LOAD_RECOVERY_STARTED state='+str(out/'state.json'), flush=True)
    try:
        with (build.ROOT/'build/video_project.lock').open('a') as lock:
            while True:
                try:
                    fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
                    break
                except BlockingIOError:
                    save()
                    time.sleep(5)
            command = [args.vivado, '-mode', 'batch', '-source',
                       str(Path(__file__).with_suffix('.tcl').resolve()),
                       '-log', str(out/'vivado.log'), '-journal', str(out/'vivado.jou'),
                       '-tclargs', str(checkpoint), str(out)]
            state.update(phase='STARTING_VIVADO', implementation_lock='ACQUIRED', command=command)
            save()
            with (out/'console.log').open('w') as log:
                process = subprocess.Popen(command, cwd=out, stdout=log,
                                           stderr=subprocess.STDOUT, start_new_session=True)
                state['vivado_pid'] = process.pid
                while process.poll() is None:
                    phase = out/'phase.txt'
                    if phase.is_file():
                        state['phase'] = phase.read_text().strip()
                    save()
                    time.sleep(5)
            state['exit_code'] = process.returncode
            if process.returncode != 0:
                raise RuntimeError('Vivado failed; see console.log')
            values = dict(line.split('=', 1) for line in (out/'result.txt').read_text().splitlines())
            bit = Path(values['BITSTREAM'])
            if bit.parent != out or not bit.is_file() or bit.stat().st_size == 0:
                raise ValueError('Invalid bitstream artifact')
            changed = [path for path, expected in inputs.items()
                       if build.candidate.sha(Path(path)) != expected]
            changed += [path for path, expected in evidence['sha256'].items()
                        if build.candidate.sha(Path(path)) != expected]
            state.update(changed_inputs=changed, input_integrity='CHANGED' if changed else 'UNCHANGED')
            if changed:
                raise ValueError('Recovery inputs changed during build')
            timing = build.timing_summary(out/'routed_timing.rpt')
            met = (min(timing[k] for k in ('wns_ns', 'whs_ns', 'wpws_ns')) >= 0
                   and not any(timing[k] for k in ('setup_failing_endpoints', 'hold_failing_endpoints', 'pulse_failing_endpoints')))
            state.update(build_state='PASS' if met else 'BITSTREAM_TIMING_UNMET', phase='COMPLETE',
                         bitstream=str(bit), bitstream_sha256=build.candidate.sha(bit),
                         bitstream_bytes=bit.stat().st_size, timing_met=met,
                         routed_timing_summary=timing, route_status=values)
    except Exception as exc:
        state.update(build_state='FAIL', error=str(exc))
        raise
    finally:
        state['ended_utc'] = build.utc()
        save()
        print('DMA_LOAD_RECOVERY='+state['build_state'], flush=True)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
