#!/usr/bin/env python3
"""Capture UART before ELF startup, require terminal PASS, and audit the log."""
import argparse
import fcntl
import os
from pathlib import Path
import select
import signal
import subprocess
import sys
import termios
import time

from build import ROOT, write
from build_yolo import check
from analyze_yolo import parse


def stop_download(process):
    """Stop our own session, including descendants of an exited launcher."""
    if process is None:return
    try:os.killpg(process.pid,signal.SIGTERM)
    except ProcessLookupError:pass
    try:process.wait(timeout=10)
    except subprocess.TimeoutExpired:pass
    try:os.killpg(process.pid,signal.SIGKILL)
    except ProcessLookupError:pass
    process.wait()


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--test',choices=('asram','model','diagnostic'),required=True)
    parser.add_argument('--run',required=True)
    parser.add_argument('--port',default='/dev/ttyACM0')
    parser.add_argument('--timeout',type=float,default=1800)
    args=parser.parse_args()
    import re
    if not re.fullmatch('[A-Za-z0-9_-]+',args.run):raise ValueError('Invalid run name')
    from build import check as asram_check
    manifest=asram_check() if args.test=='asram' else check()
    directory=ROOT/'logs'/args.run
    directory.mkdir(parents=True,exist_ok=True)
    log=directory/(args.test+'.log')
    # Exclusive creation prevents accidental loss of earlier measurements.
    with log.open('xb') as output, (directory/'load_console.txt').open('x') as console:
        fd=os.open(args.port,os.O_RDWR|os.O_NOCTTY|os.O_NONBLOCK)
        previous=termios.tcgetattr(fd)
        process=None
        try:
            fcntl.flock(fd,fcntl.LOCK_EX|fcntl.LOCK_NB)
            settings=termios.tcgetattr(fd)
            settings[0]=settings[1]=settings[3]=0
            settings[2]=termios.CLOCAL|termios.CREAD|termios.CS8
            settings[4]=settings[5]=termios.B115200
            settings[6][termios.VMIN]=0;settings[6][termios.VTIME]=0
            termios.tcsetattr(fd,termios.TCSANOW,settings)
            termios.tcflush(fd,termios.TCIFLUSH)
            process=subprocess.Popen([sys.executable,'-B',str(ROOT/'scripts/program.py'),
                'load','--test',args.test,'--run',args.run],stdout=console,stderr=subprocess.STDOUT,start_new_session=True)
            deadline=time.monotonic()+args.timeout
            pending=b'';passed=False
            while time.monotonic()<deadline:
                if select.select([fd],[],[],0.5)[0]:
                    block=os.read(fd,65536)
                    if not block:raise RuntimeError('UART disconnected')
                    output.write(block);output.flush();pending+=block
                    while b'\n' in pending:
                        line,pending=pending.split(b'\n',1)
                        if line.startswith((b'ATSOFT1,FAIL,',b'ATSOFT1,TRAP,',b'ATSOFT1,PPU_DIFF,',b'ASRY1,DIFF,',b'ASRAM1,FAIL,',b'ASRAM1,TRAP,')):
                            raise RuntimeError(line.decode(errors='replace'))
                        if line.startswith(b'ASRAM1,PASS,' if args.test=='asram' else b'ASRY1,PASS,'):passed=True
                result=process.poll()
                if result not in (None,0):raise RuntimeError('ELF download failed; see '+str(console.name))
                if passed and result==0:break
            else:raise TimeoutError('Board suite timed out; UART retained at '+str(log))
            output.flush()
            receipt=directory/(args.test+'.load.json')
            if not receipt.is_file():raise RuntimeError('Missing successful ELF load receipt')
            if args.test=='asram':
                from analyze import parse as accept
            else:accept=parse
            report=accept(log.read_text(),manifest)
            write(log.with_suffix('.summary.json'),report)
            print('S1_BOARD_SUITE='+report['status']+' test='+args.test+' log='+str(log),flush=True)
        finally:
            stop_download(process)
            termios.tcsetattr(fd,termios.TCSANOW,previous)
            os.close(fd)


if __name__=='__main__':main()
