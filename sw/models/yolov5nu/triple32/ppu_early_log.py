"""Validate early PPU timestamps; queue admission alone is not core overlap."""
from check_log import number

EVENT_FIELDS = {'worker', 'graph_done_cycles', 'publication_commit_cycles',
                'enqueue_cycles', 'result_observed_cycles', 'enqueue_done_mask',
                'result_done_mask', 'progress_cycles', 'progress_done_mask'}
SUMMARY_FIELDS = {'published_mask', 'enqueued_mask', 'result_mask', 'progress_mask',
                  'progress_sampling', 'service_calls', 'service_cycles'}


def validate(run):
    events, summary = run['ppu_events'], run.get('ppu_early_stats')
    if not run['ppu_early'] or run['mode'] != 'independent':
        if events or summary is not None:
            raise ValueError('early PPU records outside enabled independent run')
        return
    if set(events) != {0, 1, 2} or summary is None or set(summary) != SUMMARY_FIELDS:
        raise ValueError('requires three PPU events and complete early summary')
    values = {k: number(summary, k) for k in SUMMARY_FIELDS}
    if any(values[k] != 7 for k in ('published_mask', 'enqueued_mask', 'result_mask')):
        raise ValueError('incomplete early PPU workers')
    if (not 0 <= values['progress_mask'] <= 7 or values['progress_sampling'] != run['analysis']
            or values['service_calls'] <= 0 or values['service_cycles'] < 0):
        raise ValueError('invalid early PPU sampling/service counters')
    if not run['analysis'] and (values['progress_mask'] or values['service_cycles']):
        raise ValueError('formal early PPU run must not sample progress or service cycles')
    if values['service_cycles'] > run['graph']:
        raise ValueError('PPU service exceeds graph interval')
    done = {}
    for w, event in events.items():
        if set(event) != EVENT_FIELDS or number(event, 'worker') != w:
            raise ValueError('incomplete PPU event fields')
        done[w] = number(event, 'graph_done_cycles')
    for w, event in events.items():
        g, p, e, r = (number(event, k) for k in ('graph_done_cycles', 'publication_commit_cycles',
                                               'enqueue_cycles', 'result_observed_cycles'))
        valid = 0 < g <= r <= run['batch'] and 0 < p <= min(r,run['graph']) and 0 < e <= r
        if run.get('head_clean'):
            if not run.get('head_admit'):valid = valid and max(g,p)<=e
        else:valid = valid and g<=p<=e
        if not valid:
            raise ValueError('invalid PPU event order or bounds')
        # A full hardware queue can postpone admission until after graph end.
        # Completion masks describe the observation time, not the submitter.
        for field, cycle in (('enqueue_done_mask', e), ('result_done_mask', r)):
            mask = number(event, field)
            expected = sum(1 << peer for peer, c in done.items() if c <= cycle)
            own_required = field=='result_done_mask' or not run.get('head_admit')
            if mask != expected or (own_required and not mask & (1 << w)):
                raise ValueError('PPU completion mask disagrees with graph timestamps')
        pc, pm = number(event, 'progress_cycles'), number(event, 'progress_done_mask')
        if values['progress_mask'] & (1 << w):
            expected = sum(1 << peer for peer, c in done.items() if c <= pc)
            if not e <= pc <= min(r, run['graph']) or pm != expected or pm == 7:
                raise ValueError('invalid hardware PPU progress overlap evidence')
        elif pc or pm:
            raise ValueError('progress event without sampled progress bit')


def report(runs):
    from statistics import median
    enabled = [r for r in runs if r.get('ppu_early') and r['mode'] == 'independent']
    if not enabled:
        return
    if not any(r.get('head_clean') for r in enabled):
        print('Early PPU: each completed worker publishes six heads while peers continue; one shared hardware PPU consumes the queue.')
    print('PPU queue admission does not prove core processing overlap. Diagnostic progress and result masks provide separate evidence.')
    for w in range(3):
        es = [r['ppu_events'][w] for r in enabled if r['phase'] == 'measure']
        if not es:
            es = [r['ppu_events'][w] for r in enabled if not r['analysis']]
        if es and not any(r.get('head_clean') for r in enabled):
            delays = [median(number(e, b)-number(e, a) for e in es) for a, b in
                      (('graph_done_cycles', 'publication_commit_cycles'),
                       ('publication_commit_cycles', 'enqueue_cycles'),
                       ('enqueue_cycles', 'result_observed_cycles'))]
            print(f'worker={w} median publication_delay_cycles={delays[0]:.0f} admission_delay_cycles={delays[1]:.0f} enqueue_to_result_cycles={delays[2]:.0f}')
    for r in enabled:
        if r['analysis']:
            result_mask = sum(1 << w for w, e in r['ppu_events'].items() if number(e, 'result_done_mask') != 7)
            print(f"run={r['id']} PPU progress_overlap_mask={number(r['ppu_early_stats'], 'progress_mask')} result_before_all_graphs_mask={result_mask} scheduler_ppu_service_cycles={number(r['ppu_early_stats'], 'service_cycles')}")
