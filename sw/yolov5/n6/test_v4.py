#!/usr/bin/env python3
"""I: v2/v3/v4 sources. P: check exact cache rollback and retained tiling/timing.
O: regression report. A: 王志瑞. T: 2026-09-10.
"""
from pathlib import Path
import re
R=Path(__file__).resolve().parents[3];O=R/'build/yolov5nu_n6_v4'
def flush(s):
 a=s.index('static void n6_flush(');b=s.index('/* I: per-operation',a);return s[a:b]
a=(R/'debug/yolov5nu_n6_v2_20260910/source/n6_runtime.h').read_text()
b=(R/'sw/yolov5/n6/n6_runtime.h').read_text()
assert flush(a)==flush(b)
assert 'n6_cache_need_line' not in b and 'n6_clean_lines' not in b
logs=['PASS: direct flush byte-identical to v2; no bitmap in runtime']
for image in ['025','036','142','404','650']:
 s=(O/image/'main.c').read_text();p=(R/'build/yolov5nu_n6_opt'/image/'main.c').read_text()
 assert re.findall(r'tiled_conv\([^;]+;',s)==re.findall(r'tiled_conv\([^;]+;',p)
 assert len(re.findall(r'tiled_conv\([^;]+;',s))==58
 assert re.findall(r'n6_pending_label="[^"]+";',s)==re.findall(r'n6_pending_label="[^"]+";',p)
 assert 'n6_cache_forget' not in s and 'n6_cache_init' not in s
 start=s.index('uint64_t graph_start =');end=s.index('uint64_t inference_cycles =')
 assert not re.search(r'\b(?:printf|print_\w+)\s*\(',s[start:end])
 assert s.index('n6_check_heads(',end)>end
 assert 'n6_port_v4_direct_cache' in s and 'N6_VERBOSE_UART' in s
 logs.append(image+': PASS unchanged 58 explicit tiles and operands; UART/validation excluded; no bitmap maintenance')
(O/'test_v4.log').write_text('\n'.join(logs)+'\n');print('\n'.join(logs))
