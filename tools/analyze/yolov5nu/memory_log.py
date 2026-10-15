from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[3] / "sw/models/yolov5nu/codegen"))
"""Validate v21/v22 graph counts and optional board element/guard test."""
from check_log import fields, number
from memory_kernels import expected_counts


def validate(run):
    rows = run.get('memory', {})
    if not run.get('memory_ops'):
        if rows: raise ValueError('memory records without enabled operators')
        return
    if set(rows) != {0,1,2}: raise ValueError('missing memory worker counts')
    expected=expected_counts(run.get('resize_batch',0),run.get('resize_rows',0))
    for w,row in rows.items():
        if set(row) != {'worker','pad_cycles',*expected} or number(row,'worker') != w:
            raise ValueError('invalid memory worker schema')
        if any(number(row,k) != v for k,v in expected.items()):
            raise ValueError('memory command counts differ from graph')
        pad = number(row,'pad_cycles')
        if pad < 0 or (run['analysis'] and pad == 0) or (not run['analysis'] and pad != 0):
            raise ValueError('memory padding profile differs from run')
        if run['analysis']:
            for f,k in [(2,'mvin'),(3,'mvout')]:
                if number(run['rocc'][(w,f)],'count') != expected[k]:
                    raise ValueError('memory commands differ from native RoCC count')


def validate_smoke(text):
    active = None
    errors = []
    cases = [(0,1,1,128,0),(0,3,4,65,1),(0,15,20,128,1),(0,15,20,128,2),
             (1,3,17,65,2),(1,15,20,128,2),(1,30,40,64,2)]
    for raw in text.splitlines():
        line = raw.strip()
        try:
            if line.startswith('YOLO32_MEMORY_TEST_BEGIN '):
                if active is not None: raise ValueError('nested element test')
                r=fields(line)
                if set(r)!={'workers','cases_per_worker'} or number(r,'workers')!=3 or number(r,'cases_per_worker')!=7:
                    raise ValueError('invalid element test header')
                active={}
            elif line.startswith('YOLO32_MEMORY_TEST_CASE '):
                if active is None: raise ValueError('element case outside test')
                r=fields(line); w=number(r,'worker'); i=number(r,'case')
                if set(r)!={'worker','case','kind','h','w','c','pattern','elements','mismatches','guard_errors','first','cycles'}:
                    raise ValueError('invalid element case schema')
                if w not in range(3) or i not in range(7) or (w,i) in active:
                    raise ValueError('invalid/duplicate element case')
                resize,h,width,c,pattern=cases[i]
                if (r['kind']!=('resize' if resize else 'pool') or
                    [number(r,k) for k in ['h','w','c','pattern','elements']]!=[h,width,c,pattern,h*width*c*(4 if resize else 1)]):
                    raise ValueError('element geometry changed')
                if (number(r,'mismatches') or number(r,'guard_errors') or
                    number(r,'first')!=2**64-1 or number(r,'cycles')<=0):
                    raise ValueError('element/guard comparison failed')
                active[w,i]=r
            elif line.startswith('YOLO32_MEMORY_TEST_RESULT '):
                if active is None or len(active)!=21:
                    raise ValueError('incomplete element test')
                r=fields('RESULT '+line.split(' ',2)[-1])
                if not line.startswith('YOLO32_MEMORY_TEST_RESULT PASS ') or set(r)!={'errors'} or number(r,'errors'):
                    raise ValueError('element test did not pass')
                active=None
            elif active is not None and line.startswith(('YOLO32_FIRMWARE ','YOLO32_BEGIN ')):
                raise ValueError('element test interrupted before result')
        except (KeyError,ValueError) as e:
            errors.append(f'memory element test: {e}: {line}')
    if active is not None: errors.append('memory element test truncated at end of log')
    return errors


def report(runs):
    for r in runs:
        if not r.get('memory_ops'): continue
        expected=expected_counts(r.get('resize_batch',0),r.get('resize_rows',0))
        print(f"run={r['id']} Gemmini DDR operators: 3 Pool + 2 Resize/worker; "
              f"Mvin=1944 Mvout=624 local DMA waits={expected['waits']}/worker")
        if r.get('resize_batch'):
            print(f"  Multi-row Resize: row limit={r.get('resize_rows',0)} (0=ACC capacity); "
                  f"Resize phase waits={expected['waits']-24}/worker")
        if r['analysis']:
            print('  RVV boundary-padding CPU cycles by worker: '+','.join(
                str(number(r['memory'][w],'pad_cycles')) for w in range(3)))
    if any(r.get('memory_ops') for r in runs):
        print('Pool/Resize profile spans include hardware waits; use task CPU cycles for exclusive CPU cost.')
