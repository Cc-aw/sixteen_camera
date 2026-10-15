"""Validate staged submission flags and actual credit CSR read accounting."""
from check_log import number

FLAGS = ('credit_query','packet_dispatch','split_diag','diagnostic_build')
FIELDS = {'worker','retired_reads','status_reads','retirement_reused',
          'budget_rejects','hardware_rejects','resume_rechecks','error_probes',
          'peer_queries','scheduler_queries','admit_queries','resume_queries'}


def configuration(version,row):
    defaults=dict(zip(FLAGS,(0,0,0,1)))
    values={k:number(row,k) if k in row else defaults[k] for k in FLAGS}
    if any(v not in (0,1) for v in values.values()):
        raise ValueError('invalid submit optimization flags')
    expected={'v23':(1,0,0,1),'v24':(1,1,0,1)}
    if version in ('v23','v24','v25','v26','v27','v28'):
        if not set(FLAGS)<=row.keys():raise ValueError('missing submit optimization flags')
        if version in ('v25','v26','v27','v28'):
            if tuple(values[k] for k in FLAGS[:3])!=(1,1,1):
                raise ValueError('v25 requires all submit optimizations')
        elif tuple(values[k] for k in FLAGS)!=expected[version]:
            raise ValueError('submit flags differ from firmware version')
    elif values!=defaults:raise ValueError('submit flags without matching firmware version')
    return values


def validate(run):
    records=run.get('credit_query_stats',{})
    if not (run.get('credit_query') and run['analysis'] and run['mode']=='independent'):
        if records:raise ValueError('credit query detail outside enabled diagnosis')
        return
    if set(records)!={0,1,2}:raise ValueError('missing credit query detail')
    for w,r in records.items():
        if set(r)!=FIELDS or number(r,'worker')!=w:
            raise ValueError('invalid credit query schema')
        q={k:number(r,k) for k in FIELDS-{'worker'}}
        if min(q.values())<0:raise ValueError('negative credit query detail')
        c=run['credit'][w]
        if q['retired_reads']+q['retirement_reused']!=number(c,'checks'):
            raise ValueError('retirement read/cache counts differ from logical queries')
        if q['budget_rejects']+q['hardware_rejects']!=number(c,'blocked'):
            raise ValueError('credit rejection classes do not close')
        if q['status_reads']!=number(c,'checks')-q['budget_rejects']+q['error_probes']:
            raise ValueError('status reads differ from capacity/error probes')
        if q['error_probes']!=q['budget_rejects']//16 or q['resume_rechecks']!=number(c,'resumes'):
            raise ValueError('bounded error checks or fresh resume checks differ')
        if (sum(q[k] for k in ('peer_queries','scheduler_queries','admit_queries','resume_queries'))!=number(c,'checks') or
            q['admit_queries']!=number(c,'admitted') or q['resume_queries']!=number(c,'resumes')):
            raise ValueError('credit query origins differ from queries/admissions/resumes')


def report(runs):
    for r in runs:
        rows=r.get('credit_query_stats',{})
        if not rows:continue
        totals={k:sum(number(p,k) for p in rows.values()) for k in FIELDS-{'worker'}}
        print(f"run={r['id']} credit query optimization: actual retired CSR reads={totals['retired_reads']}; "
              f"status CSR reads={totals['status_reads']}; reused retirement observations={totals['retirement_reused']}; "
              f"budget rejects={totals['budget_rejects']}; hardware rejects={totals['hardware_rejects']}")
        print('  Final packet admission rechecks live ingress status; observations are not hardware reservations.')
        print('  Query origins: '+', '.join(f'{k}={totals[k]}' for k in
              ('peer_queries','scheduler_queries','admit_queries','resume_queries')))
