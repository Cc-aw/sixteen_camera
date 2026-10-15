"""Check partial publication separately from queue admission and producer end."""
from check_log import number

STAGES = (124,147,164,123,146,163)
HEAD_FIELDS = {'worker','head','stage','requests','completed_cycles','publication_commit_cycles','ready_observed_cycles'}
STATE_FIELDS = {'worker','published_heads','ready_at_finish','allocated_at_finish','finish_sample_cycles'}
SUMMARY_FIELDS = {'head_admit','publication_transactions','ready_sampling'}


def validate(run):
    events, states, summary = run.get('head_events',{}),run.get('head_states',{}),run.get('head_stats')
    if not run.get('head_clean') or run['mode']!='independent':
        if events or states or summary is not None:raise ValueError('head records outside enabled independent run')
        return
    if set(events)!={(w,h) for w in range(3) for h in range(6)} or set(states)!={0,1,2}:
        raise ValueError('requires all 18 head events and three finish snapshots')
    if summary is None or set(summary)!=SUMMARY_FIELDS:
        raise ValueError('missing/incomplete head clean summary')
    if (number(summary,'head_admit')!=run['head_admit'] or number(summary,'ready_sampling')!=run['analysis']
            or not 3<=number(summary,'publication_transactions')<=18):
        raise ValueError('invalid head clean policy/sampling/publication count')
    for w in range(3):
        ppu=run['ppu_events'][w];g=number(ppu,'graph_done_cycles');r=number(ppu,'result_observed_cycles')
        count=number(run['independent'],f'requests{w}');previous=(0,0,0)
        for h in (3,0,4,1,5,2):
            event=events[w,h]
            if set(event)!=HEAD_FIELDS or number(event,'worker')!=w or number(event,'head')!=h or number(event,'stage')!=STAGES[h]:
                raise ValueError('invalid head event identifier/fields')
            c,p,ready,q=(number(event,k) for k in ('completed_cycles','publication_commit_cycles','ready_observed_cycles','requests'))
            if not 0<c<=g or not c<=p<=run['graph'] or not 0<q<=count:
                raise ValueError('invalid head completion/publication bounds')
            if not c>previous[0] or p<previous[1] or not q>previous[2]:
                raise ValueError('head completion order differs from native graph')
            if ready and (not run['analysis'] or not p<=ready<=r):
                raise ValueError('invalid head ready sampling timestamp')
            previous=(c,p,q)
        if number(events[w,2],'requests')!=count or number(events[w,2],'publication_commit_cycles')!=number(ppu,'publication_commit_cycles'):
            raise ValueError('full publication/last convolution differs from head events')
        if run['head_admit'] and number(ppu,'enqueue_cycles')<number(events[w,0],'publication_commit_cycles'):
            raise ValueError('descriptor admitted before Class0 publication')
        state=states[w]
        if (set(state)!=STATE_FIELDS or number(state,'worker')!=w or number(state,'published_heads')!=63
                or not 0<=number(state,'ready_at_finish')<=63 or number(state,'allocated_at_finish') not in (0,1)):
            raise ValueError('invalid finish head snapshot')
        sample=number(state,'finish_sample_cycles')
        if not max(g,previous[1])<=sample<=min(run['graph'],r):
            raise ValueError('finish snapshot outside producer/result interval')
        if not run['head_admit'] and (number(state,'allocated_at_finish')!=1 or sample>number(ppu,'enqueue_cycles')):
            raise ValueError('complete-graph policy released/submitted before finish snapshot')
        if not number(state,'allocated_at_finish') and number(state,'ready_at_finish'):
            raise ValueError('released slot must have cleared ready bits')


def report(runs):
    from statistics import median
    selected=[r for r in runs if r.get('head_clean') and r['mode']=='independent']
    if not selected:return
    print('Per-head clean: immutable output is published after its local completion; hardware clean determines readiness.')
    print('PPU admission: '+('Class0 publication' if selected[0]['head_admit'] else 'complete graph')+'; one shared core, final batch fence retained.')
    measured=[r for r in selected if r['phase']=='measure'] or [r for r in selected if not r['analysis']]
    for w in range(3):
        if measured:
            lead=median(number(r['ppu_events'][w],'graph_done_cycles')-number(r['head_events'][w,0],'publication_commit_cycles') for r in measured)
            print(f'worker={w} median Class0 publication lead_cycles={lead:.0f}; ready_at_finish_masks='+','.join(str(number(r['head_states'][w],'ready_at_finish')) for r in measured))
