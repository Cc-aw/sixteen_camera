#!/usr/bin/env python3
"""I: Stage8F AOT/整数参考、N6 软件接口。P: 独立生成尾块与缓存适配。O: 五图源码及参考。
A: 王志瑞。T: 2026-09-10。
"""
from pathlib import Path
import hashlib, json, re, shutil, os
import numpy as np
from plan_tiles import Planner
ROOT = Path(__file__).resolve().parents[3]
BASE = ROOT / 'sw/yolov5'
HERE = Path(__file__).resolve().parent
VARIANT = os.environ.get('N6_DDR_TILE_VARIANT', 'v6')
assert VARIANT in ('v6','v7'), VARIANT
OUT = ROOT / f'build/yolov5nu_n6_v8_ddr_{VARIANT}'
MODEL = BASE / 'generators/gemmini/software/gemmini-ort/models/detection/stage8_640x480_hardware_aware'
IMAGES = ('025','036','142','404','650')

def transform(s, planner):
    """I: 同事 C。P: 显式尾块、容量限制和 CPU/DMA 所有权交接。O: N6 C。A: 王志瑞。T: 2026-09-10。"""
    s = s.replace('#include "include/gemmini.h"', '#include "n6_credit_profile.h"\n#include "include/gemmini.h"')
    s = s.replace('#include "include/gemmini_nn.h"', '#include "include/gemmini_nn.h"\n#include "n6_runtime.h"')
    s = s.replace('int main(void) {', 'int main(void) {\n  uart_init();\n  printf("YOLOV5NU_N6 image=%s DIM=64 ACC_ROWS=2048 clock_hz=100000000 revision=n6_port_v8_ddr_VARIANT\\n", YOLOV5NU_IMAGE_NAME);')
    s=s.replace('n6_port_v8_ddr_VARIANT', 'n6_port_v8_ddr_'+VARIANT)
    # Restrict replacements to split-K helpers; arbitrary J tails are passed to hardware.
    start = s.index('static void gemmini_splitk_1x1_two_slice_i8(')
    end = s.index('\nstatic ', s.index('static void gemmini_splitk_1x1_multi_slice_i8(') + 15)
    part = s[start:end]
    part = part.replace(' || out_channels % DIM != 0', '')
    part = part.replace(' ||\n      out_channels0 % DIM != 0 || out_channels1 % DIM != 0', '')
    part = part.replace('pad_i, 0, pad_k', 'pad_i, j_blocks * DIM - out_channels, pad_k')
    # Pair helpers have separate J dimensions.
    part = part.replace('i_blocks0, j_blocks0, k_blocks, pad_i, j_blocks * DIM - out_channels, pad_k', 'i_blocks0, j_blocks0, k_blocks, pad_i, j_blocks0 * DIM - out_channels0, pad_k')
    part = part.replace('i_blocks1, j_blocks1, k_blocks, pad_i, j_blocks * DIM - out_channels, pad_k', 'i_blocks1, j_blocks1, k_blocks, pad_i, j_blocks1 * DIM - out_channels1, pad_k')
    part = part.replace('(ACC_ROWS / 2) / (j_blocks * DIM)', 'n6_tile_i(j_blocks, (slice_channels + DIM - 1) / DIM)')
    # Multi-slice helper must use the maximum slice width.
    multi = part.index('static void gemmini_splitk_1x1_multi_slice_i8(')
    part = part[:multi] + part[multi:].replace('n6_tile_i(j_blocks, (slice_channels + DIM - 1) / DIM)', 'n6_multi_tile_i(j_blocks, slice_channels, slice_count)')
    part = part.replace('(ACC_ROWS / 2) / (j_blocks0 * DIM)', 'n6_tile_i(j_blocks0, k_blocks)')
    part = part.replace('(ACC_ROWS / 2) / (j_blocks1 * DIM)', 'n6_tile_i(j_blocks1, k_blocks)')
    s = s[:start] + part + s[end:]
    # Add ownership transfer to the entry/exit of accelerator-only helpers.
    rules = {
      'add_gemmini_shared_resadd_i8': ([('a','positions * channels'),('b','positions * channels')],[('dst','positions * channels')]),
      'gemmini_splitk_1x1_two_slice_i8': ([('a0','positions * slice_channels'),('a1','positions * slice_channels')],[('output','positions * out_channels')]),
      'gemmini_splitk_1x1_two_slice_i8_spad_reuse': ([('a0','positions * slice_channels'),('a1','positions * slice_channels')],[('output','positions * out_channels')]),
      'gemmini_splitk_1x1_two_slice_two_consumer_spad_reuse_i8': ([('a0','positions * slice_channels'),('a1','positions * slice_channels')],[('output0','positions * out_channels0'),('output1','positions * out_channels1')]),
      'gemmini_splitk_1x1_multi_slice_i8': ([], [('output','positions * out_channels')]),
    }
    for name,(inputs,outputs) in rules.items():
        a=s.index('static void '+name+'('); b=s.index('{',a); depth=1; e=b+1
        while depth:
            depth += (s[e]=='{') - (s[e]=='}'); e+=1
        pre='\n  n6_scope_begin(n6_pending_label); n6_wait();\n'+''.join(f'  n6_flush({p}, (size_t)({n}));\n' for p,n in inputs+outputs)
        if name.endswith('multi_slice_i8'):
            pre+='  for (int q=0; q<slice_count; ++q) n6_flush(inputs[q], (size_t)positions * slice_channels[q]);\n'
        pre+='  n6_begin(n6_pending_label);\n'
        post='\n  n6_wait(); n6_end();\n'+''.join(f'  n6_flush({p}, (size_t)({n}));\n' for p,n in outputs)
        post+='  n6_scope_end();\n'
        s=s[:b+1]+pre+s[b+1:e-1]+post+s[e-1:]
    # Every normal Conv is a fixed-shape, single-line call in the imported AOT.
    count=0
    def conv(m):
        nonlocal count
        args=[x.strip() for x in m.group(1).split(',')]
        assert len(args)==27, len(args)
        assert args[24:26]==['0','0'], 'pooling requires separate output sizing'
        ib=' * '.join(args[i] for i in [0,1,2,3]); ob=' * '.join(args[i] for i in [0,5,6,4])
        count+=1
        # I: fixed layer geometry. P: retain full K channels within N6 capacity.
        # O: three isolated tile overrides. A: 王志瑞. T: 2026-09-10.
        tile=planner.tile(args)
        overrides={
          # I: conv0 width 320. P: avoid 66=64+2 internal tails. O: 100 aligned tiles.
          # A: 王志瑞. T: 2026-09-10.
          'yolov5nu_conv0_weights': ([1,480,640,3,16,240,320,2,1,1,2,6], [1,12,64,16,6,6,3]),
          'yolov5nu_conv1_weights': ([1,240,320,16,32,120,160,2,1,1,1,3], [1,14,64,32,3,3,16]),
          'yolov5nu_conv7_weights': ([1,120,160,32,64,60,80,2,1,1,1,3], [1,13,64,64,3,3,32]),
        }
        if VARIANT=='v6': overrides.pop('yolov5nu_conv0_weights')
        if args[18] in overrides:
            shape,chosen=overrides[args[18]]
            assert list(map(int,args[:12]))==shape
            assert args[12:17]==['false']*5
            tile=list(map(str,chosen))
        explicit=args[:12]+[args[3],args[4],args[4]]+args[12:17]+tile+args[17:]
        call=', '.join(explicit)
        return f'n6_scope_begin("{args[18]}"); n6_wait(); n6_flush({args[17]}, (size_t)({ib})); n6_flush({args[20]}, (size_t)({ob}));\n    n6_begin("{args[18]}"); tiled_conv({call});\n    n6_wait(); n6_end(); n6_flush({args[20]}, (size_t)({ob})); n6_scope_end();'
    s=re.sub(r'tiled_conv_auto\(([^;]+)\);',conv,s)
    assert count==58, count
    # Label helper groups without including cache maintenance in hardware counters.
    main_pos=s.index('int main(void)')
    prefix,body=s[:main_pos],s[main_pos:]
    def label(m):
        weights=re.findall(r'yolov5nu_conv[0-9]+_weights',m.group(0))
        name='+'.join(weights) if weights else 'shared_add'
        return f'n6_pending_label="{name}"; '+m.group(0)
    body=re.sub(r'(?:gemmini_splitk_1x1_\w+|add_gemmini_shared_resadd_i8)\([^;]+\);',label,body)
    s=prefix+body
    # Defer every normal-path print between graph and NMS until timing ends.
    a=s.index('  print_tensor_summary("YOLOv5nu class logits"')
    b=s.index('  struct Detection top_detections[10];',a)
    summaries=s[a:b];s=s[:a]+s[b:]
    s=s.replace('  print_top_detections(top_detections);\n','')
    marker='  print_nms_detections(nms_detections, nms_count, 0.25f,'
    at=s.index(marker)
    s=s[:at]+'  uint64_t inference_cycles = yolo_profile_clock() - graph_start;\n  uint64_t fps_x1000 = 100000000000ULL / inference_cycles;\n  printf("N6_INFERENCE cycles=%lu time_us=%lu fps=%lu.%03lu uart_included=0 validation_included=0 input_preprocessing_included=0\\n",\n    (unsigned long)inference_cycles, (unsigned long)(inference_cycles/100),\n    (unsigned long)(fps_x1000/1000), (unsigned long)(fps_x1000%1000));\n'+summaries+'  print_top_detections(top_detections);\n'+s[at:]
    s=s.replace('  uint64_t fps_x1000 =', '  uint64_t report_start=n6_cycles();\n  uint64_t fps_x1000 =')
    s=s.replace('    printf("YOLOV5NU_PROFILE record=', '    if (N6_VERBOSE_UART) printf("YOLOV5NU_PROFILE record=')
    s=s.replace('score_threshold=%.2f iou_threshold=%.2f', 'score_threshold_milli=%d iou_threshold_milli=%d')
    s=s.replace('YOLOV5NU_IMAGE_NAME,score_threshold,iou_threshold);', 'YOLOV5NU_IMAGE_NAME,(int)(score_threshold*1000+0.5f),(int)(iou_threshold*1000+0.5f));')
    s=s.replace('  printf("PASS\\n");\n  exit(0);', '''  n6_print_memory();
  n6_print_timing();
  uint64_t report_cycles=n6_cycles()-report_start;
  printf("N6_REPORT cycles=%lu includes_formatting=1 excludes_this_line_and_validation=1 excluded_from_inference=1\\n", (unsigned long)report_cycles);
  uint64_t validation_start=n6_cycles();
  int ok = n6_check_heads(tensor_246, tensor_248, tensor_252, dfl_candidate_mask);
  uint64_t validation_cycles=n6_cycles()-validation_start;
  printf("N6_VALIDATION cycles=%lu includes_check_uart=1 excluded_from_inference=1\\n", (unsigned long)validation_cycles);
  printf("N6_CACHE cycles=%lu flushed_bytes=%lu\\n", (unsigned long)n6_cache_cycles, (unsigned long)n6_cache_bytes);
  printf("RESULT: %s - YOLOv5nu N6 hardware integer reference\\n", ok ? "PASS" : "FAIL");
  exit(ok ? 0 : 1);''')
    assert 'printf("PASS\\n")' not in s
    return '/* I: Stage8F NHWC tensors. P: N6 tail/cache port. O: checked heads/profile. A: 王志瑞. T: 2026-09-10. */\n'+s

