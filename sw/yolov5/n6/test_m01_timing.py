#!/usr/bin/env python3
"""I: actual v8 timing log as fixture. P: exercise new M01 timing contract.
O: rejection of hidden preparation and wrong admission counts.
A: 王志瑞. T: 2026-09-11.
"""
from pathlib import Path
import re
from analyze_timing import analyze
R=Path(__file__).resolve().parents[3]
s=(R/'log/gemmini64_yolov5_v8_ddr_v6_run1.log').read_text()
s=s.replace('n6_port_v8_ddr_v6','n6_port_m01_s2d2').replace('input_preprocessing_included=0','input_preprocessing_included=1')
s+='\nN6_PREP kind=s2d2 cycles=100 bytes=921600 included_in_inference=1\n'
s=re.sub(r'(N6_CREDIT id=0 [^\n]+)',lambda m:m[1].replace('calls=100','calls=75').replace('waited_calls=96','waited_calls=71').replace('accepted=100','accepted=75').replace('retired=100','retired=75'),s)
r=analyze(s);assert r['ledger_cycles']['preparation']==100
for bad in (s.replace('N6_PREP','LOST'),s.replace('input_preprocessing_included=1','input_preprocessing_included=0'),s.replace('accepted=75','accepted=74')):
 try:analyze(bad)
 except ValueError:pass
 else:raise AssertionError('invalid M01 timing accepted')
print('PASS: M01 prep inclusion and 75-call contract; old baseline remains readable')
analyze((R/'log/gemmini64_yolov5_v8_ddr_v6_run1.log').read_text())
