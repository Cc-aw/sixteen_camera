#!/usr/bin/env python3
"""Operator-only ELF load/capture. Preflight does not open the board."""
import argparse
import datetime
import os
from pathlib import Path
import re
import shutil
import subprocess

from build import ROOT,ELF,check,write


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action',choices=('preflight','load','uart'))
    parser.add_argument('--run',default='micro_01');parser.add_argument('--port',default='/dev/ttyACM0')
    a=parser.parse_args()
    if not re.fullmatch('[A-Za-z0-9_-]+',a.run):raise ValueError('Invalid RUN')
    directory=ROOT/'logs'/a.run
    if a.action=='uart':
        directory.mkdir(parents=True,exist_ok=True);log=directory/'micro.log'
        if log.exists():raise ValueError('Existing UART log retained; choose a new RUN')
        tool=os.environ.get('TIO_BIN') or 'tio'
        if not shutil.which(tool):raise ValueError('Missing tio')
        return subprocess.call([tool,'-b','115200','-d','8','-s','1','-p','none','-f','none','-l',str(log),a.port])
    manifest=check();env=dict(os.environ,ELF_FILE=str(ELF),
        OPENOCD_CFG=str(ROOT/'program/openocd/openocd-bscan.cfg'))
    command=['bash',str(ROOT/'program/run_firmware.sh'),'--no-build']
    if a.action=='preflight':
        subprocess.run(command+['--check'],check=True,env=env)
        print('MICRO_PREFLIGHT=PASS board_accessed=0');return 0
    directory.mkdir(parents=True,exist_ok=True);receipt=directory/'micro.load.json'
    if receipt.exists():raise ValueError('Existing load receipt retained; choose a new RUN')
    env['OPENOCD_LOG']=str(directory/'openocd.log')
    subprocess.run(command,check=True,env=env)
    write(receipt,dict(build_id=manifest['build_id'],elf_sha256=manifest['elf_sha256'],
        hardware_build_id=manifest['config']['target']['hardware_build_id'],
        loaded_utc=datetime.datetime.now(datetime.timezone.utc).isoformat()))
    return 0


if __name__=='__main__':raise SystemExit(main())
