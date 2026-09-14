#!/usr/bin/env python3
"""I: five real inputs, weights, generated M01 and original capacity formula.
P: compare actual scalar pack with independent layout mapping and all first-layer
int32 outputs; verify unchanged downstream graph. O: regression evidence.
A: 王志瑞. T: 2026-09-11.
"""
from pathlib import Path
import ctypes,re,subprocess,tempfile,json
import numpy as np
from prepare_m01 import R,BASE,OUT,IMAGES,array,pack_weights
results=[]
with tempfile.TemporaryDirectory() as d:
 p=Path(d)
 (p/'pack.c').write_text('#include "n6_m01_pack.h"\nvoid pack(const int8_t *a,int8_t *b,size_t h,size_t w){n6_m01_pack_scalar(a,b,h,w);}\n')
 subprocess.run(['gcc','-shared','-fPIC','-O2','-I'+str(R/'sw/yolov5/n6'),str(p/'pack.c'),'-o',str(p/'pack.so')],check=True)
 lib=ctypes.CDLL(str(p/'pack.so'));lib.pack.argtypes=[ctypes.c_void_p,ctypes.c_void_p,ctypes.c_size_t,ctypes.c_size_t]
 def scalar(x):
  out=np.full(x.size+128,0x55,dtype=np.int8);lib.pack(x.ctypes.data,out[64:-64].ctypes.data,x.shape[0],x.shape[1]);assert np.all(out[:64]==0x55) and np.all(out[-64:]==0x55)
  return out[64:-64].reshape(x.shape[0]//2,x.shape[1]//2,12)
 # Reproduce RVV strided addressing over several vector lengths and tails.
 for height,width in [(2,2),(6,14),(4,130),(2,642)]:
  x=np.random.default_rng(width).integers(-128,128,size=(height,width,3),dtype=np.int8);ref=scalar(x)
  for vlmax in (1,7,16,64,128):
   v=np.empty_like(ref);a=x.ravel();b=v.ravel()
   for y in range(height//2):
    for col in range(0,width//2,vlmax):
     vl=min(vlmax,width//2-col)
     for dy in range(2):
      for c in range(6):
       b[(y*(width//2)+col)*12+dy*6+c+np.arange(vl)*12]=a[(2*y+dy)*width*3+col*6+c+np.arange(vl)*6]
   assert np.array_equal(v,ref)
 for image in IMAGES:
  base=BASE/image;dst=OUT/image;h=next(base.glob('*params.h')).read_text()
  x=array(h,'yolov5nu_input').reshape(480,640,3);w=array(h,'yolov5nu_conv0_weights').reshape(6,6,3,16);bias=array(h,'yolov5nu_conv0_bias',np.int64)
  packed=scalar(x);ref=x.reshape(240,2,320,2,3).transpose(0,2,1,3,4).reshape(240,320,12)
  assert np.array_equal(packed,ref)
  wn=pack_weights(w);actual=array((dst/'m01_weights.h').read_text(),'n6_m01_weights').reshape(3,3,12,16)
  assert np.array_equal(actual,wn)
  bound=128*np.abs(w.astype(np.int64)).sum(axis=(0,1,2))+np.abs(bias);assert max(bound)<2**31
  oldpatch=np.lib.stride_tricks.sliding_window_view(np.pad(x,((2,2),(2,2),(0,0))), (6,6),axis=(0,1))[::2,::2].transpose(0,1,3,4,2).reshape(-1,108).astype(np.int32)
  newpatch=np.lib.stride_tricks.sliding_window_view(np.pad(packed,((1,1),(1,1),(0,0))), (3,3),axis=(0,1)).transpose(0,1,3,4,2).reshape(-1,108).astype(np.int32)
  oldacc=oldpatch @ w.reshape(108,16).astype(np.int32);newacc=newpatch @ wn.reshape(108,16).astype(np.int32)
  assert np.array_equal(oldacc,newacc)
  old=(base/'main.c').read_text();new=(dst/'main.c').read_text()
  calls=lambda s:re.findall(r'tiled_conv\([^;]+;',s)
  assert calls(old)[1:]==calls(new)[1:] and len(calls(new))==58
  # Everything after first Conv's following activation block is unchanged except reporting.
  suffix='    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.1/conv/Conv");'
  oa=old[old.index(suffix):old.index('  uint64_t graph_cycles =')];na=new[new.index(suffix):new.index('  uint64_t graph_cycles =')];assert oa==na
  a=new.index('uint64_t inference_start =');b=new.index('uint64_t inference_cycles =')
  assert new.index('n6_m01_pack(yolov5nu_input',a)<new.index('uint64_t graph_start =')
  assert not re.search(r'\b(?:printf|print_\w+)\s*\(',new[a:b])
  assert 'input_preprocessing_included=1' in new
  results.append(dict(image=image,packed_bytes=x.size,accumulators_checked=int(oldacc.size),max_abs_bound=int(max(bound))))
  print(image+': PASS pack guards/layout, all 1228800 convolution accumulators, weights, downstream graph and frame timing',flush=True)
 # Use the exact frozen software capacity model for the new stride1 shape.
 h=(R/'sw/yolov5/n6/platform/include/gemmini.h').read_text();a=h.index('static int tiled_conv_total_spad_rows(');b=h.index('\n\nstatic void conv_cpu_without_pool',a)
 code='#include <stdbool.h>\n#include <assert.h>\n#define DIM 64\n'+h[a:b]+'\nint main(){assert(tiled_conv_total_spad_rows(0,1,1,1,0,0,0,1,16,64,16,3,3,12,1,1)==1296);assert(tiled_conv_total_spad_rows(1,1,1,1,0,0,0,1,16,64,16,3,3,12,1,1)==1024);}\n'
 (p/'cap.c').write_text(code);subprocess.run(['gcc',str(p/'cap.c'),'-o',str(p/'cap')],check=True);subprocess.run([str(p/'cap')],check=True)
(OUT/'host_validation.json').write_text(json.dumps(dict(images=results,spad_rows=1296,acc_rows=1024,expected_loopconv_calls=75,rvv_execution='NOT_EXECUTED_ON_HOST; address model tested; board pending'),indent=2)+'\n')
print('PASS exact capacity, 75 expected submissions, RVV address model including tails; hardware RVV execution pending')
