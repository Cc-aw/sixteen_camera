#!/usr/bin/env python3
"""I: frozen v8/v6 five-image generated artifacts. P: exact first-layer S2D2
input/weight mapping with timed input preparation. O: isolated M01 sources.
A: 王志瑞. T: 2026-09-11.
"""
from pathlib import Path
import re,json,shutil,hashlib
import numpy as np
R=Path(__file__).resolve().parents[3];BASE=R/'build/yolov5nu_n6_v8_ddr_v6';OUT=R/'build/yolov5nu_n6_m01'
IMAGES=('025','036','142','404','650')
def array(text,name,dtype=np.int8):
 m=re.search(r'\b'+name+r'\[[^\]]+\][^=]*=\s*\{([^}]+)\}',text)
 if not m: raise ValueError(name)
 return np.fromstring(m[1].replace('\n',''),sep=',',dtype=dtype)
def pack_weights(w):
 return w.reshape(3,2,3,2,3,16).transpose(0,2,1,3,4,5).copy().reshape(3,3,12,16)
def transform(s):
 assert 'n6_port_v8_ddr_v6' in s
 s=s.replace('n6_port_v8_ddr_v6','n6_port_m01_s2d2')
 # The additional buffer is separate from the existing lifetime-planned arena.
 pos=s.index('\n#ifndef YOLOV5NU_LAYER_STATS')
 s=s[:pos]+'''\n/* I: original input/weights. P: private packed first-layer storage.
 * O: unchanged output interface. A: 王志瑞. T: 2026-09-11. */
#include "n6_m01_pack.h"
#include "m01_weights.h"
static elem_t n6_m01_input[240*320*12] row_align(1);
'''+s[pos:]
 start='  uint64_t graph_start = yolo_profile_clock();'
 assert s.count(start)==1
 s=s.replace(start,'''  /* I: per-frame RGB. P: include input packing in inference clock.
   * O: explicit preparation and full-frame measurements. A: 王志瑞. T: 2026-09-11. */
  uint64_t inference_start = yolo_profile_clock();
  n6_m01_pack(yolov5nu_input, n6_m01_input, 480, 640);
  uint64_t prep_cycles = yolo_profile_clock() - inference_start;
'''+start)
 def conv(m):
  a=[x.strip() for x in m[1].split(',')]
  if a[28]!='yolov5nu_conv0_weights': return m[0]
  assert list(map(int,a[:12]))==[1,480,640,3,16,240,320,2,1,1,2,6]
  a[:12]=list(map(str,[1,240,320,12,16,240,320,1,1,1,1,3]));a[12]='12'
  a[20:27]=list(map(str,[1,16,64,16,3,3,12]));a[27]='n6_m01_input';a[28]='n6_m01_weights'
  return 'tiled_conv('+', '.join(a)+');'
 s=re.sub(r'tiled_conv\(([^;]+)\);',conv,s)
 s=s.replace('n6_flush(yolov5nu_input, (size_t)(1 * 480 * 640 * 3));','n6_flush(n6_m01_input, (size_t)(1 * 240 * 320 * 12));')
 s=s.replace('uint64_t inference_cycles = yolo_profile_clock() - graph_start;', 'uint64_t inference_cycles = yolo_profile_clock() - inference_start;')
 s=s.replace('input_preprocessing_included=0','input_preprocessing_included=1')
 s=s.replace('  uint64_t fps_x1000 =', '  printf("N6_PREP kind=s2d2 cycles=%lu bytes=921600 included_in_inference=1\\n", (unsigned long)prep_cycles);\n  uint64_t fps_x1000 =')
 return s

def main():
 OUT.mkdir(parents=True,exist_ok=True);manifest=[]
 for image in IMAGES:
  src=BASE/image;dst=OUT/image;dst.mkdir(exist_ok=True)
  params=next(src.glob('*params.h'));h=params.read_text()
  w=array(h,'yolov5nu_conv0_weights');assert w.size==1728
  packed=pack_weights(w).ravel()
  (dst/'m01_weights.h').write_text('/* I: original 6x6x3x16 weights. P: offline permutation. O: 3x3x12x16. A: 王志瑞. T: 2026-09-11. */\nstatic const elem_t n6_m01_weights[1728] row_align(1) = {\n'+','.join(map(str,packed.tolist()))+'\n};\n')
  (dst/'main.c').write_text(transform((src/'main.c').read_text()))
  shutil.copy2(params,dst/params.name);shutil.copy2(src/'reference.S',dst/'reference.S')
  manifest.append(dict(image=image,baseline_sha256=hashlib.sha256((src/'main.c').read_bytes()).hexdigest(),adapted_sha256=hashlib.sha256((dst/'main.c').read_bytes()).hexdigest(),weights_sha256=hashlib.sha256(packed.tobytes()).hexdigest()))
 (OUT/'sources.json').write_text(json.dumps(manifest,indent=2)+'\n')
if __name__=='__main__':main()
