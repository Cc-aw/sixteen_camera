#!/usr/bin/env python3
"""I: v6/v7 generated sources and frozen capacity function.
P: verify isolated conv0 alignment, cache/credit preservation and capacity.
O: regression evidence. A: 王志瑞. T: 2026-09-10.
"""
from pathlib import Path
import re,subprocess,tempfile
R=Path(__file__).resolve().parents[3]
for image in ('025','036','142','404','650'):
 old=(R/'build/yolov5nu_n6_v6'/image/'main.c').read_text()
 new=(R/'build/yolov5nu_n6_v7'/image/'main.c').read_text();changed=[]
 def normalize(m):
  args=[x.strip() for x in m[1].split(',')]
  if args[28]=='yolov5nu_conv0_weights':
   assert list(map(int,args[20:27]))==[1,12,64,16,6,6,3]
   args[22]='66';changed.append(1)
  return 'tiled_conv('+', '.join(args)+');'
 restored=re.sub(r'tiled_conv\(([^;]+)\);',normalize,new).replace('n6_port_v7_conv0_align','n6_port_v6_conv_tiles')
 assert restored==old and len(changed)==1
 print(image+': PASS only conv0 tile width 66 -> 64 and revision changed')
for f in ('n6_runtime.h','n6_credit_profile.h'):
 assert (R/'sw/yolov5/n6'/f).read_bytes()==(R/'debug/yolov5nu_n6_v6_20260910/source'/f).read_bytes()
with tempfile.TemporaryDirectory() as d:
 exe=Path(d)/'capacity'
 subprocess.run(['gcc',str(R/'debug/yolov5nu_n6_v6_20260910/conv0_analysis/capacity.c'),'-o',str(exe)],check=True)
 assert subprocess.check_output([str(exe)],text=True).splitlines()==['4081 792','3965 768']
print('PASS unchanged cache/credit runtime; exact capacity formula: candidate SPAD=3965 ACC=768')
