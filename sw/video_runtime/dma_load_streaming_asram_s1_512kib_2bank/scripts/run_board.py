#!/usr/bin/env python3
"""Capture UART, explicitly load video firmware, sample ~100 live frames."""
import argparse,os,re,subprocess,sys,threading,time,json
from pathlib import Path
from build import ROOT,check
from uart import SerialPort

def sample_result(lines):
 ready=any(s.startswith('S1RT,READY,') for s in lines)
 ends=[s for s in lines if s.startswith('S1RT,SAMPLE_END,')]
 failures=[s for s in lines if ',FAIL,' in s or ',FAULT,' in s or ',TRAP,' in s or 'FATAL TRAP' in s]
 if not ready or not ends or failures or not any(s.startswith('S1RT,GUARDS_PASS,') for s in lines):return None
 end=dict(part.split('=',1) for part in ends[-1].split(',')[2:] if '=' in part)
 if any(end.get(k)!='0' for k in ('errors','held_tensor','heads')) or end.get('idle')!='1' or int(end.get('completed','0'))<100:return None
 streams={int(m.group(1)):int(m.group(2)) for s in lines if (m:=re.match(r'S1RT,STREAM,stream=(\d+),dispatched=\d+,completed=(\d+),',s))}
 if not any(streams.values()):return None
 return dict(status='PASS',scope='live input scheduling / completion / safe drain; detection accuracy requires visual or reference check',completed=int(end['completed']),active_streams=[s for s,n in streams.items() if n],stream_completed=streams)

def startup_command(live):
 return b'' if live else b'b'

def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--run',default='video_01');p.add_argument('--port',default='/dev/ttyACM0');p.add_argument('--timeout',type=float,default=180);p.add_argument('--live',action='store_true',help='continuous inference until Ctrl-C; no 100-frame stop');a=p.parse_args()
 if not re.fullmatch('[A-Za-z0-9_-]+',a.run):raise ValueError('Invalid RUN')
 check()
 d=ROOT/'logs'/a.run;d.mkdir(parents=True,exist_ok=True);log=d/'video.log'
 if log.exists():raise ValueError('Existing UART log retained; choose another RUN')
 lines=[];stop=threading.Event();done=threading.Event();fault=threading.Event();sample_sent=threading.Event();drained=threading.Event()
 port=SerialPort(a.port,115200,timeout=0.2,write_timeout=2)
 def reader():
  pending=b''
  with log.open('wb') as out:
   while not stop.is_set():
    try:data=port.read(4096)
    except OSError as error:
     line='S1RT,FAIL,reason=host_uart_read,error='+str(error)
     lines.append(line);out.write((line+'\n').encode());out.flush();print(line,flush=True);fault.set();return
    if not data:continue
    out.write(data);out.flush();pending+=data
    while b'\n' in pending:
     raw,pending=pending.split(b'\n',1);line=raw.decode('utf-8','replace').strip();lines.append(line);print(line,flush=True)
     if line.startswith('S1RT,READY,') and not sample_sent.is_set():
      command=startup_command(a.live)
      if command:port.write(command)
      sample_sent.set()
     if line.startswith('S1RT,SAMPLE_END,'):done.set()
     if line=='S1RT,STOPPED':drained.set()
     if ',FAIL,' in line or ',FAULT,' in line or ',TRAP,' in line or 'FATAL TRAP' in line:fault.set()
 t=threading.Thread(target=reader,daemon=True);t.start()
 try:
  subprocess.run([sys.executable,'-B',str(ROOT/'scripts/program.py'),'load','--run',a.run],check=True,env=os.environ)
  if a.live:
   print('S1RT_LIVE=RUNNING automatic_stop=0 stop=Ctrl-C',flush=True)
   try:
    while not fault.wait(0.2):pass
   except KeyboardInterrupt:
    print('S1RT_LIVE=STOP_REQUEST waiting_for_capture_and_jobs_to_drain',flush=True)
    port.write(b'sv');deadline=time.monotonic()+40
    while not drained.wait(0.2) and not fault.is_set() and time.monotonic()<deadline:pass
    if not drained.is_set() or fault.is_set():raise RuntimeError('Live stop failed; inspect '+str(log))
    print('S1RT_LIVE=STOPPED log='+str(log));return 0
   raise RuntimeError('Live runtime fault; inspect '+str(log))
  deadline=time.monotonic()+a.timeout
  while time.monotonic()<deadline and not done.wait(0.2) and not fault.is_set():pass
  if not done.is_set() and not fault.is_set():
   port.write(b'sv');time.sleep(1)
   raise TimeoutError('No 100-frame sample completion; inspect '+str(log))
  result=sample_result(lines)
  if result is None:raise ValueError('Live-video sample failed; inspect '+str(log))
  (d/'result.json').write_text(json.dumps(result,indent=2)+'\n')
  print('S1RT_BOARD_SAMPLE=PASS completed='+str(result['completed'])+' log='+str(log));return 0
 finally:
  stop.set();t.join(timeout=2);port.close()
if __name__=='__main__':raise SystemExit(main())
