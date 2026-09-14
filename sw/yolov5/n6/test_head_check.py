#!/usr/bin/env python3
"""I: class-major references and actual C checker. P: transpose to physical layout,
inject errors. O: regression result. A: 王志瑞. T: 2026-09-10.
"""
from pathlib import Path
import subprocess
ROOT=Path(__file__).resolve().parents[3]
OUT=ROOT/'build/yolov5nu_n6_v4'
s=(ROOT/'sw/yolov5/n6/n6_runtime.h').read_text()
checker=s[s.index('extern const int8_t'):s.rindex('#endif')]
code='''#include <stdint.h>
#include <stdio.h>
#include <assert.h>
#include <string.h>
typedef int8_t elem_t;
'''+checker+'''
static elem_t logits[504000], scores[504000], dfl[25200];
static uint8_t mask[6300];
int main(void) {
 for(int p=0;p<6300;p++) {
  mask[p]=n6_ref_mask[p];
  for(int c=0;c<80;c++) {logits[p*80+c]=n6_ref_class_logits[c*6300+p];scores[p*80+c]=n6_ref_class_scores[c*6300+p];}
  for(int e=0;e<4;e++) dfl[p*4+e]=n6_ref_dfl[e*6300+p];
 }
 assert(n6_check_heads(logits,scores,dfl,mask));
 logits[123]^=1;assert(!n6_check_heads(logits,scores,dfl,mask));logits[123]^=1;
 scores[456]^=1;assert(!n6_check_heads(logits,scores,dfl,mask));scores[456]^=1;
 int p=0;while(!mask[p])p++;
 dfl[p*4+2]^=1;assert(!n6_check_heads(logits,scores,dfl,mask));dfl[p*4+2]^=1;
 mask[p]^=1;assert(!n6_check_heads(logits,scores,dfl,mask));mask[p]^=1;
 assert(n6_check_heads(logits,scores,dfl,mask));
 puts("PASS: location-major checker and four independent error injections");
}
'''
p=OUT/'test_head_check.c';p.write_text(code)
logs=[]
for image in ['025','036','142','404','650']:
 binary=OUT/'test_head_check'
 subprocess.run(['gcc','-O2',str(p),str(OUT/image/'reference.S'),'-o',str(binary)],check=True,capture_output=True)
 res=subprocess.run([str(binary)],check=True,capture_output=True,text=True)
 logs.append(image+'\n'+res.stdout)
(OUT/'test_head_check.log').write_text('\n'.join(logs));print('\n'.join(logs))
