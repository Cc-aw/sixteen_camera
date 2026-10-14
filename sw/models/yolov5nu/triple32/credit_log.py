"""Validate cooperative capacity waits separately from dependency completion."""
from check_log import number

FIELDS = {'worker', 'limit', 'admitted', 'checks', 'blocked', 'yields', 'resumes',
          'max_pending', 'wait_cycles', 'check_cycles'}


def validate(run):
    records = run.get('credit', {})
    limit = run.get('credit_limit', 0)
    if not limit or run['mode'] != 'independent':
        if records:
            raise ValueError('credit records outside enabled independent run')
        return
    supported=(3,4) if run.get('capacity_experiment') else (3,)
    if limit not in supported or set(records) != {0, 1, 2}:
        raise ValueError('credit experiment requires limit=3 and all three workers')
    for w, r in records.items():
        if set(r) != FIELDS or number(r, 'worker') != w or number(r, 'limit') != limit:
            raise ValueError('invalid credit fields/worker/limit')
        admitted, checks, blocked, yields, resumes, maximum, wait, check = (
            number(r, k) for k in ('admitted', 'checks', 'blocked', 'yields', 'resumes',
                                   'max_pending', 'wait_cycles', 'check_cycles'))
        if (min(admitted, checks, blocked, yields, resumes, maximum, wait, check) < 0
                or admitted != number(run['independent'], f'requests{w}')
                or checks < admitted + blocked or blocked < yields or resumes != yields
                or not 0 < maximum <= limit):
            raise ValueError('credit requests/capacity/handoffs differ')
        if run['analysis']:
            if check <= 0 or bool(wait) != bool(yields) or wait > run['graph'] or check > run['graph']:
                raise ValueError('invalid diagnostic credit intervals')
        elif wait or check:
            raise ValueError('formal credit run must not time capacity checks/waits')


def handoffs(run):
    return sum(number(r, 'yields') for r in run.get('credit', {}).values())


def report(runs):
    for r in runs:
        if r.get('credit_limit') and r['mode'] == 'independent' and r['analysis']:
            records = r['credit']
            print(f"run={r['id']} cooperative Conv credit limit={r['credit_limit']}; "
                  f"handoffs={handoffs(r)}; max CPU-issued pending=" +
                  ','.join(str(number(records[w], 'max_pending')) for w in range(3)))
            print('  Credit wait overlaps other workers; capacity check cycles are already '
                  'inside task/scheduler intervals. Original DMA dependency waits retained.')
