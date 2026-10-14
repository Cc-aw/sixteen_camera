#!/usr/bin/env python3
"""Check independent-image runs and report measured throughput/bottlenecks."""
import argparse
from pathlib import Path
from statistics import median
from check_log import fields, number, SIGNATURES, DETECTION_FIELDS, latest_session

IMAGES = ('025', '036', '142')
MODES = ('parallel', 'forward', 'reverse', 'blocked')
ALL_MODES = MODES + ('independent',)
CLOCK = 100_000_000


def parse(text):
    if any(line.strip().startswith('YOLO32_BEGIN ') and 'postprocess=hardware' in line
           for line in text.splitlines()):
        from hardware_log import parse_hardware
        return parse_hardware(text)
    errors, runs, reference = [], [], None
    active = None
    bench = None
    boot_burst = boot_quantum = None
    boot_hot_paths = 0
    boot_layer_build = 0
    boot_fixed_plans = None
    boot_fixed_packets = None
    boot_idle_priority = boot_tail_wait = None
    boot_prepared_packets = None
    boot_ppu_early = None
    boot_early_required = False
    boot_head_required = False
    boot_head_clean = boot_head_admit = None
    boot_wait_reuse = None
    boot_wait_required = False
    boot_credit_limit = None
    boot_credit_required = False
    boot_supply_required = False
    boot_supply_build = 0
    boot_memory_required = False
    boot_memory_ops = 0
    boot_resize_required = False
    boot_resize_batch = boot_resize_rows = 0
    boot_binding_init=0
    boot_version=''
    from capacity_log import configuration as capacity_configuration
    boot_capacity=capacity_configuration('',{})
    boot_submit=dict(credit_query=0,packet_dispatch=0,split_diag=0,diagnostic_build=1)
    from memory_log import validate_smoke
    errors.extend(validate_smoke(text))

    def fail(message):
        errors.append(message)

    def finish(run, ending):
        nonlocal reference
        prefix = f"run {run['id']}: "
        if ending != 'YOLO32_RESULT PASS workers=bit_exact reference=serial':
            fail(prefix + 'missing consistency PASS or firmware FAIL')
        if set(run['workers']) != {0, 1, 2} or set(run['comparisons']) != {0, 1, 2}:
            fail(prefix + 'requires all three workers and serial byte comparisons')
        signatures, detections = {}, {}
        for w in range(3):
            try:
                r = run['workers'][w]
                if r['image'] != IMAGES[w]:
                    raise ValueError('incorrect image mapping')
                signatures[w] = tuple(number(r, k) for k in SIGNATURES)
                if any(not 0 <= v < 2**64 for v in signatures[w]):
                    raise ValueError('signature outside uint64 range')
                count = number(r, 'detections')
                if not 0 <= count <= 10 or not 0 <= number(r, 'candidates') <= 6300 or number(r, 'cycles') <= 0:
                    raise ValueError('invalid counts/cycles')
                ds = run['detections'].get(w, {})
                if set(ds) != set(range(count)):
                    raise ValueError('missing or extra detection')
                detections[w] = tuple(tuple(number(ds[i], k) for k in DETECTION_FIELDS) for i in range(count))
                for d in detections[w]:
                    if not 0 <= d[0] < 80 or any(not 0 <= v < 2**32 for v in d[1:]):
                        raise ValueError('invalid detection fields')
                c = run['comparisons'][w]
                if c['image'] != IMAGES[w] or c['reference'] != 'serial' or number(c, 'mismatches') or c['first'] != 'none' or number(c, 'index'):
                    raise ValueError('byte comparison failed')
            except (KeyError, ValueError) as e:
                fail(prefix + f'worker {w}: {e}')
        if run['phase'] == 'baseline':
            if run['mode'] != 'forward' or run['analysis'] or run['round']:
                fail(prefix + 'invalid serial baseline configuration')
            reference = (signatures, detections)
        elif reference is None:
            fail(prefix + 'missing preceding serial baseline')
        elif (signatures, detections) != reference:
            fail(prefix + 'output differs from corresponding serial image')
        try:
            t = run['timing']
            b, g, p = (number(t, k) for k in ('batch_cycles', 'graph_cycles', 'post_cycles'))
            if min(b, g, p) <= 0 or g + p > b:
                raise ValueError('invalid timing intervals')
            run.update(batch=b, graph=g, post=p)
            from ppu_early_log import validate as validate_ppu_early
            validate_ppu_early(run)
            from ppu_head_log import validate as validate_ppu_heads
            validate_ppu_heads(run)
            from wait_reuse_log import validate as validate_wait_reuse
            validate_wait_reuse(run)
            from credit_log import validate as validate_credit
            validate_credit(run)
        except (KeyError, ValueError) as e:
            fail(prefix + f'timing: {e}')
        if run['mode'] == 'parallel':
            try:
                s = run['parallel']
                groups = number(s, 'tile_groups')
                if number(s, 'conv_groups') != 58 or groups <= 0 or any(number(s, f'requests{w}') != groups for w in range(3)):
                    raise ValueError('invalid tile/request counts')
                if number(s, 'busy_sampling') != run['analysis']:
                    raise ValueError('sampling/profile configuration differs')
                if run['analysis']:
                    if not 0 < number(s, 'triple_overlap_samples') <= number(s, 'overlap_samples') or number(s, 'busy_mask_seen') != 7 or run['parallel_result'] != 'YOLO32_PARALLEL_RESULT PASS':
                        raise ValueError('missing three-worker overlap evidence')
                elif run['parallel_result'] != 'YOLO32_PARALLEL_RESULT UNMEASURED' or any(number(s, k) for k in ('overlap_samples', 'triple_overlap_samples', 'busy_mask_seen')):
                    raise ValueError('formal timing must not sample busy')
            except (KeyError, ValueError) as e:
                fail(prefix + f'parallel evidence: {e}')
        if run['mode'] == 'independent':
            try:
                s = run['independent']
                requests = [number(s, f'requests{w}') for w in range(3)]
                if number(s, 'done_mask') != 7 or min(requests) <= 0 or len(set(requests)) != 1:
                    raise ValueError('incomplete workers or different conv request counts')
                if any(number(s, f'matmuls{w}') <= 0 or number(s, f'resumes{w}') <= 0 or
                       number(s, f'wait_cycles{w}') < 0 for w in range(3)):
                    raise ValueError('missing native matmul/task progress')
                if number(s, 'busy_sampling') != run['analysis']:
                    raise ValueError('sampling/profile configuration differs')
                if (run['idle_priority'] or run['tail_wait']) and 'policy' not in run:
                    raise ValueError('scheduled packets requires policy counters')
                if 'policy' in run:
                    p = run['policy']
                    for key in ('submit_burst', 'quantum_us'):
                        if run[key] is not None and number(p,key) != run[key]:
                            raise ValueError('policy differs from run/boot configuration')
                    keys = ('command_yields', 'stage_yields', 'command_kept', 'stage_kept',
                            'bootstrap_yields', 'idle_yields', 'packet_yields', 'time_yields',
                            'wait_yields', 'no_peer', 'max_quantum_packets')
                    if min(number(p, k) for k in keys) < 0 or min(number(p, k) for k in ('submit_burst', 'quantum_us')) <= 0:
                        raise ValueError('invalid conditional scheduling counters')
                    voluntary = number(p, 'command_yields') + number(p, 'stage_yields')
                    pressure = number(p, 'pressure_yields') if 'pressure_yields' in p else 0
                    if voluntary != pressure + sum(number(p, k) for k in ('bootstrap_yields', 'idle_yields', 'packet_yields', 'time_yields')):
                        raise ValueError('conditional switch reasons differ from handoffs')
                    from credit_log import handoffs as credit_handoffs
                    if voluntary + number(p, 'wait_yields') + credit_handoffs(run) + 3 != sum(number(s, f'resumes{w}') for w in range(3)):
                        raise ValueError('conditional handoffs differ from resumes')
                    if number(p, 'command_yields') + number(p, 'command_kept') != sum(
                            number(s, f'{k}{w}') for w in range(3) for k in ('requests', 'matmuls')):
                        raise ValueError('conditional command decisions differ from native packets')
                    if run['idle_priority'] or run['tail_wait'] or 'tail' in run:
                        t = run.get('tail', {})
                        if set(t) != {'deferred', 'merges', 'conv', 'ws'}:
                            raise ValueError('missing or invalid tail wait record')
                        deferred, merges, conv, ws = (number(t, k) for k in ('deferred', 'merges', 'conv', 'ws'))
                        if (min(deferred, merges, conv, ws) < 0 or deferred != merges or merges != conv + ws
                                or merges > number(p, 'wait_yields') or deferred > number(p, 'command_kept')
                                or conv > sum(number(s, f'requests{w}') for w in range(3))
                                or ws > sum(number(s, f'matmuls{w}') for w in range(3))):
                            raise ValueError('tail wait counters differ from packets/waits')
                        if run['tail_wait']:
                            if not conv or not ws: raise ValueError('missing convolution or WS tail merges')
                        elif deferred:
                            raise ValueError('tail waits recorded while disabled')
                    if 'pressure_yields' in p:
                        feedback_keys = ('pressure_yields', 'feedback_commands', 'feedback_cycles', 'dispatch_max_cycles',
                                         'slow_dispatches', 'burst_reductions', 'burst_recoveries', 'cached_ready_hits')
                        if min(number(p, k) for k in feedback_keys) < 0 or not (
                                0 < number(p, 'recover_us') < number(p, 'block_us') and number(p, 'fast_packets') > 0):
                            raise ValueError('invalid latency feedback configuration/counters')
                        if run['scheduling'] == 'adaptive':
                            packets = sum(number(s, f'{k}{w}') for w in range(3) for k in ('requests', 'matmuls'))
                            count, cycles, maximum = (number(p,k) for k in ('feedback_commands','feedback_cycles','dispatch_max_cycles'))
                            reductions, recoveries = (number(p,k) for k in ('burst_reductions','burst_recoveries'))
                            if (count != packets or not 0 < maximum <= cycles or cycles < count or maximum*count < cycles
                                    or not 0 <= number(p,'slow_dispatches') <= count
                                    or not 0 <= reductions <= number(p,'slow_dispatches')
                                    or not 0 <= reductions-recoveries <= 3 or pressure > number(p,'command_yields')):
                                raise ValueError('latency feedback differs from native packets/handoffs')
                        elif any(number(p,k) for k in feedback_keys
                                 if k != 'cached_ready_hits' or not run['hot_paths']):
                            raise ValueError('fixed policy must not use latency feedback/completion caching')
                    elif run['scheduling'] == 'adaptive':
                        raise ValueError('missing latency feedback records')
                if run['analysis']:
                    if not 0 < number(s, 'triple_overlap_samples') <= number(s, 'overlap_samples') or number(s, 'busy_mask_seen') != 7:
                        raise ValueError('missing three-worker busy overlap')
                    if number(s, 'ahead_submissions') <= 0 or not run['ahead']:
                        raise ValueError('missing independent cross-stage progress')
                    if run['independent_result'] != 'YOLO32_INDEPENDENT_RESULT PASS':
                        raise ValueError('missing independent PASS')
                    for t in run['ahead']:
                        w, mask = number(t, 'worker'), number(t, 'busy_mask')
                        ss = [number(t, f'stage{k}') for k in range(3)]
                        if w not in range(3) or not 0 <= mask <= 7 or any(not 0 <= v <= 167 for v in ss) or not any(
                            k != w and (mask & (1 << k)) and ss[k] < ss[w] for k in range(3)):
                            raise ValueError('invalid ahead trace')
                elif (run['independent_result'] != 'YOLO32_INDEPENDENT_RESULT UNMEASURED' or run['ahead'] or
                      any(number(s, k) for k in ('ahead_submissions', 'overlap_samples', 'triple_overlap_samples', 'busy_mask_seen'))):
                    raise ValueError('formal timing must not sample progress/busy')
            except (KeyError, ValueError) as e:
                fail(prefix + f'independent evidence: {e}')
        if run['analysis']:
            expected_stages = {(w, s) for w in range(3) for s in range(165)} if run['mode'] == 'independent' else set(range(165))
            measured_stages = run['task_stages'] if run['mode'] == 'independent' else run['stages']
            if set(run['profiles']) != {0, 1, 2} or set(measured_stages) != expected_stages:
                fail(prefix + 'missing worker profiles or graph stages')
            for w, r in run['profiles'].items():
                try:
                    if r['image'] != IMAGES[w] or any(number(r, k) < 0 for k in ('gem_busy', 'exec', 'load_stall', 'store_stall', 'conv_call', 'fence', 'rvv')):
                        raise ValueError('invalid profile')
                except (KeyError, ValueError) as e:
                    fail(prefix + f'profile: {e}')
            for r in run['stages'].values():
                try:
                    if number(r, 'cycles') < 0 or not r['kind'] or not r['label']:
                        raise ValueError('invalid stage')
                except (KeyError, ValueError) as e:
                    fail(prefix + f'stage: {e}')
            for r in run['task_stages'].values():
                try:
                    if any(number(r, k) < 0 for k in ('cpu_cycles', 'span_cycles')) or not r['kind'] or not r['label']:
                        raise ValueError('invalid task stage')
                    if run['diagnostics'] and number(r,'cpu_cycles')>number(r,'span_cycles'):
                        raise ValueError('stage CPU exceeds its wall span')
                except (KeyError, ValueError) as e:
                    fail(prefix + f'task stage: {e}')
            if run['mode'] == 'parallel':
                try:
                    if any(number(run['group'], k) < 0 for k in ('submit_cycles', 'wait_cycles')):
                        raise ValueError('invalid group profile')
                except (KeyError, ValueError) as e:
                    fail(prefix + f'group profile: {e}')
        if run['diagnostics']:
            try:
                if not run['analysis'] or {w for w,_ in run['rocc']}!={0,1,2}:
                    raise ValueError('missing command diagnostics or profiling disabled')
                for (w,f),s in run['rocc'].items():
                    n,c,m=(number(s,k) for k in ('count','cycles','max_cycles'))
                    if n<=0 or not 0<m<=c or c<n or m*n<c:
                        raise ValueError('invalid command counts/timing')
                if run['mode']=='independent':
                    p=run['scheduler']
                    if set(run['task_cpu'])!={0,1,2}: raise ValueError('missing task CPU records')
                    wall=sum(number(s,'wall_cycles') for s in run['task_cpu'].values())
                    context=sum(number(s,'context_cycles') for s in run['task_cpu'].values())
                    step,sched,switch=(number(p,k) for k in ('step_cycles','scheduler_cycles','switch_cycles'))
                    if step!=sched+wall or switch!=context or min(step,sched,switch)<=0 or step>run['graph']:
                        raise ValueError('scheduler/task/switch accounting differs')
                    if number(p,'switch_count')!=2*sum(number(run['independent'],f'resumes{w}') for w in range(3)):
                        raise ValueError('switch count differs from task resumes')
                    if not 0<=number(p,'ready_cycles')<=sched or not 0<=number(p,'ready_blocked')<=number(p,'ready_checks') or number(p,'idle_steps')<0:
                        raise ValueError('invalid completion polling diagnostics')
                    if run['hot_paths']:
                        idle,active=(number(p,k) for k in ('idle_scheduler_cycles','active_scheduler_cycles'))
                        resumes=sum(number(run['independent'],f'resumes{w}') for w in range(3))
                        if min(idle,active)<0 or idle+active!=sched or number(p,'scheduler_steps')!=resumes:
                            raise ValueError('idle/active scheduler accounting differs')
                    for w,s in run['task_cpu'].items():
                        native=sum(number(p,'cycles') for (worker,f),p in run['rocc'].items() if worker==w and f!=7)
                        if native+number(s,'context_cycles')>number(s,'wall_cycles') or number(s,'context_cycles')<0:
                            raise ValueError('command/switch time exceeds task quantum time')
                        for f,key in ((15,'requests'),(8,'matmuls')):
                            if number(run['rocc'][(w,f)],'count')!=number(run['independent'],f'{key}{w}'):
                                raise ValueError('native command counts differ from scheduler')
                    if run['scheduling'] == 'adaptive':
                        feedback = [s for (w,f),s in run['rocc'].items() if f in (11,15)]
                        policy = run['policy']
                        if (number(policy,'feedback_cycles') != sum(number(s,'cycles') for s in feedback) or
                                number(policy,'feedback_commands') != sum(number(s,'count') for s in feedback) or
                                number(policy,'dispatch_max_cycles') != max(number(s,'max_cycles') for s in feedback)):
                            raise ValueError('latency feedback differs from operand-ready dispatch diagnostics')
            except (KeyError,ValueError) as e:
                fail(prefix+f'CPU diagnostics: {e}')
        try:
            from rocc_layers import validate
            validate(run)
            from supply_diag_log import validate as validate_supply
            validate_supply(run)
            from memory_log import validate as validate_memory
            validate_memory(run)
            from submit_log import validate as validate_submit
            validate_submit(run)
            from capacity_log import validate as validate_capacity
            validate_capacity(run)
            from software_batch_log import validate as validate_batch
            validate_batch(run)
        except (KeyError, ValueError) as e:
            fail(prefix + f'layer diagnostics: {e}')
        runs.append(run)
        if bench is not None:
            bench['runs'].append(run)

    def finish_bench(ending):
        if ending != 'YOLO32_BENCH_RESULT PASS':
            fail('benchmark reported FAIL')
        modes = bench['modes']
        if set(bench['summaries']) != set(modes):
            fail('benchmark requires all configured mode summaries')
        per_mode=6+bench['diagnostic_build']
        if len(bench['runs']) != per_mode * len(modes) or any(r['phase'] not in ('warmup', 'measure', 'analysis') or r['mode'] not in modes for r in bench['runs']):
            fail(f'benchmark must contain exactly {per_mode * len(modes)} configured runs')
        medians = {}
        for mode in modes:
            subset = [r for r in bench['runs'] if r['mode'] == mode]
            measured = [r for r in subset if r['phase'] == 'measure']
            if (len(measured) != 5 or {r['round'] for r in measured} != set(range(1, 6))
                    or sum(r['phase'] == 'warmup' for r in subset) != 1
                    or sum(r['phase'] == 'analysis' for r in subset) != bench['diagnostic_build']):
                fail(f'benchmark {mode}: missing/duplicate measured rounds, warmup or profile')
            if len(measured) == 5 and all('batch' in r for r in measured):
                medians[mode] = (int(median(r['batch'] for r in measured)), int(median(r['graph'] for r in measured)))
        for mode in modes:
            try:
                b, g = medians[mode]
                rb, rg = medians['forward']
                s = bench['summaries'][mode]
                expected = dict(samples=5, median_batch_cycles=b, median_graph_cycles=g,
                                speedup_batch_milli=rb*1000//b, speedup_graph_milli=rg*1000//g,
                                fps_milli=CLOCK*3000//b)
                if any(number(s, k) != v for k, v in expected.items()):
                    raise ValueError('summary disagrees with measured rounds')
            except (KeyError, ValueError, ZeroDivisionError) as e:
                fail(f'benchmark {mode}: {e}')

    for raw in text.splitlines():
        line = raw.strip()
        try:
            if line.startswith('YOLO32_FIRMWARE '):
                boot_version=line.split()[1]
                boot_binding_init=0
                boot_capacity=capacity_configuration('',{})
                boot_submit=dict(credit_query=0,packet_dispatch=0,split_diag=0,diagnostic_build=1)
                boot_resize_required = boot_version in ('v22','v23','v24','v25','v26','v27','v28')
                boot_resize_batch = boot_resize_rows = 0
                boot_memory_required = line.startswith('YOLO32_FIRMWARE v21 ') or boot_resize_required
                boot_memory_ops = 0
                boot_supply_required = line.startswith('YOLO32_FIRMWARE v20 ')
                boot_supply_build = 0
                boot_credit_required = line.startswith('YOLO32_FIRMWARE v19 ') or boot_supply_required or boot_memory_required
                boot_wait_required = line.startswith('YOLO32_FIRMWARE v18 ') or boot_credit_required
                boot_head_required = line.startswith('YOLO32_FIRMWARE v17 ') or boot_wait_required
                boot_early_required = line.startswith('YOLO32_FIRMWARE v16 ') or boot_head_required
                boot_burst = boot_quantum = None
                boot_hot_paths = 0
                boot_layer_build = 0
                boot_fixed_plans = None
                boot_fixed_packets = None
                boot_idle_priority = boot_tail_wait = None
                boot_prepared_packets = None
                boot_ppu_early = None
                boot_head_clean = boot_head_admit = None
                boot_wait_reuse = None
                boot_credit_limit = None
            elif line.startswith('YOLO32_SCHED_CONFIG '):
                r = fields(line)
                from submit_log import configuration
                boot_submit=configuration(boot_version,r)
                boot_capacity=capacity_configuration(boot_version,r,boot=True)
                boot_memory_ops=number(r,'memory_ops') if 'memory_ops' in r else 0
                if boot_memory_ops not in (0,1) or bool(boot_memory_ops)!=boot_memory_required:
                    raise ValueError('memory operators differ from firmware version')
                if boot_resize_required and not {'resize_batch','resize_rows'} <= r.keys():
                    raise ValueError('v22 boot requires Resize batch configuration')
                boot_resize_batch=number(r,'resize_batch') if 'resize_batch' in r else 0
                boot_resize_rows=number(r,'resize_rows') if 'resize_rows' in r else 0
                from memory_kernels import expected_counts
                expected_counts(boot_resize_batch,boot_resize_rows)
                if bool(boot_resize_batch)!=boot_resize_required:
                    raise ValueError('Resize batch differs from firmware version')
                boot_supply_build=number(r,'supply_diag') if 'supply_diag' in r else 0
                if boot_supply_build not in (0,1) or bool(boot_supply_build)!=boot_supply_required:
                    raise ValueError('supply build flag differs from firmware version')
                if boot_early_required and 'ppu_early' not in r:
                    raise ValueError('v16 boot requires early PPU flag')
                boot_burst, boot_quantum = number(r,'submit_burst'), number(r,'quantum_us')
                boot_hot_paths = number(r,'hot_paths') if 'hot_paths' in r else 0
                boot_layer_build=number(r,'rocc_layers') if 'rocc_layers' in r else 0
                boot_fixed_plans=number(r,'fixed_plans') if 'fixed_plans' in r else 0
                if boot_fixed_plans not in (0,1): raise ValueError('invalid fixed plans configuration')
                boot_fixed_packets=number(r,'fixed_packets') if 'fixed_packets' in r else 0
                if boot_fixed_packets not in (0,1) or boot_fixed_packets > boot_fixed_plans:
                    raise ValueError('invalid fixed packets configuration')
                boot_idle_priority = number(r, 'idle_priority') if 'idle_priority' in r else 0
                boot_tail_wait = number(r, 'tail_wait') if 'tail_wait' in r else 0
                if boot_idle_priority not in (0, 1) or boot_tail_wait not in (0, 1) or boot_tail_wait > boot_fixed_packets:
                    raise ValueError('invalid scheduled packets configuration')
                boot_prepared_packets = number(r,'prepared_packets') if 'prepared_packets' in r else 0
                if boot_prepared_packets not in (0,1) or boot_prepared_packets > boot_fixed_packets:
                    raise ValueError('invalid prepared packets configuration')
                boot_ppu_early = number(r,'ppu_early') if 'ppu_early' in r else 0
                if (boot_ppu_early not in (0,1) or boot_ppu_early > boot_prepared_packets
                        or (boot_early_required and boot_ppu_early != 1)):
                    raise ValueError('invalid early PPU configuration')
                if boot_head_required and not {'head_clean','head_admit'} <= r.keys():
                    raise ValueError('v17 requires head clean/admission configuration')
                boot_head_clean=number(r,'head_clean') if 'head_clean' in r else 0
                boot_head_admit=number(r,'head_admit') if 'head_admit' in r else 0
                if (boot_head_clean not in (0,1) or boot_head_admit not in (0,1)
                        or boot_head_clean>boot_ppu_early or boot_head_admit>boot_head_clean
                        or (boot_head_required and boot_head_clean!=1)):
                    raise ValueError('invalid head clean/admission configuration')
                if boot_layer_build not in (0,1): raise ValueError('invalid layer build configuration')
                if not boot_submit['diagnostic_build'] and boot_layer_build:
                    raise ValueError('formal-only build cannot enable layer diagnostics')
                if boot_wait_required and 'wait_reuse' not in r:
                    raise ValueError('v18 requires wait reuse flag')
                boot_wait_reuse=number(r,'wait_reuse') if 'wait_reuse' in r else 0
                if (boot_wait_reuse not in (0,1) or (boot_wait_required and not boot_wait_reuse)
                        or (boot_wait_reuse and (not boot_head_clean or boot_head_admit))):
                    raise ValueError('wait reuse requires the A baseline')
                if boot_credit_required and 'credit_limit' not in r:
                    raise ValueError('v19 boot requires credit limit')
                boot_credit_limit=number(r,'credit_limit') if 'credit_limit' in r else 0
                if (boot_credit_limit not in ((3,4) if boot_capacity['capacity_experiment'] else (0,3)) or bool(boot_credit_limit)!=boot_credit_required
                        or (boot_credit_limit and not boot_wait_reuse)):
                    raise ValueError('credit limit differs from firmware or v18 baseline')
                if boot_hot_paths not in (0,1): raise ValueError('invalid hot paths configuration')
                if min(boot_burst,boot_quantum) <= 0:
                    raise ValueError('invalid boot scheduling configuration')
            elif line.startswith('YOLO32_BENCH_BEGIN '):
                if bench is not None or active is not None:
                    raise ValueError('nested benchmark')
                r = fields(line)
                if number(r, 'rounds') != 5 or number(r, 'warmups') != 1 or number(r, 'clock_hz') != CLOCK:
                    raise ValueError('invalid benchmark configuration')
                modes = int(r.get('modes', '4'), 0)
                if modes not in (4, 5): raise ValueError('unsupported mode count')
                bench = {'runs': [], 'summaries': {}, 'modes': ALL_MODES if modes == 5 else MODES,
                         'diagnostic_build':0 if boot_capacity['capacity_experiment'] else boot_submit['diagnostic_build']}
            elif line.startswith('YOLO32_BENCH_RESULT '):
                if bench is None or active is not None:
                    raise ValueError('benchmark result without complete benchmark')
                finish_bench(line)
                bench = None
            elif line.startswith('YOLO32_BENCH '):
                if bench is None:
                    raise ValueError('summary outside benchmark')
                r = fields(line)
                if r['mode'] not in bench['modes'] or r['mode'] in bench['summaries']:
                    raise ValueError('invalid/duplicate mode summary')
                bench['summaries'][r['mode']] = r
            elif line.startswith('YOLO32_BEGIN '):
                if active is not None:
                    fail(f"run {active['id']}: truncated before next run")
                r = fields(line)
                if (r['images'] != ','.join(IMAGES) or number(r, 'dim') != 32 or number(r, 'workers') != 3
                        or r['reference'] != 'serial' or r['mode'] not in ALL_MODES
                        or r['phase'] not in (('baseline', 'manual', 'warmup', 'measure', 'analysis', 'capacity') if boot_version=='v26' else ('baseline', 'manual', 'warmup', 'measure', 'analysis'))
                        or number(r, 'profile') not in (0, 1)):
                    raise ValueError('invalid run configuration')
                if boot_early_required and 'ppu_early' not in r:
                    raise ValueError('v16 run requires early PPU flag')
                analysis = number(r, 'profile')
                diagnostics = number(r,'diagnostics') if 'diagnostics' in r else 0
                rocc_layers = number(r,'rocc_layers') if 'rocc_layers' in r else 0
                if boot_layer_build and rocc_layers != diagnostics:
                    raise ValueError('layer build requires layer records on analysis runs')
                if rocc_layers not in (0,1) or rocc_layers > diagnostics:
                    raise ValueError('invalid layer diagnostics configuration')
                context = r.get('context', 'full')
                if context not in ('full', 'light'):
                    raise ValueError('invalid task context mode')
                scheduling = r.get('scheduling', 'fixed')
                if scheduling not in (('supply',) if boot_version in ('v27','v28') else ('adaptive','fixed')):
                    raise ValueError('invalid scheduling policy')
                burst = number(r,'submit_burst') if 'submit_burst' in r else boot_burst
                quantum = number(r,'quantum_us') if 'quantum_us' in r else boot_quantum
                hot_paths = number(r,'hot_paths') if 'hot_paths' in r else boot_hot_paths
                fixed_plans = number(r,'fixed_plans') if 'fixed_plans' in r else (boot_fixed_plans or 0)
                if fixed_plans not in (0,1) or (boot_fixed_plans is not None and fixed_plans != boot_fixed_plans):
                    raise ValueError('fixed plans differs from boot configuration')
                fixed_packets = number(r,'fixed_packets') if 'fixed_packets' in r else (boot_fixed_packets or 0)
                if (fixed_packets not in (0,1) or fixed_packets > fixed_plans or
                        (boot_fixed_packets is not None and fixed_packets != boot_fixed_packets)):
                    raise ValueError('fixed packets differs from boot configuration or plans')
                idle_priority = number(r, 'idle_priority') if 'idle_priority' in r else (boot_idle_priority or 0)
                tail_wait = number(r, 'tail_wait') if 'tail_wait' in r else (boot_tail_wait or 0)
                if (idle_priority not in (0, 1) or tail_wait not in (0, 1) or tail_wait > fixed_packets
                        or (boot_idle_priority is not None and idle_priority != boot_idle_priority)
                        or (boot_tail_wait is not None and tail_wait != boot_tail_wait)):
                    raise ValueError('scheduled packets differs from boot configuration or packets')
                prepared_packets = number(r,'prepared_packets') if 'prepared_packets' in r else (boot_prepared_packets or 0)
                if (prepared_packets not in (0,1) or prepared_packets > fixed_packets
                        or (boot_prepared_packets is not None and prepared_packets != boot_prepared_packets)):
                    raise ValueError('prepared packets differs from boot configuration or packets')
                ppu_early = number(r,'ppu_early') if 'ppu_early' in r else (boot_ppu_early or 0)
                if (ppu_early not in (0,1) or ppu_early > prepared_packets
                        or (boot_ppu_early is not None and ppu_early != boot_ppu_early)
                        or (boot_early_required and ppu_early != 1)):
                    raise ValueError('early PPU differs from boot configuration or packets')
                if boot_head_required and not {'head_clean','head_admit'} <= r.keys():
                    raise ValueError('v17 run requires head clean/admission flags')
                head_clean=number(r,'head_clean') if 'head_clean' in r else (boot_head_clean or 0)
                head_admit=number(r,'head_admit') if 'head_admit' in r else (boot_head_admit or 0)
                if (head_clean not in (0,1) or head_admit not in (0,1) or head_clean>ppu_early
                        or head_admit>head_clean or (boot_head_required and head_clean!=1)
                        or (boot_head_clean is not None and head_clean!=boot_head_clean)
                        or (boot_head_admit is not None and head_admit!=boot_head_admit)):
                    raise ValueError('head clean/admission differs from boot configuration')
                if hot_paths not in (0,1): raise ValueError('invalid hot paths configuration')
                if boot_wait_required and 'wait_reuse' not in r:
                    raise ValueError('v18 run requires wait reuse flag')
                wait_reuse=number(r,'wait_reuse') if 'wait_reuse' in r else (boot_wait_reuse or 0)
                if (wait_reuse not in (0,1) or (boot_wait_required and not wait_reuse)
                        or (wait_reuse and (not head_clean or head_admit))
                        or (boot_wait_reuse is not None and wait_reuse!=boot_wait_reuse)):
                    raise ValueError('wait reuse differs from boot configuration or A baseline')
                if boot_credit_required and 'credit_limit' not in r:
                    raise ValueError('v19 run requires credit limit')
                capacity=capacity_configuration(boot_version,r)
                if any(capacity[k]!=boot_capacity[k] for k in capacity if k!='capacity_period'):
                    raise ValueError('capacity flags differ from boot')
                if bool(capacity['capacity_period'])!=(r['phase']=='capacity') or (capacity['capacity_period'] and r['mode']!='independent'):
                    raise ValueError('capacity sampling differs from run phase/mode')
                credit_limit=number(r,'credit_limit') if 'credit_limit' in r else (boot_credit_limit or 0)
                if (credit_limit not in ((3,4) if capacity['capacity_experiment'] else (0,3)) or (boot_credit_required and not credit_limit)
                        or (credit_limit and not wait_reuse)
                        or (boot_credit_limit is not None and credit_limit!=boot_credit_limit)):
                    raise ValueError('credit limit differs from boot configuration or v18 baseline')
                supply_diag=number(r,'supply_diag') if 'supply_diag' in r else 0
                supply_detail=number(r,'supply_detail') if 'supply_detail' in r else 0
                memory_ops=number(r,'memory_ops') if 'memory_ops' in r else 0
                if memory_ops not in (0,1) or memory_ops!=boot_memory_ops:
                    raise ValueError('memory operators differ from boot configuration')
                if boot_resize_required and not {'resize_batch','resize_rows'} <= r.keys():
                    raise ValueError('v22 run requires Resize batch configuration')
                resize_batch=number(r,'resize_batch') if 'resize_batch' in r else 0
                resize_rows=number(r,'resize_rows') if 'resize_rows' in r else 0
                if (resize_batch,resize_rows)!=(boot_resize_batch,boot_resize_rows):
                    raise ValueError('Resize batch differs from boot configuration')
                if (supply_diag not in (0,1) or
                    supply_diag != int(bool(boot_supply_build and analysis and r['mode'] in ('forward','independent')))):
                    raise ValueError('supply diagnosis flag differs from build/run mode')
                if supply_detail not in (0,1) or supply_detail>supply_diag or (boot_supply_build and 'supply_detail' not in r):
                    raise ValueError('invalid/missing supply detail flag')
                if any(v is not None and v <= 0 for v in (burst,quantum)):
                    raise ValueError('invalid run scheduling configuration')
                if diagnostics not in (0,1) or diagnostics>analysis:
                    raise ValueError('invalid diagnostics configuration')
                from submit_log import configuration
                submit=configuration(boot_version,r)
                if submit!=boot_submit or (analysis and not submit['diagnostic_build']):
                    raise ValueError('submit flags differ from boot or formal-only capability')
                if bool(analysis) != (r['phase'] == 'analysis') or (r['phase'] != 'measure' and number(r, 'round') != 0):
                    raise ValueError('invalid phase/round/profile combination')
                if r['phase'] == 'measure' and not 1 <= number(r, 'round') <= 5:
                    raise ValueError('invalid measured round')
                active = dict(id=number(r, 'run'), mode=r['mode'], phase=r['phase'],
                              round=number(r, 'round'), analysis=analysis, workers={},
                              comparisons={}, detections={}, profiles={}, stages={}, task_stages={}, ahead=[],
                              diagnostics=diagnostics, context=context, scheduling=scheduling,
                              submit_burst=burst, quantum_us=quantum, hot_paths=hot_paths, rocc={}, task_cpu={}, rocc_layers=rocc_layers, rocc_layer_stats={}, layer_build=boot_layer_build, fixed_plans=fixed_plans, fixed_packets=fixed_packets,
                              idle_priority=idle_priority, tail_wait=tail_wait, prepared_packets=prepared_packets,
                              ppu_early=ppu_early, ppu_events={}, head_clean=head_clean,
                              head_admit=head_admit, head_events={}, head_states={}, wait_reuse=wait_reuse,
                              credit_limit=credit_limit, credit={}, supply_diag=supply_diag,
                              supply_build=boot_supply_build, credit_sources={}, supply={},
                              cpu_details={}, hw_stages={}, feed_stages={}, hw_totals={}, supply_detail=supply_detail,
                              memory_ops=memory_ops, memory={}, resize_batch=resize_batch, resize_rows=resize_rows,
                              credit_query_stats={}, capacity_stats={}, capacity_gaps={}, batch_bindings={}, batch_credit={}, batch_policy={}, bind_once_cycles=boot_binding_init, **submit, **capacity)
            elif line.startswith('YOLO32_BATCH_INIT '):
                if active is not None or boot_version not in ('v27','v28') or boot_binding_init:
                    raise ValueError('invalid/duplicate integrated init')
                init=fields(line)
                if set(init)!={'bind_once_cycles'} or number(init,'bind_once_cycles')<=0:
                    raise ValueError('invalid integrated init fields')
                boot_binding_init=number(init,'bind_once_cycles')
            elif line.startswith(('YOLO32_BATCH_BIND ','YOLO32_BATCH_CREDIT ','YOLO32_BATCH_POLICY ')):
                if active is None or not active.get('software_batch'):
                    raise ValueError('integrated record outside v27/v28 run')
                row=fields(line)
                if line.startswith('YOLO32_BATCH_POLICY '):
                    if active['batch_policy']:raise ValueError('duplicate integrated policy')
                    active['batch_policy']=row
                else:
                    w=number(row,'worker');key='batch_bindings' if line.startswith('YOLO32_BATCH_BIND ') else 'batch_credit'
                    if w not in range(3) or w in active[key]:raise ValueError('invalid/duplicate integrated worker')
                    active[key][w]=row
            elif line.startswith(('YOLO32_CAPACITY ', 'YOLO32_CAPACITY_GAP ')):
                if active is None:raise ValueError('capacity record outside run')
                r=fields(line);w=number(r,'worker')
                if w not in range(3):raise ValueError('invalid capacity worker')
                summary=line.startswith('YOLO32_CAPACITY ')
                key=w if summary else (w,number(r,'index'))
                target=active['capacity_stats' if summary else 'capacity_gaps']
                if key in target:raise ValueError('duplicate capacity record')
                target[key]=r
            elif line.startswith('YOLO32_CREDIT_QUERY '):
                if active is None:raise ValueError('credit query record outside run')
                r=fields(line);w=number(r,'worker')
                if w not in range(3) or w in active['credit_query_stats']:
                    raise ValueError('invalid/duplicate credit query worker')
                active['credit_query_stats'][w]=r
            elif line.startswith('YOLO32_MEMORY '):
                if active is None: raise ValueError('memory record outside run')
                r=fields(line); w=number(r,'worker')
                if w not in range(3) or w in active['memory']:
                    raise ValueError('invalid/duplicate memory worker')
                active['memory'][w]=r
            elif line.startswith(('YOLO32_CREDIT_SOURCE ', 'YOLO32_SUPPLY ', 'YOLO32_CPU_DETAIL ', 'YOLO32_HW_STAGE ', 'YOLO32_FEED_STAGE ', 'YOLO32_HW_TOTAL ')):
                if active is None: raise ValueError('supply diagnostic record outside run')
                from supply_diag_log import RECORDS, SOURCES
                r=fields(line); w=number(r,'worker'); kind=line.split()[0]
                if w not in range(3): raise ValueError('invalid supply diagnostic worker')
                target=active[RECORDS[kind]]
                if kind=='YOLO32_CREDIT_SOURCE':
                    if r['source'] not in SOURCES: raise ValueError('invalid credit query origin')
                    key=(w,r['source'])
                elif kind in ('YOLO32_SUPPLY','YOLO32_HW_TOTAL'): key=w
                else:
                    stage=number(r,'stage')
                    if stage not in range(165): raise ValueError('invalid supply diagnostic stage')
                    key=(w,stage)
                if key in target: raise ValueError('duplicate supply diagnostic record')
                target[key]=r
            elif line.startswith('YOLO32_CREDIT '):
                if active is None: raise ValueError('credit record outside run')
                r=fields(line); w=number(r,'worker')
                if w not in range(3) or w in active['credit']:
                    raise ValueError('invalid/duplicate credit worker')
                active['credit'][w]=r
            elif line.startswith('YOLO32_WAIT_REUSE '):
                if active is None or 'wait_reuse_stats' in active:
                    raise ValueError('outside/duplicate wait reuse summary')
                active['wait_reuse_stats']=fields(line)
            elif line.startswith('YOLO32_HEAD_EVENT '):
                if active is None: raise ValueError('head event outside run')
                r=fields(line);key=(number(r,'worker'),number(r,'head'))
                if key[0] not in range(3) or key[1] not in range(6) or key in active['head_events']:
                    raise ValueError('invalid/duplicate head event')
                active['head_events'][key]=r
            elif line.startswith('YOLO32_HEAD_STATE '):
                if active is None: raise ValueError('head state outside run')
                r=fields(line);w=number(r,'worker')
                if w not in range(3) or w in active['head_states']:raise ValueError('invalid/duplicate head state')
                active['head_states'][w]=r
            elif line.startswith('YOLO32_HEAD_CLEAN '):
                if active is None or 'head_stats' in active:raise ValueError('outside/duplicate head summary')
                active['head_stats']=fields(line)
            elif line.startswith('YOLO32_PPU_EVENT '):
                if active is None: raise ValueError('PPU event outside run')
                r=fields(line); w=number(r,'worker')
                if w not in range(3) or w in active['ppu_events']: raise ValueError('invalid/duplicate PPU event')
                active['ppu_events'][w]=r
            elif line.startswith('YOLO32_PPU_EARLY '):
                if active is None or 'ppu_early_stats' in active: raise ValueError('outside/duplicate early PPU summary')
                active['ppu_early_stats']=fields(line)
            elif line.startswith('YOLO32_RESULT '):
                if active is None:
                    raise ValueError('result without run')
                finish(active, line)
                active = None
            elif line.startswith('YOLO32_ROCC_LAYER '):
                if active is None: raise ValueError('layer record outside run')
                r=fields(line); w, stage, f=(number(r,k) for k in ('worker','stage','funct'))
                if w not in range(3) or not 0 <= stage < 165 or f not in (11,15):
                    raise ValueError('invalid layer command identifier')
                key=(w,stage,f)
                if key in active['rocc_layer_stats']: raise ValueError('duplicate layer command record')
                active['rocc_layer_stats'][key]=r
            elif active is not None and line.startswith('YOLO32_AHEAD '):
                active['ahead'].append(fields(line))
            elif active is not None and line.startswith(('YOLO32_ROCC ','YOLO32_TASK_CPU ')):
                r=fields(line); w=number(r,'worker')
                if w not in range(3): raise ValueError('invalid diagnostic worker')
                if line.startswith('YOLO32_ROCC '):
                    f=number(r,'funct')
                    if not 0<=f<32: raise ValueError('invalid command funct')
                    target,key=active['rocc'],(w,f)
                else: target,key=active['task_cpu'],w
                if key in target: raise ValueError('duplicate CPU diagnostic record')
                target[key]=r
            elif active is not None and line.startswith('YOLO32_SCHED_PROFILE '):
                if 'scheduler' in active: raise ValueError('duplicate scheduler profile')
                active['scheduler']=fields(line)
            elif active is not None and line.startswith(('YOLO32_WORKER ', 'YOLO32_COMPARE ', 'YOLO32_DETECTION ', 'YOLO32_PROFILE ', 'YOLO32_STAGE ', 'YOLO32_TASK_STAGE ')):
                r = fields(line)
                kind = line.split()[0]
                if kind == 'YOLO32_TASK_STAGE':
                    w, s = number(r, 'worker'), number(r, 'stage')
                    if w not in range(3) or not 0 <= s < 165: raise ValueError('invalid worker stage')
                    target, key = active['task_stages'], (w, s)
                elif kind == 'YOLO32_STAGE':
                    target, key = active['stages'], number(r, 'stage')
                    if not 0 <= key < 165:
                        raise ValueError('invalid stage')
                else:
                    w = number(r, 'worker')
                    if w not in range(3):
                        raise ValueError('invalid worker')
                    if kind == 'YOLO32_DETECTION':
                        target, key = active['detections'].setdefault(w, {}), number(r, 'index')
                    else:
                        name = {'YOLO32_WORKER': 'workers', 'YOLO32_COMPARE': 'comparisons', 'YOLO32_PROFILE': 'profiles'}[kind]
                        target, key = active[name], w
                if key in target:
                    raise ValueError('duplicate record')
                target[key] = r
            elif active is not None and line.startswith(('YOLO32_TIMING ', 'YOLO32_PARALLEL ', 'YOLO32_GROUP_PROFILE ', 'YOLO32_INDEPENDENT ', 'YOLO32_POLICY ', 'YOLO32_TAIL_WAIT ')):
                key = {'YOLO32_TIMING': 'timing', 'YOLO32_PARALLEL': 'parallel', 'YOLO32_GROUP_PROFILE': 'group', 'YOLO32_INDEPENDENT': 'independent', 'YOLO32_POLICY': 'policy', 'YOLO32_TAIL_WAIT': 'tail'}[line.split()[0]]
                if key in active:
                    raise ValueError('duplicate record')
                active[key] = fields(line)
            elif active is not None and line.startswith('YOLO32_PARALLEL_RESULT '):
                if 'parallel_result' in active:
                    raise ValueError('duplicate parallel result')
                active['parallel_result'] = line
            elif active is not None and line.startswith('YOLO32_INDEPENDENT_RESULT '):
                if 'independent_result' in active: raise ValueError('duplicate independent result')
                active['independent_result'] = line
        except (KeyError, ValueError) as e:
            fail(f'malformed log line: {line}: {e}')
    if active is not None:
        fail('truncated run at end of log')
    if bench is not None:
        fail('truncated automatic benchmark')
    if not runs:
        fail('no complete independent-image run')
    return errors, runs


def report(runs):
    def config(r):
        return (r.get('context','full'),r.get('scheduling','fixed'),r.get('submit_burst'),r.get('quantum_us'),r.get('hot_paths',0),r.get('layer_build',0),r.get('fixed_plans',0),r.get('fixed_packets',0),r.get('idle_priority',0),r.get('tail_wait',0),r.get('prepared_packets',0),r.get('ppu_early',0),r.get('head_clean',0),r.get('head_admit',0),r.get('wait_reuse',0),r.get('credit_limit',0),r.get('supply_build',0),r.get('memory_ops',0),r.get('resize_batch',0),r.get('resize_rows',0),r.get('credit_query',0),r.get('packet_dispatch',0),r.get('split_diag',0),r.get('diagnostic_build',1),r.get('capacity_experiment',0),r.get('credit_cap',0),r.get('capacity_diag',0),r.get('supply_revision',0))
    configurations = sorted({config(r) for r in runs},key=str)
    if len(configurations) > 1:
        # Full/light logs may be concatenated for an A/B comparison. Never
        # merge their timing samples into a single independent-mode median.
        for c in configurations:
            context, scheduling, burst, quantum, hot, layers, fixed_plans, fixed_packets, idle_priority, tail_wait, prepared_packets, ppu_early, head_clean, head_admit, wait_reuse, credit_limit, supply_build, memory_ops, resize_batch, resize_rows, credit_query, packet_dispatch, split_diag, diagnostic_build, capacity_experiment, credit_cap, capacity_diag, supply_revision = c
            print(f'\nTask context: {context}; scheduling: {scheduling}; submit_burst={burst}; quantum_cycles={quantum*CLOCK//1_000_000 if quantum is not None else None}; hot_paths={hot}; rocc_layer_build={layers}; fixed_plans={fixed_plans}; fixed_packets={fixed_packets}; idle_priority={idle_priority}; tail_wait={tail_wait}; prepared_packets={prepared_packets}; ppu_early={ppu_early}; head_clean={head_clean}; head_admit={head_admit}; wait_reuse={wait_reuse}; credit_limit={credit_limit}; supply_diag_build={supply_build}')
            print(f'memory_ops={memory_ops}; resize_batch={resize_batch}; resize_rows={resize_rows}; credit_query={credit_query}; packet_dispatch={packet_dispatch}; split_diag={split_diag}; diagnostic_build={diagnostic_build}; capacity_experiment={capacity_experiment}; credit_cap={credit_cap}; capacity_diag={capacity_diag}; supply_revision={supply_revision}')
            report([r for r in runs if config(r) == c])
        return
    # Manual t/u commands can precede an automatic benchmark in the same boot.
    # Match the firmware's formal summaries; use manual runs only as a fallback.
    measured = {}
    for m in ALL_MODES:
        formal = [r for r in runs if r['mode'] == m and r['phase'] == 'measure']
        measured[m] = formal or [r for r in runs if r['mode'] == m and r['phase'] == 'manual']
    baseline = measured['forward'] or [r for r in runs if r['phase'] == 'baseline']
    rb = median(r['batch'] for r in baseline)
    rg = median(r['graph'] for r in baseline)
    print('mode       samples  graph_cycles  batch_cycles  graph_speedup  batch_speedup  images/s')
    for m, rs in measured.items():
        if not rs:
            continue
        b, g = median(r['batch'] for r in rs), median(r['graph'] for r in rs)
        print(f'{m:10} {len(rs):7} {g:13.0f} {b:13.0f} {rg/g:14.3f} {rb/b:14.3f} {3*CLOCK/b:9.3f}')
    from software_batch_log import report as report_batch
    report_batch(runs)
    from capacity_log import report as report_capacity
    report_capacity(runs)
    serial_layers = None
    for r in runs:
        if not r['analysis']:
            continue
        if r.get('rocc_layers'):
            from rocc_layers import report_run
            report_run(r,serial_layers if r['mode']=='independent' else None)
            if r['mode']=='forward': serial_layers=r
        if r['diagnostics']:
            by_funct={}
            for (w,f),p in r['rocc'].items():
                v=by_funct.setdefault(f,[0,0,0])
                v[0]+=number(p,'count');v[1]+=number(p,'cycles');v[2]=max(v[2],number(p,'max_cycles'))
            names={0:'config',7:'startup flush',8:'LoopWS execute',15:'LoopConv execute',26:'SiLU LUT'}
            total=sum(v[1] for v in by_funct.values())
            print(f"\nRun {r['id']} ({r['mode']}) operand-ready RoCC dispatch: {total} cycles (three-worker CPU sum)")
            for f,(n,c,m) in sorted(by_funct.items(),key=lambda x:x[1][1],reverse=True)[:5]:
                print(f"  funct={f:2} {names.get(f,'command/config'):18} count={n} total={c} cycles mean={c/n:.1f} cycles max={m} cycles")
            if r['mode']=='independent':
                p=r['scheduler']
                wall=sum(number(s,'wall_cycles') for s in r['task_cpu'].values())
                native=sum(number(s,'cycles') for (w,f),s in r['rocc'].items() if f!=7)
                switch=number(p,'switch_cycles'); sched=number(p,'scheduler_cycles')
                parts={'native command dispatch':native,'context switch':switch,
                       'other task CPU':wall-switch-native,'scheduler':sched,
                       'outside scheduler steps':r['graph']-number(p,'step_cycles')}
                print('  Exclusive graph wall partition (profiling run):')
                for label,c in parts.items():
                    print(f'    {label:25} {c:12} cycles {100*c/r["graph"]:6.2f}%')
                print(f"  Completion polling inside scheduler={number(p,'ready_cycles')} cycles checks={number(p,'ready_checks')} blocked={number(p,'ready_blocked')} idle steps={number(p,'idle_steps')}; switches={number(p,'switch_count')}")
                if r['hot_paths']:
                    print(f"  Scheduler frames={number(p,'scheduler_steps')}; idle polling={number(p,'idle_scheduler_cycles')} cycles; active scheduling={number(p,'active_scheduler_cycles')} cycles")
        if r['mode'] == 'independent':
            s = r['independent']
            if 'policy' in r:
                p = r['policy']
                print(f"  Conditional scheduling: burst={number(p,'submit_burst')} CPU budget={number(p,'quantum_us')*CLOCK//1_000_000} cycles; "
                      f"command handoffs={number(p,'command_yields')} kept={number(p,'command_kept')}; "
                      f"stage handoffs={number(p,'stage_yields')} kept={number(p,'stage_kept')}; "
                      f"dependency handoffs={number(p,'wait_yields')}")
                if 'tail' in r:
                    t = r['tail']
                    print(f"  Tail packet handoffs merged into local waits: {number(t,'merges')} "
                          f"(conv={number(t,'conv')}, WS={number(t,'ws')}); idle_priority={r['idle_priority']}")
                if 'pressure_yields' in p:
                    print(f"  Scheduling={r['scheduling']}: pressure handoffs={number(p,'pressure_yields')}; "
                          f"slow dispatches={number(p,'slow_dispatches')}; burst reductions/recoveries="
                          f"{number(p,'burst_reductions')}/{number(p,'burst_recoveries')}; "
                          f"cached positive completions={number(p,'cached_ready_hits')}")
                print('  Handoff reasons: ' + ' '.join(f'{k}={number(p,k)}' for k in
                      ('bootstrap_yields','idle_yields','packet_yields','time_yields')) +
                      f"; no eligible peer={number(p,'no_peer')}; max packets/quantum={number(p,'max_quantum_packets')}")
            print(f"\nAnalysis run {r['id']} (independent): ahead submissions={number(s, 'ahead_submissions')}; no layer barrier")
            for w in range(3):
                cpu = sum(number(p, 'cpu_cycles') for (worker, _), p in r['task_stages'].items() if worker == w)
                print(f"  worker={w}: task CPU={cpu} cycles own wait={number(s, f'wait_cycles{w}')} cycles resumes={number(s, f'resumes{w}')}")
            print('  Worker stage spans and local waits overlap; do not sum them into batch time.')
            for w, p in sorted(r['profiles'].items()):
                print(f"  worker={w} event cycles: " + ' '.join(f'{k}={number(p, k)}' for k in ('gem_busy', 'exec', 'load_stall', 'store_stall')))
            continue
        print(f"\nAnalysis run {r['id']} ({r['mode']}): top 5 graph stages (three-image aggregate wall time)")
        for s, p in sorted(r['stages'].items(), key=lambda x: number(x[1], 'cycles'), reverse=True)[:5]:
            print(f"  stage={s:3} {p['kind']:12} {number(p, 'cycles'):12} cycles {p['label']}")
        totals = {}
        for p in r['stages'].values():
            totals[p['kind']] = totals.get(p['kind'], 0) + number(p, 'cycles')
        print('  stage totals (cycles): ' + ' '.join(f'{k}={v}'
              for k, v in sorted(totals.items(), key=lambda x: x[1], reverse=True)))
        for w, p in sorted(r['profiles'].items()):
            print(f"  worker={w} image={p['image']} event cycles: " + ' '.join(f'{k}={number(p, k)}' for k in ('gem_busy', 'exec', 'load_stall', 'store_stall', 'rvv', 'fence')))
        if 'group' in r:
            p = r['group']
            print(f"  grouped submit={number(p, 'submit_cycles')} cycles drain={number(p, 'wait_cycles')} cycles")
    print('\nBusy overlap is supporting evidence, not speedup or MAC utilization. Stall/event intervals can overlap; do not add them.')
    from wait_reuse_log import report as report_wait_reuse
    report_wait_reuse(runs)
    from credit_log import report as report_credit
    report_credit(runs)
    from submit_log import report as report_submit
    report_submit(runs)
    from supply_diag_log import report as report_supply
    report_supply(runs)
    from memory_log import report as report_memory
    report_memory(runs)
    if any(r.get('hardware') for r in runs):
        print('Hardware PPU completes Class/DFL/Decode/NMS. CPU reads and checks completed records only.')
        if any(r.get('ppu_early') for r in runs):
            from ppu_early_log import report as report_ppu_early
            report_ppu_early(runs)
            from ppu_head_log import report as report_ppu_heads
            report_ppu_heads(runs)
        else:
            print('Independent mode defers hardware PPU until all graphs finish; other modes overlap PPU with the graph. Compare graph and whole-batch timing separately.')
        for m, rs in measured.items():
            if rs:
                print(f"{m}: median PPU tail={median(r['post'] for r in rs):.0f} cycles core total={median(r['ppu_core'] for r in rs):.0f} cycles")
    else:
        print('CPU post time includes Class/DFL/Decode/NMS and model checksum work. No PPU is used.')


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('log', type=Path)
    p.add_argument('--latest',action='store_true',help='analyze only the last firmware boot session')
    args = p.parse_args()
    text=args.log.read_text(errors='replace')
    errors, runs = parse(latest_session(text) if args.latest else text)
    for e in errors:
        print('FAIL: ' + e)
    if not errors:
        report(runs)
    print('YOLO32_BENCH_LOG_CHECK=' + ('FAIL' if errors else 'PASS'))
    return bool(errors)


if __name__ == '__main__':
    raise SystemExit(main())
