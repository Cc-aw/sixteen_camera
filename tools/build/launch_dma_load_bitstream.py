#!/usr/bin/env python3
"""Supervise a complete private bitstream build, publishing synthesis separately."""
import argparse
import datetime
import fcntl
import importlib.util
import json
import os
import re
import signal
from pathlib import Path
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/soc'))
spec = importlib.util.spec_from_file_location('dma_candidate', ROOT/'tools/soc/dma_load_candidate.py')
candidate = importlib.util.module_from_spec(spec)
spec.loader.exec_module(candidate)


def utc():
    return datetime.datetime.now(datetime.timezone.utc).isoformat()


def timing_summary(path):
    body=path.read_text().split('Design Timing Summary',1)[1]
    row=re.search(r'^\s*(-?\d+\.\d+)\s+(-?\d+\.\d+)\s+(\d+)\s+(\d+)\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)\s+(\d+)\s+(\d+)\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)\s+(\d+)\s+(\d+)\s*$',body,re.M)
    if not row:raise ValueError('Missing setup/hold/pulse timing summary')
    return dict(wns_ns=float(row[1]),whs_ns=float(row[5]),wpws_ns=float(row[9]),
                setup_failing_endpoints=int(row[3]),hold_failing_endpoints=int(row[7]),pulse_failing_endpoints=int(row[11]))


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--context', type=Path, required=True)
    p.add_argument('--report-dir', type=Path, required=True)
    p.add_argument('--verification', type=Path, required=True)
    p.add_argument('--vivado', default='/mnt/data/Vivado/Vivado/2023.2/bin/vivado')
    p.add_argument('--check', action='store_true')
    args = p.parse_args()
    context_path = args.context.resolve()
    context, rtl = candidate.validate(context_path)
    evidence = json.loads(args.verification.read_text())
    if evidence['status'] != 'READY_FOR_BITSTREAM' or evidence['build_id'] != context['dma_load_build_id']:
        raise SystemExit('Candidate has not passed all required verification')
    for path, expected in evidence['sha256'].items():
        if candidate.sha(Path(path)) != expected:
            raise SystemExit('Verification input changed: ' + path)
    out = args.report_dir.resolve()
    allowed = (ROOT/'build/experiments/dma_load').resolve()
    if allowed not in out.parents:
        raise SystemExit('Use an independent directory below build/experiments/dma_load')
    version = subprocess.check_output([args.vivado,'-version'],text=True)
    if '2023.2' not in version:
        raise SystemExit('Vivado 2023.2 required')
    if args.check:
        print('DMA_LOAD_FULL_BUILD_PREFLIGHT_PASS')
        return 0
    out.mkdir(parents=True,exist_ok=False)
    signal.signal(signal.SIGHUP,signal.SIG_IGN)
    project = out/'project/sixteen_camera.xpr'
    state_path = out/'state.json'
    state = dict(build_state='RUNNING', phase='STARTING', synthesis_state='PENDING',
                 bitstream='NOT_GENERATED', board_run='NOT_RUN', started_utc=utc(),
                 supervisor_pid=os.getpid(), project=str(project), rtl=str(rtl),
                 generation_context=str(context_path), generation_context_sha256=candidate.sha(context_path),
                 build_id=context['dma_load_build_id'],l2_kib=512,l2_banks=2)
    inputs={str(path):candidate.sha(path) for directory in
        ('hw/rtl','hw/constraints','hw/ip','hw/manifests','hw/vivado','tools/build')
        for path in (ROOT/directory).rglob('*') if path.is_file() and path.suffix in
        ('.v','.sv','.vh','.svh','.vhd','.vhdl','.xdc','.tcl','.json','.py')}
    inputs.update(evidence['sha256'])
    (out/'build_input_sha256.json').write_text(json.dumps(inputs,indent=2)+'\n')
    state['input_integrity']='CHECKED_AT_LAUNCH'

    def save():
        state['updated_utc']=utc()
        temp=state_path.with_suffix('.tmp')
        temp.write_text(json.dumps(state,indent=2)+'\n')
        temp.replace(state_path)

    def result_values(path):
        return dict(line.split('=',1) for line in path.read_text().splitlines() if '=' in line)

    # IP/BD outputs belong to this new private XPR. Serialize access to that
    # project, while permitting its synthesis alongside another project's
    # implementation. Full implementations share the repository resource lock.
    with (out/'project.lock').open('a') as lock, (ROOT/'build/video_project.lock').open('a') as implementation_lock:
        fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
        implementation_locked=False
        implementation_wait_reported=False
        state['locking_policy']='PRIVATE_PROJECT_SYNTHESIS_GLOBAL_IMPLEMENTATION'
        env=dict(os.environ,DMA_LOAD_CANDIDATE_CONTEXT=str(context_path),VIVADO_PROJECT=str(project),
                 DMA_LOAD_REPORT_DIR=str(out),SOC_VARIANT='dma_load_512kib_2bank',SOC_CONFIG=context['config'])
        command=[args.vivado,'-mode','batch','-source',str(ROOT/'tools/build/build_dma_load_bitstream.tcl'),
                 '-log',str(out/'vivado.log'),'-journal',str(out/'vivado.jou')]
        state['command']=command
        save()
        print('DMA_LOAD_FULL_BITSTREAM_STARTED state='+str(state_path),flush=True)
        with (out/'console.log').open('w') as log:
            process=subprocess.Popen(command,cwd=out,env=env,stdout=log,stderr=subprocess.STDOUT,start_new_session=True)
            state['vivado_pid']=process.pid
            save()
            while process.poll() is None:
                phase=out/'phase.txt'
                if phase.is_file():state['phase']=phase.read_text().strip()
                synthesis=out/'synthesis_result.txt'
                if synthesis.is_file() and state['synthesis_state'] == 'PENDING':
                    values=result_values(synthesis)
                    checkpoint=Path(values['CHECKPOINT'])
                    if values['SYNTHESIS']=='PASS' and checkpoint.is_file():
                        changed=[path for path,expected in inputs.items() if candidate.sha(Path(path))!=expected]
                        state.update(synthesis_state='INPUTS_CHANGED' if changed else 'PASS',
                                     input_integrity='CHANGED' if changed else 'UNCHANGED_THROUGH_SYNTHESIS',
                                     changed_inputs=changed,synthesis_completed_utc=utc(),
                                     synthesis_checkpoint=str(checkpoint),synthesis_checkpoint_sha256=candidate.sha(checkpoint))
                        print('DMA_LOAD_FULL_SYNTHESIS_'+state['synthesis_state']+' checkpoint='+str(checkpoint),flush=True)
                if state['synthesis_state']=='PASS' and state['phase']=='WAITING_IMPLEMENTATION_LOCK' and not implementation_locked:
                    try:
                        fcntl.flock(implementation_lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
                        implementation_locked=True
                        state['implementation_lock']='ACQUIRED'
                        (out/'implementation.ready').write_text(utc()+'\n')
                        print('DMA_LOAD_IMPLEMENTATION_LOCK_ACQUIRED',flush=True)
                    except BlockingIOError:
                        state['implementation_lock']='WAITING_OTHER_BUILD'
                        if not implementation_wait_reported:
                            print('DMA_LOAD_IMPLEMENTATION_QUEUED_WAITING_OTHER_BUILD',flush=True)
                            implementation_wait_reported=True
                save()
                time.sleep(5)
            state.update(exit_code=process.returncode,ended_utc=utc())
        result=out/'result.txt'
        if process.returncode==0 and result.is_file():
            values=result_values(result)
            bit=Path(values['BITSTREAM'])
            timing=timing_summary(out/'routed_timing.rpt')
            timing_met=values['TARGET_MET']=='1' and min(timing[k]for k in ('wns_ns','whs_ns','wpws_ns'))>=0 and not any(timing[k]for k in ('setup_failing_endpoints','hold_failing_endpoints','pulse_failing_endpoints'))
            state.update(build_state='PASS' if timing_met else 'BITSTREAM_TIMING_UNMET',
                         bitstream=str(bit),bitstream_sha256=candidate.sha(bit),
                         routed_wns_ns=float(values['WNS_NS']),routed_whs_ns=float(values['WHS_NS']),
                         routed_timing_summary=timing)
        else:
            state['build_state']='FAIL'
        save()
        print('DMA_LOAD_FULL_BUILD='+state['build_state'],flush=True)
        return process.returncode


if __name__ == '__main__':
    raise SystemExit(main())
