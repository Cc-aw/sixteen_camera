#!/usr/bin/env python3
"""I: v8 variants, baseline sources and mocked counter hardware.
P: validate unchanged workloads, counter remapping and raw-byte interpretation.
O: regression evidence. A: 王志瑞. T: 2026-09-10.
"""
from pathlib import Path
import re,subprocess,tempfile
from analyze_timing import analyze
R=Path(__file__).resolve().parents[3]
for variant,rev in [('v6','n6_port_v6_conv_tiles'),('v7','n6_port_v7_conv0_align')]:
 for image in ('025','036','142','404','650'):
  base=(R/f'build/yolov5nu_n6_{variant}'/image/'main.c').read_text()
  new=(R/f'build/yolov5nu_n6_v8_ddr_{variant}'/image/'main.c').read_text()
  assert new.replace('n6_port_v8_ddr_'+variant,rev)==base
  print(variant+'/'+image+': PASS identical generated workload except revision')
s=(R/'sw/yolov5/n6/n6_runtime.h').read_text();old=(R/'debug/yolov5nu_n6_v7_20260910/source/n6_runtime.h').read_text()
a=s.index('static void n6_flush(');b=s.index('/* I: per-operation')
assert s[a:b]==old[old.index('static void n6_flush('):old.index('/* I: per-operation')]
# Compile the actual n6_end function against a counter-mux model.
a=s.index('struct n6_record');b=s.index('static const char *n6_pending_label;',a)
decls=s[a:b];a=s.index('static void n6_end(');b=s.index('static void n6_print_memory(',a);fn=s[a:b]
code='''#include <stdint.h>
#include <assert.h>
static unsigned selected[8]={0,1,2,3,4,5,6,7};
static unsigned n6_external_events[4]={48,49,50,51};
static uint64_t n6_credit_calls=3,n6_credit_waits=2,n6_credit_cycles=17;
static unsigned n6_flush_phase;
static uint64_t n6_cycles(void){return 100;}
static uint32_t counter_read(unsigned i){return selected[i]+1000;}
static void counter_configure(unsigned i,unsigned event){selected[i]=event;}
static uint32_t gemmini_loopconv_accepted_count_read(void){return 3;}
static uint32_t gemmini_loopconv_retired_count_read(void){return 3;}
'''+decls+fn+'''int main(void){n6_end();
assert(n6_record_count==1);
for(unsigned i=0;i<8;i++)assert(n6_records[0].counts[i]==1000+i);
for(unsigned i=0;i<4;i++)assert(n6_records[0].external[i]==1048+i);
assert(n6_records[0].calls==3 && n6_records[0].credit_cycles==17);}
'''
with tempfile.TemporaryDirectory() as d:
 p=Path(d);(p/'test.c').write_text(code)
 subprocess.run(['gcc',str(p/'test.c'),'-o',str(p/'test')],check=True)
 subprocess.run([str(p/'test')],check=True)
print('PASS original events saved before external remap; no reset; cache/scope routines unchanged')
fixture='''YOLOV5NU_N6 revision=n6_port_v8_ddr_v6
N6_INFERENCE cycles=110 uart_included=0 validation_included=0 input_preprocessing_included=0
YOLOV5NU_PROFILE records=1 graph_cycles=90 decode_cycles=10 nms_cycles=5
YOLOV5NU_PROFILE record=0 kind=Conv name=test cycles=80
N6_MEMORY op=test cycles=50 load_req_backpressure=2 store_req_backpressure=3 rdma_tlb_wait=0
N6_CREDIT id=0 op=test calls=1 waited_calls=0 wait_cycles=0 accepted=1 retired=1
N6_DMA id=0 op=test rdma_bytes_raw=128 wdma_transaction_bytes=32 rdma_occupancy_cycles=100 wdma_occupancy_cycles=25 rdma_multibeat_overcount=1 ddr_bytes_measured=0
N6_SCOPE id=0 op=test total_cycles=70 cache_cycles=20 wait_cycles=10 other_cycles=40
N6_FLUSH id=0 scope=0 phase=0 address=0x80000000 bytes=64 cycles=20
N6_TIMING scopes=1 flushes=1 overflow=0 scope_cycles=70 cache_cycles=20 wait_cycles=10
N6_CACHE cycles=20 flushed_bytes=64
N6_CHECK class_logits_mismatches=0
N6_REPORT cycles=1000
N6_VALIDATION cycles=100
RESULT: PASS
'''
for variant in ('v6','v7'):
 f=fixture.replace('ddr_v6','ddr_'+variant);r=analyze(f)['dma'][0]
 assert r['tl_response_bytes_lower_bound']==64 and r['tl_response_bytes_upper_bound']==128
 assert r['rdma_mean_outstanding_approx']==2
 for bad in (f.replace('N6_DMA','LOST'),f.replace('ddr_bytes_measured=0','ddr_bytes_measured=1'),f.replace('retired=1','retired=0')):
  try: analyze(bad)
  except ValueError: pass
  else: raise AssertionError('invalid trace accepted')
print('PASS DMA bounds/occupancy interpretation and rejection of missing/mislabelled/counter-mismatched traces')
