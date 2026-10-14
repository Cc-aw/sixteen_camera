"""Strict v26 capacity experiment and sparse observation validation."""
from check_log import number

CONFIG=('capacity_experiment','credit_cap','capacity_diag','capacity_period','quantum_cycles')
BASE={'worker','schema','period','queries','probes','retired_reads','status_reads',
      'peer_queries','scheduler_queries','admit_queries','resume_queries','known_probes',
      'full_can','full_no','allowed_can','allowed_no','retired_progress','retired_observed',
      'ready_events','ready_canceled','ready_cycles','ready_max','refill_events','refill_canceled',
      'refill_cycles','refill_max','submitted','first_submit','last_submit','graph_done',
      'observed_span','gap_candidates','gap_kept','owner0_cycles','owner1_cycles','owner2_cycles','scheduler_cycles'}
BASE|={'known_busy','eligible_busy','eligible_idle'}
BASE|={'budget_rejects','entrance_rejects','ready_queries'}
FIELDS=BASE|{f'pending{i}_{k}' for i in range(5) for k in ('samples','cycles')}
GAP={'worker','index','kind','cycles','stage','start_owner','start_stage','pending','start_busy'}


def configuration(version,row,boot=False):
    if version not in ('v26','v27','v28'):
        if set(CONFIG)&row.keys() or 'software_batch' in row:raise ValueError('capacity flags require v26')
        return dict(zip(CONFIG,(0,0,0,0,0)),software_batch=0)
    if not set(CONFIG)<=row.keys():raise ValueError('v26 missing capacity configuration')
    c={k:number(row,k) for k in CONFIG}
    if version in ('v27','v28'):
        if number(row,'software_batch')!=1 or number(row,'credit_limit')!=4 or c['capacity_diag'] or c['capacity_period']:
            raise ValueError('v27 requires integrated four-slot formal capability')
    elif 'software_batch' in row:raise ValueError('software batch requires v27')
    c['software_batch']=int(version in ('v27','v28'))
    c['supply_revision']=int(version=='v28')
    if (c['capacity_experiment']!=1 or c['credit_cap']!=4 or c['capacity_diag'] not in (0,1)
        or c['capacity_diag']!=number(row,'diagnostic_build') or c['quantum_cycles']!=20000
        or c['capacity_period'] not in (0,16,64) or (c['capacity_period'] and not c['capacity_diag'])
        or (boot and c['capacity_period']) or number(row,'credit_limit') not in (3,4)
        or number(row,'submit_burst')!=1 or number(row,'rocc_layers')!=0
        or number(row,'memory_ops')!=1 or number(row,'resize_batch')!=1 or number(row,'resize_rows')!=0
        or number(row,'hot_paths')!=1 or number(row,'idle_priority')!=1 or number(row,'tail_wait')!=1
        or row.get('scheduling')!=('supply' if version in ('v27','v28') else 'fixed') or row.get('context')!='light'):
        raise ValueError('v26 capacity configuration differs from fixed baseline')
    if number(row,'quantum_us')*100!=c['quantum_cycles']:
        raise ValueError('capacity quantum differs from legacy field')
    return c


