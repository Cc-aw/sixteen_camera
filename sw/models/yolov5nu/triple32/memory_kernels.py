"""Replace only the five same-scale RVV graph calls with DDR Gemmini kernels."""
import json
import re
from fixed_plans import graph_stages

STAGES = (75, 76, 77, 83, 97)
WAITS_PER_WORKER = 144
EXPECTED = dict(pool_calls=3, resize_calls=2, mvin=1944, mvout=624, waits=144)


def expected_counts(resize_batch=False, resize_rows=0):
    if resize_batch not in (False, True) or not isinstance(resize_rows, int) or not 0 <= resize_rows <= 30:
        raise ValueError('Invalid Resize batch configuration')
    if resize_rows and not resize_batch:
        raise ValueError('Resize row limit requires batching')
    expected = EXPECTED.copy()
    if resize_batch:
        rows1, rows2 = min(15, resize_rows or 15), min(12, resize_rows or 12)
        expected['waits'] = 24 + 4*((15+rows1-1)//rows1) + 2*((30+rows2-1)//rows2)
    return expected


def bake(out, model, resize_batch=False, resize_rows=0):
    expected = expected_counts(resize_batch, resize_rows)
    stages = graph_stages(model)
    records = []
    for stage in STAGES:
        kind = 'maxpool' if stage < 80 else 'resize'
        name = 'maxpool_nhwc_i8' if kind == 'maxpool' else 'resize_nearest_nhwc_i8'
        matches = list(re.finditer(r'\b'+name+r'\(([^;]+)\);', stages[stage]))
        if len(matches) != 1:
            raise ValueError(f'Memory operator call changed at stage {stage}')
        match = matches[0]
        args = [s.strip() for s in match[1].split(',')]
        if len(args) != (16 if kind == 'maxpool' else 10):
            raise ValueError(f'Memory operator arguments changed at stage {stage}')
        n, c, h, w, oh, ow = map(int, args[2:8])
        if n != 1 or args[-2] != args[-1]:
            raise ValueError(f'Memory operator requires batch=1 and same scale: {stage}')
        if kind == 'maxpool':
            if (c,h,w,oh,ow) != (128,15,20,15,20) or list(map(int,args[8:14])) != [5,5,1,1,2,2]:
                raise ValueError(f'Unsupported pool geometry: {stage}')
            call = f'yolo32_memory_pool5({args[0]}, {args[1]}, {h}, {w}, {c});'
        else:
            if (h,w,c) != ((15,20,128) if stage == 83 else (30,40,64)) or (oh,ow) != (2*h,2*w):
                raise ValueError(f'Unsupported resize geometry: {stage}')
            call = f'yolo32_memory_resize2({args[0]}, {args[1]}, {h}, {w}, {c});'
        if model.count(match[0]) != 1:
            raise ValueError(f'Ambiguous memory operator replacement: {stage}')
        model = model.replace(match[0], call, 1)
        records.append(dict(stage=stage, kind=kind, height=h, width=w, channels=c))
    marker = '#include "include/yolov5nu_stage4_rvv.h"'
    if model.count(marker) != 1:
        raise ValueError('Memory kernel include point changed')
    model = model.replace(marker, marker+'\n#include "memory_kernels_runtime.inc"', 1)
    manifest = dict(
        schema=2 if resize_batch else 1, stages=records, expected_per_worker=expected,
        extra_batch_waits=3*expected['waits'],
        completion=('original scoped ingress/retirement/DMA wait; Resize dirty before each non-yielding phase'
                    if resize_batch else 'original scoped ingress/retirement/DMA wait; dirty before every Mvin/Mvout'),
        source='colleague pool-resize-round2 / dim32-ddr-batch',
        source_elf_sha256='2ba8f44b59e6e8c394fda2e615f6b70b6cf603de80ddb0713783e91e6870af5b')
    if resize_batch:
        manifest.update(resize_batch=1, resize_rows=resize_rows,
                        resize_source='colleague yolo_gemmini_resize2_ddr_multir (not in supplied round2 ELF)',
                        resize_batches_per_channel=[min(15,resize_rows or 15),min(12,resize_rows or 12)],
                        resize_phase_waits=expected['waits']-24)
    (out/'memory_kernels.json').write_text(json.dumps(manifest,indent=2)+'\n')
    with (out/'fixed_plans_guard.inc').open('a') as f:
        f.write('_Static_assert(YOLO32_MEMORY_OPS == 1, "Memory graph requires memory-ops build");\n')
        f.write(f'_Static_assert(YOLO32_RESIZE_BATCH == {int(resize_batch)}, "Resize build/generator mismatch");\n')
        if resize_batch:
            f.write('_Static_assert(DIM == 32 && ACC_ROWS == 2048 && MAX_BLOCK_LEN == 2, "Resize batch ABI/capacity changed");\n')
            f.write(f'_Static_assert(YOLO32_RESIZE_ROWS == {resize_rows} && YOLO32_MEMORY_WAITS == {expected["waits"]}, "Resize wait plan changed");\n')
    return model
