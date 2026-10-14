"""Diagnostic-only scopes around unchanged native model functions."""
import re
from fixed_plans import function


def wrap(model, name, arguments, category, movement=''):
    original = function(model, 'static void '+name+'(')
    signature = original[:original.index('{')]
    native = original.replace(name+'(', name+'_diag_native(', 1)
    wrapper = signature + '{\n'
    wrapper += ('  unsigned diag_w=worker_id;\n' if name == 'select_worker_memory' else
                '  unsigned diag_w=gemmini_pool_active_worker;\n')
    wrapper += f'  unsigned diag_token=yolo32_diag_push(diag_w,{category});\n'
    if name == 'select_worker_memory':
        wrapper += '  uint64_t diag_start=read_cycle();\n'
    wrapper += f'  {name}_diag_native({arguments});\n'
    wrapper += movement
    if name == 'select_worker_memory':
        wrapper += '  yolo32_diag_scheduler_bind(worker_id,read_cycle()-diag_start);\n'
    wrapper += '  yolo32_diag_pop(diag_w,diag_token);\n}\n'
    return model.replace(original, '#if YOLO32_SUPPLY_DIAG\n'+native+'\n'+wrapper+
                         '#else\n'+original+'\n#endif', 1)


def annotate(model):
    original = function(model, 'static uint32_t frame_counter_read(')
    needle = '  return frame_counter_access(worker_id, (index & 7U) << 4);'
    if original.count(needle) != 1:
        raise ValueError('Frame counter read structure changed')
    model = model.replace(original, original.replace(needle,
        '  uint32_t value=frame_counter_access(worker_id, (index & 7U) << 4);\n'
        '#if YOLO32_SUPPLY_DIAG\n'
        '  yolo32_diag_counter(worker_id,index,value);\n#endif\n'
        '  return value;'),1)
    model = wrap(model, 'select_worker_memory', 'worker_id', 'DIAG_BIND')
    model = wrap(model, 'requant_copy', 'src,dst,count,src_scale,dst_scale', 'DIAG_COPY',
                 '  if (count>0) yolo32_diag_copy(diag_w,(uint64_t)count,(uint64_t)count);\n')
    model = wrap(model, 'concat_nhwc_slice_strided_i8',
                 'src,dst,positions,channels,dst_stride,src_scale,dst_scale', 'DIAG_COPY',
                 '#if defined(__riscv_vector)\n'
                 '  if (positions>0 && channels>0) yolo32_diag_copy(diag_w,\n'
                 '    (uint64_t)positions*channels,(uint64_t)positions*channels);\n#endif\n')
    for name in ('maxpool_nhwc_i8_strided', 'resize_nearest_nhwc_i8_strided'):
        # Both native strided kernels use these exact scalar parameters.
        original = function(model, 'static void '+name+'(')
        signature = original[:original.index('{')]
        parameters = signature[signature.index('(')+1:signature.rindex(')')]
        arguments = ','.join(re.search(r'(\w+)\s*$', p)[1] for p in parameters.split(','))
        model = wrap(model,name,arguments,'DIAG_MAXPOOL' if name.startswith('maxpool') else 'DIAG_RESIZE')
    pattern = r'yolo32_prepared_ws\(&prepared_ws_plan_(\d+), \(const void \*const\[10\]\)\{([^}]+)\}\);'

    def bind(match):
        return ('#if YOLO32_SUPPLY_DIAG\n'
                '    unsigned diag_bind=yolo32_diag_push(worker_id,DIAG_BIND);\n'
                '    const void *const diag_bases[10]={'+match[2]+'};\n'
                '    __asm__ volatile("" :: "r"(diag_bases) : "memory");\n'
                '    yolo32_diag_pop(worker_id,diag_bind);\n'
                '    yolo32_prepared_ws(&prepared_ws_plan_'+match[1]+',diag_bases);\n'
                '#else\n    '+match[0]+'\n#endif')
    model, count = re.subn(pattern, bind, model)
    if count != 20:
        raise ValueError('Diagnostic binding expects all 20 prepared WS stages')
    return model
