#!/usr/bin/env python3
"""I: generated v4/v5 and synthetic timing records. P: check semantic preservation,
accounting and truncation rejection. O: regression result. A: 王志瑞. T: 2026-09-10.
"""
from pathlib import Path
import re
from analyze_timing import analyze
ROOT=Path(__file__).resolve().parents[3]
for image in ('025','036','142','404','650'):
    old=(ROOT/'build/yolov5nu_n6_v4'/image/'main.c').read_text()
    new=(ROOT/'build/yolov5nu_n6_v5'/image/'main.c').read_text()
    for pattern in [r'tiled_conv\([^;]+;',r'n6_flush\([^;]+;',r'n6_pending_label="[^"]+";']:
        assert re.findall(pattern,old)==re.findall(pattern,new),pattern
    a=new.index('uint64_t graph_start =');b=new.index('uint64_t inference_cycles =')
    assert not re.search(r'\b(?:printf|print_\w+)\s*\(',new[a:b])
    assert new.count('n6_scope_begin(')==63 and new.count('n6_scope_end();')==63
    assert new.index('n6_print_timing();')>b and new.index('n6_check_heads(',b)>b
    assert 'n6_port_v5_timing' in new
    print(image+': PASS unchanged Conv operands/flush calls/helper labels; timing boundaries')
fixture='''YOLOV5NU_N6 revision=n6_port_v5_timing
N6_INFERENCE cycles=110 uart_included=0 validation_included=0 input_preprocessing_included=0
YOLOV5NU_PROFILE records=1 graph_cycles=90 decode_cycles=10 nms_cycles=5
YOLOV5NU_PROFILE record=0 kind=Conv name=test cycles=80
N6_MEMORY op=test cycles=50
N6_SCOPE id=0 op=test total_cycles=70 cache_cycles=20 wait_cycles=10 other_cycles=40
N6_FLUSH id=0 scope=0 phase=0 address=0x80000000 bytes=64 cycles=20
N6_TIMING scopes=1 flushes=1 overflow=0 scope_cycles=70 cache_cycles=20 wait_cycles=10
N6_CACHE cycles=20 flushed_bytes=64
N6_CHECK class_logits_mismatches=0
N6_REPORT cycles=1000
N6_VALIDATION cycles=100
RESULT: PASS
'''
r=analyze(fixture);assert r['ledger_cycles']['between_phases']==5 and r['ledger_cycles']['graph_unattributed']==10
for bad in [fixture.replace('overflow=0','overflow=1'),fixture.replace('N6_FLUSH id=0','LOST id=0'),fixture.replace('flushed_bytes=64','flushed_bytes=128'),fixture+fixture]:
    try: analyze(bad)
    except ValueError: pass
    else: raise AssertionError('invalid trace accepted')
print('PASS ledger arithmetic and rejection of overflow, missing records, mismatched totals, duplicate runs')
