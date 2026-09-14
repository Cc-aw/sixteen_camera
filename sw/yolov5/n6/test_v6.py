#!/usr/bin/env python3
"""I: v5/v6 generated sources and real N6 capacity function. P: verify isolated
changes, capacity, expected submissions and credit hook. O: regression result.
A: 王志瑞. T: 2026-09-10.
"""
from pathlib import Path
import re,subprocess,tempfile
R=Path(__file__).resolve().parents[3]
expected={'yolov5nu_conv1_weights':[1,14,64,32,3,3,16], 'yolov5nu_conv7_weights':[1,13,64,64,3,3,32]}
for image in ('025','036','142','404','650'):
 old=(R/'build/yolov5nu_n6_v5'/image/'main.c').read_text();new=(R/'build/yolov5nu_n6_v6'/image/'main.c').read_text()
 changed=[]
 def normalize(m):
  args=[x.strip() for x in m[1].split(',')];name=args[28]
  if name in expected:
   assert list(map(int,args[20:27]))==expected[name];changed.append(name)
   args[20:27]=['1','14','67',args[23],'3','3','1']
  return 'tiled_conv('+', '.join(args)+');'
 restored=re.sub(r'tiled_conv\(([^;]+)\);',normalize,new)
 restored=restored.replace('#include "n6_credit_profile.h"\n','').replace('n6_port_v6_conv_tiles','n6_port_v5_timing')
 assert restored==old,'Unexpected non-tile source change'
 assert sorted(changed)==sorted(expected)
 assert new.index('#include "n6_credit_profile.h"')<new.index('#include "include/gemmini.h"')
 print(image+': PASS exactly two tile changes; all other generated computation/cache/timing code unchanged')
old=(R/'debug/yolov5nu_n6_v5_20260910/source/n6_runtime.h').read_text();new=(R/'sw/yolov5/n6/n6_runtime.h').read_text()
def flush(s): return s[s.index('static void n6_flush('):s.index('static void n6_scope_begin(')]
assert flush(old)==flush(new)
# Exercise the actual hook on host, including zero-wait admissions.
with tempfile.TemporaryDirectory() as d:
 p=Path(d);(p/'test.c').write_text('#include "n6_credit_profile.h"\n#include <assert.h>\nint main(){n6_credit_sample(0);n6_credit_sample(17);n6_credit_sample(23);assert(n6_credit_calls==3 && n6_credit_waits==2 && n6_credit_cycles==40);}\n')
 subprocess.run(['gcc','-I'+str(R/'sw/yolov5/n6'),str(p/'test.c'),'-o',str(p/'test')],check=True)
 subprocess.run([str(p/'test')],check=True)
subprocess.run(['python',str(R/'debug/yolov5nu_n6_v5_20260910/conv_analysis/check_tiles.py')],check=True,stdout=subprocess.DEVNULL)
print('PASS exact unchanged cache routine; actual credit hook; original capacity formula validates both candidates')
# I: complete v6 single-group trace. P: reject counter and tile-count drift.
# O: analyzer regression. A: 王志瑞. T: 2026-09-10.
from analyze_timing import analyze
fixture='''YOLOV5NU_N6 revision=n6_port_v6_conv_tiles
N6_INFERENCE cycles=110 uart_included=0 validation_included=0 input_preprocessing_included=0
YOLOV5NU_PROFILE records=1 graph_cycles=90 decode_cycles=10 nms_cycles=5
YOLOV5NU_PROFILE record=0 kind=Conv name=test cycles=80
N6_MEMORY op=yolov5nu_conv1_weights cycles=50
N6_CREDIT id=0 op=yolov5nu_conv1_weights calls=27 waited_calls=2 wait_cycles=10 accepted=27 retired=27
N6_SCOPE id=0 op=yolov5nu_conv1_weights total_cycles=70 cache_cycles=20 wait_cycles=10 other_cycles=40
N6_FLUSH id=0 scope=0 phase=0 address=0x80000000 bytes=64 cycles=20
N6_TIMING scopes=1 flushes=1 overflow=0 scope_cycles=70 cache_cycles=20 wait_cycles=10
N6_CACHE cycles=20 flushed_bytes=64
N6_CHECK class_logits_mismatches=0
N6_REPORT cycles=1000
N6_VALIDATION cycles=100
RESULT: PASS
'''
assert analyze(fixture)['credit'][0]['calls']=='27'
for bad in (fixture.replace('retired=27','retired=26'),fixture.replace('N6_CREDIT','LOST'),fixture.replace('=27','=28')):
 try: analyze(bad)
 except ValueError: pass
 else: raise AssertionError('invalid credit trace accepted')
print('PASS v6 analyzer validates hardware deltas and rejects missing/wrong admission counts')