def main():
    OUT.mkdir(parents=True,exist_ok=True)
    planner=Planner(OUT)
    refs=np.load(MODEL/'hardware_integer_reference.npz')
    manifest=[]
    for image in IMAGES:
        dest=OUT/image;dest.mkdir(exist_ok=True)
        stem=f'yolov5nu-stage8f-dual-consumer-spad-reuse-img640x480-image{image}-profile'
        source=MODEL/'aot'/f'{stem}.c'
        (dest/'main.c').write_text(transform(source.read_text(), planner))
        shutil.copy2(MODEL/'aot'/f'{stem}_params.h',dest/f'{stem}_params.h')
        assembly=['# I: integer reference bytes. P: link read-only. O: symbols. A: 王志瑞. T: 2026-09-10.', '.section .rodata']
        for name in ['class_logits','class_scores','dfl']:
            values=refs[f'{image}__{name}']; assert values.dtype==np.int8
            binary=dest/f'{name}.bin';binary.write_bytes(values.tobytes())
            assembly += ['.balign 64',f'.global n6_ref_{name}',f'n6_ref_{name}:',f'.incbin "{binary}"']
        scores=refs[f'{image}__class_scores']; best=scores.max(axis=0)
        mask=best.astype(np.float32)*np.float32(0.007530334406)>=np.float32(.25)
        mask[np.argsort(-best,kind='stable')[:10]]=True
        binary=dest/'mask.bin';binary.write_bytes(mask.astype(np.uint8).tobytes())
        assembly += ['.global n6_ref_mask','n6_ref_mask:',f'.incbin "{binary}"']
        (dest/'reference.S').write_text('\n'.join(assembly)+'\n')
        manifest.append({'image':image,'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'adapted_sha256':hashlib.sha256((dest/'main.c').read_bytes()).hexdigest()})
    planner.save()
    (OUT/'sources.json').write_text(json.dumps(manifest,indent=2)+'\n')

if __name__=='__main__': main()
