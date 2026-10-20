#!/usr/bin/env python3
"""Explicit manual downloads; preflight does not access the board."""
import argparse,datetime,json,os,re,shutil,subprocess
from build import ROOT,ELF,BIT,BIT_SHA,HW_ID,check,sha

def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('action',choices=['load','bitstream','preflight','uart']);p.add_argument('--run',default='video_01');p.add_argument('--port',default='/dev/ttyACM0');a=p.parse_args()
 if not re.fullmatch('[A-Za-z0-9_-]+',a.run):raise ValueError('Invalid RUN')
 d=ROOT/'logs'/a.run
 if a.action=='uart':
  d.mkdir(parents=True,exist_ok=True);log=d/'video.log'
  if log.exists():raise ValueError('Log exists; choose a new RUN')
  return subprocess.call(['tio','-b','115200','-d','8','-s','1','-p','none','-f','none','-l',str(log),a.port])
 manifest=check();env=dict(os.environ,ELF_FILE=str(ELF),TCL_SCRIPT=str(ROOT/'program/program_bitstream.tcl'),OPENOCD_CFG=str(ROOT/'program/openocd/openocd-bscan.cfg'))
 load=['bash',str(ROOT/'program/run_firmware.sh'),'--no-build']
 if a.action in ('bitstream','preflight'):
  if not BIT.is_file() or sha(BIT)!=BIT_SHA:raise ValueError('Frozen S1 bitstream missing or SHA mismatch')
  download=['bash',str(ROOT/'program/download_bitstream.sh'),'--vivado',os.environ.get('VIVADO_BIN','vivado'),'--bitstream',str(BIT)]
 if a.action=='preflight':
  subprocess.run(load+['--check'],env=env,check=True);subprocess.run(download+['--check'],env=env,check=True)
  print('S1RT_PREFLIGHT=PASS board_accessed=0');return 0
 d.mkdir(parents=True,exist_ok=True);receipt=d/(a.action+'.json')
 if receipt.exists():raise ValueError('Receipt exists; choose a new RUN')
 env['OPENOCD_LOG']=str(d/'openocd.log');env['LOG_FILE']=str(d/'vivado_program.log')
 subprocess.run(download if a.action=='bitstream' else load,env=env,check=True)
 receipt.write_text(json.dumps(dict(action=a.action,build_id=manifest['build_id'],elf_sha256=manifest['elf_sha256'],hardware_build_id=HW_ID,bitstream_sha256=BIT_SHA,time_utc=datetime.datetime.now(datetime.timezone.utc).isoformat()),indent=2)+'\n')
 return 0
if __name__=='__main__':raise SystemExit(main())
