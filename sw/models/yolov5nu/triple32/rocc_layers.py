"""Validate and rank per-layer operand-ready RoCC dispatch measurements."""
from check_log import number

CLOCK = 100_000_000
BUCKETS = (20, 100, 1000)
KEYS = {'worker', 'stage', 'funct', 'kind', 'label', 'count', 'cycles', 'max_cycles', 'max_index'} | {
    f'{p}{us}' for p in ('n', 'c') for us in BUCKETS}


def validate(run):
    rows = run['rocc_layer_stats']
    if not run['rocc_layers']:
        if rows:
            raise ValueError('layer records without enabled layer diagnosis')
        return
    if not run['diagnostics']:
        raise ValueError('layer diagnosis requires command diagnostics')
    groups = {}
    stage_cycles = {}
    for (w, stage, f), row in rows.items():
        if set(row) != KEYS:
            raise ValueError('invalid layer record fields')
        stage_row = (run['task_stages'].get((w, stage)) if run['mode'] == 'independent'
                     else run['stages'].get(stage))
        if not stage_row or any(row[k] != stage_row[k] for k in ('kind', 'label')):
            raise ValueError('layer label differs from executing graph stage')
        n, c, maximum, index = (number(row, k) for k in ('count', 'cycles', 'max_cycles', 'max_index'))
        if n <= 0 or not 0 < maximum <= c or not n <= c <= n*maximum or not 1 <= index <= n:
            raise ValueError('invalid layer count/peak timing')
        previous_n, previous_c = n, c
        for us in BUCKETS:
            bn, bc = number(row, f'n{us}'), number(row, f'c{us}')
            threshold = CLOCK//1_000_000*us
            if (not 0 <= bn <= previous_n or not 0 <= bc <= previous_c or
                    (bn == 0) != (bc == 0) or not bn*threshold <= bc <= bn*maximum or
                    ((maximum >= threshold) != (bn > 0)) or
                    c-bc > (n-bn)*(threshold-1) or
                    (bn > 0 and bc < maximum+(bn-1)*threshold)):
                raise ValueError('invalid cumulative latency buckets')
            previous_n, previous_c = bn, bc
        group = groups.setdefault((w, f), [0, 0, 0])
        group[0] += n; group[1] += c; group[2] = max(group[2], maximum)
        stage_cycles[(w, stage)] = stage_cycles.get((w, stage), 0) + c
    expected = {key for key in run['rocc'] if key[1] in (11, 15)}
    if set(groups) != expected:
        raise ValueError('missing or extra layer command groups')
    for key, values in groups.items():
        if values != [number(run['rocc'][key], k) for k in ('count', 'cycles', 'max_cycles')]:
            raise ValueError('layer totals differ from worker/funct command totals')
    if run['mode'] == 'independent':
        for key, c in stage_cycles.items():
            if c > number(run['task_stages'][key], 'cpu_cycles'):
                raise ValueError('layer command time exceeds stage CPU time')


def report_run(run, serial=None):
    rows = run['rocc_layer_stats']
    if not rows:
        return
    print(f"\nRun {run['id']} ({run['mode']}): top 12 layer RoCC dispatch totals")
    print('  worker stage funct count total_cycles mean_cycles max_cycles peak_packet >=10000_cycles_count >=10000_cycles_sum label')
    for (w, stage, f), r in sorted(rows.items(), key=lambda x: number(x[1], 'cycles'), reverse=True)[:12]:
        n, c, m = (number(r, k) for k in ('count', 'cycles', 'max_cycles'))
        print(f"  {w:6} {stage:5} {f:5} {n:5} {c:12} {c/n:11.2f} "
              f"{m:10} {number(r,'max_index'):11} {number(r,'n100'):13} "
              f"{number(r,'c100'):12} {r['label']}")
    for f in (15, 11):
        selected = [r for (_, _, funct), r in rows.items() if funct == f]
        total = sum(number(r, 'cycles') for r in selected)
        if not total:
            continue
        print(f'  funct={f}: total={total} cycles; cumulative latency buckets: ' +
              '; '.join(f">={us*CLOCK//1_000_000} cycles count={sum(number(r,f'n{us}') for r in selected)} "
                        f"sum={sum(number(r,f'c{us}') for r in selected)} cycles"
                        for us in BUCKETS))
    if serial is not None:
        before = serial['rocc_layer_stats']
        if set(before) != set(rows) or any(number(rows[k], 'count') != number(before[k], 'count') for k in rows):
            print('  Serial/independent layer command counts differ; skip latency delta ranking.')
            return
        deltas = {k: number(r, 'cycles')-number(before[k], 'cycles') for k, r in rows.items()}
        print('  Top 10 serial -> independent dispatch increases (same worker/image/stage/funct):')
        for (w, stage, f), delta in sorted(deltas.items(), key=lambda x: x[1], reverse=True)[:10]:
            print(f"    worker={w} stage={stage:3} funct={f} "
                  f"serial={number(before[(w,stage,f)],'cycles')} cycles "
                  f"independent={number(rows[(w,stage,f)],'cycles')} cycles "
                  f"delta={delta:+} cycles {rows[(w,stage,f)]['label']}")
    print('  Buckets overlap; never add them. Dispatch latency includes CPU/pipeline/receiver wait, '
          'not a direct hardware backpressure counter. Use unprofiled runs for speedup.')
