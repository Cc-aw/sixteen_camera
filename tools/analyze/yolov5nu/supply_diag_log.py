from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[3] / "sw/models/yolov5nu/codegen"))
"""Validate observational supply diagnosis; never treat snapshots as reservations."""
from check_log import number

SOURCES = ('peer', 'scheduler', 'admit', 'resume', 'observer')
CATEGORIES = ('other', 'interpret', 'prepare', 'address', 'bind', 'credit',
              'native', 'policy', 'copy', 'resize', 'maxpool', 'instrument')
HARDWARE = ('busy', 'load_dma', 'load_spad', 'exec', 'store_dma', 'store_spad')
CLASS_FIELDS = {'checks', 'ready', 'budget_only', 'hardware_only', 'both'}
PENDING = {f'pending{i}' for i in range(4)}
HW_REASONS=('hw_slots_full','hw_queue_full','hw_partial','hw_unknown')
SOURCE_FIELDS = {'worker', 'source', 'cycles'} | CLASS_FIELDS | PENDING | set(HW_REASONS)
GAP_FIELDS = {'events', 'gap_cycles', 'peer_cycles', 'scheduler_cycles', 'self_cycles'}
SUPPLY_FIELDS = {'worker', 'max_gap', 'withdrawn_events', 'withdrawn_cycles',
                 'positive_samples', 'known_packets', 'submitted_packets',
                 'scheduler_bind_cycles'} | GAP_FIELDS | {f'admit{i}' for i in range(4)}
CPU_FIELDS = {'worker', 'stage', 'copy_read', 'copy_write'} | set(CATEGORIES)
HW_FIELDS = {'worker', 'stage', 'samples'} | set(HARDWARE)
FLOW_FIELDS = {'worker', 'stage'} | CLASS_FIELDS | PENDING | GAP_FIELDS
RECORDS = {'YOLO32_CREDIT_SOURCE': 'credit_sources', 'YOLO32_SUPPLY': 'supply',
           'YOLO32_CPU_DETAIL': 'cpu_details', 'YOLO32_HW_STAGE': 'hw_stages',
           'YOLO32_FEED_STAGE': 'feed_stages', 'YOLO32_HW_TOTAL':'hw_totals'}


def classes(row):
    values = {key: number(row, key) for key in CLASS_FIELDS | PENDING}
    if min(values.values()) < 0 or values['checks'] != sum(values[k] for k in ('ready','budget_only','hardware_only','both')):
        raise ValueError('credit rejection classes must partition queries')
    if sum(values[f'pending{i}'] for i in range(4)) != values['checks']:
        raise ValueError('pending histogram differs from query count')
    if values['budget_only'] + values['both'] != values['pending3']:
        raise ValueError('software-budget rejections differ from pending=3')


def gap(row):
    values = {key: number(row, key) for key in GAP_FIELDS}
    if min(values.values()) < 0 or values['gap_cycles'] != sum(values[k] for k in ('peer_cycles','scheduler_cycles','self_cycles')):
        raise ValueError('supply episode owner intervals do not close')
    if bool(values['gap_cycles']) != bool(values['events']):
        raise ValueError('invalid supply episode count/interval')