def validate(run):
    records=run.get('capacity_stats',{});gaps=run.get('capacity_gaps',{})
    sampled=bool(run.get('capacity_period',0))
    if not sampled:
        if records or gaps or run['phase']=='capacity':raise ValueError('capacity data outside sampled run')
        return
    if (run['phase']!='capacity' or run['mode']!='independent' or run['analysis'] or run['diagnostics']
        or not run.get('capacity_diag') or set(records)!={0,1,2}):
        raise ValueError('missing/light capacity run configuration')
    limit=run['credit_limit'];period=run['capacity_period']
    for w,row in records.items():
        if set(row)!=FIELDS:raise ValueError('invalid capacity summary fields')
        d={k:number(row,k) for k in row}
        if min(d.values())<0 or d['worker']!=w or d['schema']!=1 or d['period']!=period:
            raise ValueError('invalid capacity summary values')
        queries=number(run['credit'][w],'checks');submitted=number(run['credit'][w],'admitted')
        if (d['queries']!=queries or d['submitted']!=submitted
            or d['budget_rejects']+d['entrance_rejects']!=number(run['credit'][w],'blocked')
            or d['budget_rejects']+d['entrance_rejects']+d['ready_queries']!=queries
            or sum(d[k] for k in ('peer_queries','scheduler_queries','admit_queries','resume_queries'))!=queries
            or d['admit_queries']!=submitted or d['resume_queries']!=number(run['credit'][w],'resumes')
            or d['probes']!=(queries+period-1)//period+1
            or d['retired_reads']!=d['probes'] or d['status_reads']!=d['probes']
            or sum(d[f'pending{i}_samples'] for i in range(5))!=d['probes']
            or sum(d[f'pending{i}_cycles'] for i in range(5))!=d['observed_span']
            or any(d[f'pending{i}_{k}'] for i in range(limit+1,5) for k in ('samples','cycles'))
            or sum(d[k] for k in ('full_can','full_no','allowed_can','allowed_no'))!=d['known_probes']
            or d['known_busy']>d['known_probes'] or d['eligible_busy']+d['eligible_idle']!=d['allowed_can']
            or d['known_probes']>d['probes'] or d['retired_progress']>d['probes']
            or not 0<d['first_submit']<=d['last_submit']<=d['graph_done']<=run['graph']
            or d['observed_span']>run['graph'] or d['retired_observed']>submitted
            or sum(d[k] for k in ('owner0_cycles','owner1_cycles','owner2_cycles','scheduler_cycles'))>run['graph']):
            raise ValueError('capacity counts/observed intervals do not close')
        for kind in ('ready','refill'):
            if (d[f'{kind}_events']>submitted or d[f'{kind}_events']+d[f'{kind}_canceled']>d['probes']
                or not 0<=d[f'{kind}_max']<=d[f'{kind}_cycles']<=run['graph']
                or bool(d[f'{kind}_cycles'])!=bool(d[f'{kind}_events'])):
                raise ValueError('invalid observed supply gap')
        candidates=d['ready_events']+d['refill_events']
        if d['gap_candidates']!=candidates or d['gap_kept']!=min(candidates,8):
            raise ValueError('capacity top-eight count mismatch')
        rows={i:g for (worker,i),g in gaps.items() if worker==w}
        if set(rows)!=set(range(d['gap_kept'])):raise ValueError('missing/duplicate capacity gap')
        for i,g in rows.items():
            if set(g)!=GAP:raise ValueError('invalid capacity gap fields')
            g={k:number(g,k) for k in g}
            if (g['worker']!=w or g['index']!=i or g['kind'] not in (0,1)
                or not 0<g['cycles']<=d['ready_max' if not g['kind'] else 'refill_max']
                or not 0<=g['stage']<165 or not 0<=g['start_owner']<=3
                or not 0<=g['start_stage']<=167 or not 0<=g['pending']<limit):
                raise ValueError('invalid capacity gap values')
            if g['start_busy'] not in (0,1):raise ValueError('invalid sampled hardware busy')


def report(runs):
    for r in runs:
        if not r.get('capacity_period'):continue
        print(f"\nrun={r['id']} light capacity diagnosis: limit={r['credit_limit']}, period={r['capacity_period']}; excluded from formal timing")
        for w,s in sorted(r['capacity_stats'].items()):
            n=lambda k:number(s,k)
            print(f"  worker={w}: queries={n('queries')} probes={n('probes')} software-full/entrance-yes={n('full_can')} software-full/entrance-no={n('full_no')}")
            print(f"    exact policy outcomes: budget-rejected={n('budget_rejects')} entrance-rejected={n('entrance_rejects')} ready={n('ready_queries')}")
            print(f"    observed-ready gaps={n('ready_events')} cycles={n('ready_cycles')} max={n('ready_max')}; observed-retirement/refill gaps={n('refill_events')} cycles={n('refill_cycles')} max={n('refill_max')}")
            print('    pending samples='+','.join(str(n(f'pending{i}_samples')) for i in range(5)))
            print(f"    eligible samples: hardware-busy={n('eligible_busy')} hardware-idle={n('eligible_idle')}")
        print('  Sparse, sequential CSR observations and held-state intervals; not continuous occupancy, DDR bandwidth or recoverable critical-path cycles. Gap rows retain only the largest eight completed observations per worker.')
