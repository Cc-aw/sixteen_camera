#!/usr/bin/env python3
"""Explicit bitstream/ELF download and capture; preflight never opens hardware."""
import argparse
import datetime
import json
import os
from pathlib import Path
import re
import shutil
import subprocess

from build import ROOT,ELF,check,sha,write


def target_bitstream(manifest):
    target=manifest['config']['target']
    if target.get('bitstream') is None or target.get('bitstream_sha256') is None:
        raise ValueError('Merged candidate has no bitstream; programming is unavailable')
    bit=(ROOT.parents[2]/target['bitstream']).resolve()
    if not bit.is_file(): raise ValueError('Missing target bitstream: '+str(bit))
    if sha(bit)!=target['bitstream_sha256']:
        raise ValueError('Target bitstream SHA-256 mismatch: '+str(bit))
    return bit


def bitstream_command(manifest,env):
    bit=target_bitstream(manifest)
    vivado=os.environ.get('VIVADO_BIN') or 'vivado'
    if not shutil.which(vivado): raise ValueError('Missing Vivado; configure VIVADO_BIN in config.local.mk')
    env['TCL_SCRIPT']=str(ROOT/'program/program_bitstream.tcl')
    return bit,['bash',str(ROOT/'program/download_bitstream.sh'),
                '--vivado',vivado,'--bitstream',str(bit)]


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action',choices=('preflight','bitstream','load','uart'))
    parser.add_argument('--test',choices=('asram','model','diagnostic'),default='asram')
    parser.add_argument('--run',default='asram_01');parser.add_argument('--port',default='/dev/ttyACM0')
    a=parser.parse_args()
    if not re.fullmatch('[A-Za-z0-9_-]+',a.run):raise ValueError('Invalid RUN')
    directory=ROOT/'logs'/a.run
    if a.action=='uart':
        directory.mkdir(parents=True,exist_ok=True);log=directory/(a.test+'.log')
        if log.exists():raise ValueError('Existing UART log retained; choose a new RUN')
        tool=os.environ.get('TIO_BIN') or 'tio'
        if not shutil.which(tool):raise ValueError('Missing tio')
        return subprocess.call([tool,'-b','115200','-d','8','-s','1','-p','none','-f','none','-l',str(log),a.port])
    manifest=check();env=dict(os.environ,ELF_FILE=str(ELF),
        OPENOCD_CFG=str(ROOT/'program/openocd/openocd-bscan.cfg'))
    command=['bash',str(ROOT/'program/run_firmware.sh'),'--no-build']
    if a.action=='preflight':
        if manifest['config']['target'].get('bitstream') is not None:
            _,download=bitstream_command(manifest,env)
            subprocess.run(download+['--check'],check=True,env=env)
        else:print('BITSTREAM=NOT_GENERATED firmware_audit_only=1')
        subprocess.run(command+['--check'],check=True,env=env)
        from build_yolo import check as yolo_check
        yolo=yolo_check()
        for artifact in yolo['artifacts'].values():
            env['ELF_FILE']=str(ROOT/artifact['path'])
            subprocess.run(command+['--check'],check=True,env=env)
        print('ASRAM_PREFLIGHT=PASS board_accessed=0');return 0
    if a.action=='bitstream':
        bit,download=bitstream_command(manifest,env)
        receipt=directory/'bitstream.json'
        if receipt.exists():raise ValueError('Existing bitstream receipt retained; choose a new RUN')
        directory.mkdir(parents=True,exist_ok=True)
        env['LOG_FILE']=str(directory/'vivado_program.log')
        subprocess.run(download,check=True,env=env)
        record=dict(schema=1,file=str(bit),sha256=manifest['config']['target']['bitstream_sha256'],
            hardware_build_id=manifest['config']['target']['hardware_build_id'],
            software_build_id=manifest['build_id'],run=a.run,
            programmed_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
            identity='Host programming receipt; firmware checks hardware build ID on startup')
        write(receipt,record)
        write(ROOT/'logs/last_programmed_bitstream.json',record)
        print('ASRAM_BITSTREAM_DOWNLOAD=PASS hardware_id='+record['hardware_build_id'])
        return 0
    target_bitstream(manifest)
    if a.test!='asram':
        from build_yolo import check as yolo_check
        yolo=yolo_check();artifact=yolo['artifacts'][a.test]
        env['ELF_FILE']=str(ROOT/artifact['path'])
        elf_sha=artifact['sha256']
    else:elf_sha=manifest['elf_sha256']
    directory.mkdir(parents=True,exist_ok=True);receipt=directory/(a.test+'.load.json')
    if receipt.exists():raise ValueError('Existing load receipt retained; choose a new RUN')
    env['OPENOCD_LOG']=str(directory/('openocd.log' if a.test=='asram' else a.test+'.openocd.log'))
    subprocess.run(command,check=True,env=env)
    write(directory/(a.test+'.manifest.json'),yolo if a.test!='asram' else manifest)
    write(receipt,dict(test=a.test,build_id=manifest['build_id'],elf_sha256=elf_sha,
        hardware_build_id=manifest['config']['target']['hardware_build_id'],
        bitstream_receipt=json.loads((ROOT/'logs/last_programmed_bitstream.json').read_text())
            if (ROOT/'logs/last_programmed_bitstream.json').exists() else None,
        loaded_utc=datetime.datetime.now(datetime.timezone.utc).isoformat()))
    return 0


if __name__=='__main__':raise SystemExit(main())