def validate(run):
    maps = {name: run.get(name,{}) for name in RECORDS.values()}
    if not run.get('supply_diag'):
        if any(maps.values()): raise ValueError('supply records without enabled diagnosis')
        return
    if not run['analysis'] or not run['rocc_layers'] or run['mode'] not in ('forward','independent') or run['credit_limit'] != 3:
        raise ValueError('supply diagnosis requires analysis and v19 forward/independent baseline')
    expected = {(w,s) for w in range(3) for s in range(165)}
    detailed=run.get('supply_detail',1)
    if detailed and (set(maps['cpu_details']) != expected or set(maps['hw_stages']) != expected):
        raise ValueError('missing/extra CPU or hardware stage diagnosis')
    if not detailed and (maps['cpu_details'] or maps['hw_stages']):
        raise ValueError('detailed records in light supply diagnosis')
    if set(maps['hw_totals']) != {0,1,2}:
        raise ValueError('missing hardware counter totals')
    for w,row in maps['hw_totals'].items():
        if set(row) != {'worker'}|set(HARDWARE) or number(row,'worker')!=w or any(number(row,k)<0 for k in HARDWARE):
            raise ValueError('invalid hardware counter totals')
        profile=run['profiles'][w]
        if (number(row,'busy')!=number(profile,'gem_busy') or number(row,'exec')!=number(profile,'exec') or
            number(row,'load_dma')+number(row,'load_spad')!=number(profile,'load_stall') or
            number(row,'store_dma')+number(row,'store_spad')!=number(profile,'store_stall')):
            raise ValueError('hardware counter totals differ from existing profile')
    for key, row in maps['cpu_details'].items():
        if set(row) != CPU_FIELDS or any(number(row,k)<0 for k in CPU_FIELDS-{'worker','stage'}):
            raise ValueError('invalid CPU detail fields')
        w, stage = key
        if (number(row,'worker'),number(row,'stage')) != key:
            raise ValueError('CPU stage identity differs')
        reference = run['task_stages'][key] if run['mode']=='independent' else run['stages'][stage]
        span = number(reference,'span_cycles' if run['mode']=='independent' else 'cycles')
        if sum(number(row,c) for c in CATEGORIES) > span:
            raise ValueError('tracked CPU intervals exceed stage wall interval')
    for key,row in maps['hw_stages'].items():
        if set(row) != HW_FIELDS or number(row,'samples') <= 0 or any(number(row,k)<0 for k in HARDWARE):
            raise ValueError('invalid hardware stage fields/samples')
        if (number(row,'worker'),number(row,'stage')) != key:
            raise ValueError('hardware stage identity differs')
    if run['mode'] != 'independent':
        if any(maps[k] for k in ('credit_sources','supply','feed_stages')):
            raise ValueError('credit/supply timing requires independent workers')
        return
    if set(maps['credit_sources']) != {(w,s) for w in range(3) for s in SOURCES} or set(maps['supply']) != {0,1,2}:
        raise ValueError('missing/extra credit origins or worker supply records')
    for w in range(3):
        for source in SOURCES:
            row=maps['credit_sources'][(w,source)]
            if set(row) != SOURCE_FIELDS or row['source'] != source or number(row,'worker') != w or number(row,'cycles')<0:
                raise ValueError('invalid credit origin fields')
            classes(row)
            blocked=number(row,'hardware_only')+number(row,'both')
            reasons=[number(row,k) for k in HW_REASONS]
            if any(not 0<=v<=blocked for v in reasons) or sum(reasons)<blocked or max(reasons[:3],default=0)+reasons[3]>blocked:
                raise ValueError('invalid overlapping ingress rejection reasons')
        original=run['credit'][w]
        rows=[maps['credit_sources'][(w,s)] for s in SOURCES]
        if (sum(number(r,'checks') for r in rows) != number(original,'checks') or
            sum(number(r,'cycles') for r in rows) != number(original,'check_cycles') or
            sum(number(r,k) for r in rows for k in ('budget_only','hardware_only','both')) != number(original,'blocked')):
            raise ValueError('credit origins differ from total checks/timing/rejections')
        row=maps['supply'][w]
        if set(row) != SUPPLY_FIELDS or number(row,'worker') != w or any(number(row,k)<0 for k in SUPPLY_FIELDS-{'worker'}):
            raise ValueError('invalid supply fields')
        gap(row)
        issued=number(original,'admitted')
        if (number(row,'known_packets') != issued or number(row,'submitted_packets') != issued or
            sum(number(row,f'admit{i}') for i in range(4)) != issued or number(row,'admit3') or
            not 0 <= number(row,'max_gap') <= number(row,'gap_cycles') <= run['graph'] or
            not 0 <= number(row,'events') <= issued or number(row,'positive_samples') < number(row,'events') or
            number(row,'withdrawn_cycles') > run['graph']):
            raise ValueError('supply packet/depth/episode accounting differs')
    if set(maps['feed_stages']) != {(w,s) for (w,s,funct) in run['rocc_layer_stats'] if funct==15}:
        raise ValueError('missing/extra known-Conv feed stage records')
    for key,row in maps['feed_stages'].items():
        if set(row) != FLOW_FIELDS or (number(row,'worker'),number(row,'stage')) != key:
            raise ValueError('invalid feed stage fields')
        classes(row); gap(row)
    for w in range(3):
        rows=[r for (worker,_),r in maps['feed_stages'].items() if worker==w]
        for k in GAP_FIELDS:
            if sum(number(r,k) for r in rows) != number(maps['supply'][w],k):
                raise ValueError('layer supply episodes differ from worker total')


