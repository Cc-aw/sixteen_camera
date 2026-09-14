#!/usr/bin/env python3
"""I: cache policy, generated C and frozen v2 C. P: test reuse/invalidation and
validate timing boundaries/tile substitution. O: regression log. A: 王志瑞. T: 2026-09-10.
"""
from pathlib import Path
import re,subprocess,json
R=Path(__file__).resolve().parents[3];O=R/'build/yolov5nu_n6_opt';P=R/'sw/yolov5/n6'
code=r'''
#include <assert.h>
#include <stdio.h>
#include "n6_cache_policy.h"
int main(void) {
 n6_cache_init((void*)0x100000,256);
 assert(n6_cache_need_line(0x100000));
 assert(!n6_cache_need_line(0x100000));
 assert(n6_cache_need_line(0x100040));
 assert(!n6_cache_need_line(0x100040));
 /* CPU access makes all potentially cached lines unknown again. */
 n6_cache_forget();assert(n6_cache_need_line(0x100000));assert(n6_cache_need_line(0x100040));
 assert(n6_cache_need_line(0xffffc0));assert(n6_cache_need_line(0xffffc0));
 assert(n6_cache_need_line(0x100100));assert(n6_cache_need_line(0x100100));
 n6_cache_init((void*)0x100003,256);assert(n6_cache_need_line(0x100040));assert(n6_cache_need_line(0x100040));
 n6_cache_init((void*)0x100000,4000000);assert(n6_cache_need_line(0x100040));assert(n6_cache_need_line(0x100040));
 puts("PASS cache line reuse, overlap, CPU invalidation, external range and invalid arena fallback");
}
'''
(O/'test_cache_host.c').write_text('/* I: cache policy. P: regression. O: checks. A: 王志瑞. T: 2026-09-10. */\n'+code)
subprocess.run(['gcc','-O2','-I'+str(P),str(O/'test_cache_host.c'),'-o',str(O/'test_cache_host')],check=True)
res=subprocess.run([str(O/'test_cache_host')],check=True,capture_output=True,text=True)
logs=[res.stdout]
for image in ['025','036','142','404','650']:
 s=(O/image/'main.c').read_text();old=(R/'build/yolov5nu_n6'/image/'main.c').read_text()
 start=s.index('uint64_t graph_start =');end=s.index('uint64_t inference_cycles =')
 assert not re.search(r'\b(?:printf|print_\w+)\s*\(',s[start:end])
 assert s.index('n6_check_heads(',end)>end
 calls=re.findall(r'tiled_conv\(([^;]+)\);',s)
 prior=re.findall(r'tiled_conv_auto\(([^;]+)\);',old)
 assert len(calls)==len(prior)==58
 for new,prev in zip(calls,prior):
  n=[x.strip() for x in new.split(',')];v=[x.strip() for x in prev.split(',')]
  assert n[:12]+n[15:20]+n[27:]==v
  assert n[12:15]==[v[3],v[4],v[4]]
  assert len(n)==37 and all(int(x)>0 for x in n[20:27])
 # Every timed CPU/RVV operation explicitly invalidates the cache knowledge.
 for m in re.finditer(r'uint64_t op_start = yolo_profile_begin\((PROFILE_\w+),',s):
  if m.group(1) not in ['PROFILE_CONV_TOTAL','PROFILE_ADD']:
   assert s[m.start()-32:m.start()].rstrip().endswith('n6_cache_forget();')
 assert 'N6_VERBOSE_UART' in s
 logs.append(image+': PASS 58 explicit Conv geometries, UART-free timed region, validation outside timer, CPU invalidation\n')
(O/'test_cache_timing.log').write_text(''.join(logs));print(''.join(logs))
