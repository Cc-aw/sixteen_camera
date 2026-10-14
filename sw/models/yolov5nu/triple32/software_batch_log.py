"""Integrated v27/v28 formal images; closed version-specific policy records."""
from check_log import number

CREDIT={'worker','retired_reads','budget_reused','status_reads','error_probes',
        'budget_rejects','entrance_rejects','peer_queries','scheduler_queries','admit_queries','resume_queries'}
POLICY={'refill_kept','low_supply_yields','fair_yields','idle_probes'}
SUPPLY_POLICY=POLICY|{'busy_reused','occupancy_probes','fed_deferred','dependency_deferred'}


def validate(run):
    bindings=run.get('batch_bindings',{});credit=run.get('batch_credit',{});policy=run.get('batch_policy',{})
    if not run.get('software_batch'):
        if bindings or credit or policy:raise ValueError('integrated records without v27 capability')
        return
    if (run['analysis'] or run['scheduling']!='supply' or run['credit_limit']!=4
        or run['diagnostic_build'] or run['capacity_period'] or set(bindings)!={0,1,2}
        or run.get('bind_once_cycles',0)<=0):raise ValueError('missing integrated configuration/bindings')
    for w,b in bindings.items():
        if (set(b)!={'worker','generation','batch_cycles'} or number(b,'worker')!=w
            or number(b,'generation')<=0 or not 0<number(b,'batch_cycles')<=run['graph']):
            raise ValueError('invalid integrated binding record')
    if run['mode']!='independent':
        if credit or policy:raise ValueError('supply accounting outside independent mode')
        return
    required=SUPPLY_POLICY if run.get('supply_revision') else POLICY
    if set(credit)!={0,1,2} or set(policy)!=required:raise ValueError('missing integrated supply records')
    for w,q in credit.items():
        if set(q)!=CREDIT or number(q,'worker')!=w:raise ValueError('invalid integrated Credit fields')
        q={k:number(q,k) for k in q};c=run['credit'][w]
        if (min(q.values())<0 or q['retired_reads']+q['budget_reused']!=number(c,'checks')
            or q['budget_rejects']+q['entrance_rejects']!=number(c,'blocked')
            or q['error_probes']!=q['budget_rejects']//16
            or sum(q[k] for k in ('peer_queries','scheduler_queries','admit_queries','resume_queries'))!=number(c,'checks')
            or q['admit_queries']!=number(c,'admitted') or q['resume_queries']!=number(c,'resumes')
            or not q['retired_reads'] or q['status_reads']<q['error_probes']
            or q['status_reads']>q['admit_queries']+q['resume_queries']+q['error_probes']):
            raise ValueError('integrated Credit counts do not close')
    p={k:number(policy,k) for k in policy};old=run['policy']
    if (min(p.values())<0 or p['refill_kept']>number(old,'command_kept')
        or p['low_supply_yields']>number(old,'packet_yields') or p['fair_yields']>number(old,'time_yields')):
        raise ValueError('integrated policy counts do not close')
    if run.get('supply_revision'):
        decisions=sum(number(old,k) for k in ('command_kept','stage_kept','command_yields','stage_yields'))
        if (p['busy_reused']+p['idle_probes']>decisions or p['occupancy_probes']>2*p['idle_probes']
            or p['fed_deferred']>2*decisions or p['dependency_deferred']>2*decisions):
            raise ValueError('supply policy observations exceed decision bounds')


def report(runs):
    for r in runs:
        if not r.get('software_batch'):continue
        if r['mode']!='independent':continue
        q=r['batch_credit'];tot=lambda key:sum(number(row,key) for row in q.values())
        print(f"run={r['id']} integrated supply: retired_reads={tot('retired_reads')} budget_reused={tot('budget_reused')} status_reads={tot('status_reads')} budget_rejects={tot('budget_rejects')} entrance_rejects={tot('entrance_rejects')}")
        print('  Budget-only peer hints; actual packet admission rechecks live ingress. Binding patches are included in batch cycles; one-time binding is reported separately.')
        if r.get('supply_revision'):
            p=r['batch_policy']
            print(f"  Policy-only occupancy CSR reads={number(p,'occupancy_probes')}; busy scans={number(p,'idle_probes')} (three status reads each); reused selection snapshots={number(p,'busy_reused')}; hardware-fed fairness deferrals={number(p,'fed_deferred')}; deferred task-side dependency polls={number(p,'dependency_deferred')}")