def report(runs):
    for run in runs:
        if not run.get('supply_diag'): continue
        print(f"\nRun {run['id']} {run['mode']}: observed supply diagnosis, detail={run.get('supply_detail',1)} (cycles)")
        if run.get('supply_detail',1):
            print('  CPU categories partition tracked task execution; diagnostic hooks add overhead.')
            for category in CATEGORIES:
                total=sum(number(r,category) for r in run['cpu_details'].values())
                print(f'  {category}: {total} cycles')
        if run['mode']=='independent':
            for source in SOURCES:
                rows=[run['credit_sources'][(w,source)] for w in range(3)]
                print(f'  credit {source}: '+', '.join(f'{k}={sum(number(r,k) for r in rows)}' for k in ('checks','cycles','ready','budget_only','hardware_only','both')))
                print('    can_submit=0 reasons (may overlap): '+', '.join(f'{k}={sum(number(r,k) for r in rows)}' for k in HW_REASONS))
            for w,row in run['supply'].items():
                print(f"  worker={w} observed capacity-to-submit episodes="+str(number(row,'events'))+
                      '; '+', '.join(f'{k}={number(row,k)} cycles' for k in ('gap_cycles','peer_cycles','scheduler_cycles','self_cycles','max_gap')))
                print('    Query pending histogram 0/1/2/3: '+','.join(str(sum(number(run['credit_sources'][(w,s)],f'pending{i}') for s in SOURCES)) for i in range(4)))
            print('  Top 12 known-Conv peer CPU supply gaps:')
            for (w,stage),row in sorted(run['feed_stages'].items(),key=lambda p:number(p[1],'peer_cycles'),reverse=True)[:12]:
                print(f"    worker={w} stage={stage} peer={number(row,'peer_cycles')} cycles gap={number(row,'gap_cycles')} cycles "+run['task_stages'][(w,stage)]['label'])
            print('  Positive-capacity episodes are sampled evidence, not continuous hardware-idle measurements. '
                  'Budget-only rejects are software depth limits; hardware-only/both observe can_submit=0.')
        print('  Existing final hardware counters, split DMA/SPAD (no extra RoCC reads in d):')
        for w,row in run['hw_totals'].items():
            print(f'    worker={w} '+', '.join(f'{k}={number(row,k)}' for k in HARDWARE))
        if run.get('supply_detail',1): print('  Top 12 stage load/store DMA wait counters (events may overlap):')
        for (w,stage),row in sorted(run['hw_stages'].items(),key=lambda p:number(p[1],'load_dma')+number(p[1],'store_dma'),reverse=True)[:12]:
            print(f"    worker={w} stage={stage} "+', '.join(f'{k}={number(row,k)}' for k in HARDWARE))
        print('  Hardware counters are overlapping event counts, not DDR bytes or exclusive CPU costs. '
              'Use the uninstrumented v19 image for formal performance.')
        from pathlib import Path
        from diagnostic_traffic import report as report_traffic
        report_traffic(run,Path(__file__).resolve().parent/'build/supply_diag/diagnostic_traffic.json')
