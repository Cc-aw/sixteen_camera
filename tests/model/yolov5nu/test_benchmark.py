from paths import HERE, source_path
"""Independent-image log, benchmark completeness and input extraction checks."""
import hashlib
import io
import json
from contextlib import redirect_stdout
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

from analyze_log import parse, report, MODES, IMAGES
from check_log import validate
from generate_inputs import generate, extract, INPUT_BYTES


def run_fixture(run, mode='forward', phase='manual', round=0, corrupt=False):
    analysis = phase == 'analysis'
    batch = 120 if mode == 'parallel' else 300
    graph, post = batch - 30, 20
    lines = [f'YOLO32_BEGIN run={run} images=025,036,142 dim=32 workers=3 mode={mode} reference=serial phase={phase} round={round} profile={int(analysis)}',
             f'YOLO32_TIMING batch_cycles={batch} graph_cycles={graph} post_cycles={post}']
    if mode == 'parallel':
        lines += ['YOLO32_PARALLEL conv_groups=58 tile_groups=500 requests0=500 requests1=500 requests2=500 '
                  + ('overlap_samples=20 triple_overlap_samples=10 busy_mask_seen=7 busy_sampling=1' if analysis else
                     'overlap_samples=0 triple_overlap_samples=0 busy_mask_seen=0 busy_sampling=0'),
                  'YOLO32_PARALLEL_RESULT ' + ('PASS' if analysis else 'UNMEASURED')]
    for w in range(3):
        value = w + (10 if corrupt and w == 2 else 0)
        lines += [f'YOLO32_WORKER worker={w} image={IMAGES[w]} raw_fnv={value} mask_fnv={w} logits_sum={w} logits_fnv={w} scores_sum={w} scores_fnv={w} dfl_sum={w} dfl_fnv={w} candidates=10 detections=1 cycles=100',
                  f'YOLO32_DETECTION worker={w} index=0 class={w} score=0x3f000000 cx=0 cy=0 width=0 height=0',
                  f'YOLO32_COMPARE worker={w} image={IMAGES[w]} reference=serial mismatches=0 first=none index=0']
        if analysis:
            lines += [f'YOLO32_PROFILE worker={w} image={IMAGES[w]} gem_busy=1 exec=1 load_stall=1 store_stall=1 conv_call=1 fence=1 rvv=1']
    if analysis:
        lines += [f'YOLO32_STAGE stage={s} kind=conv label=stage{s} cycles=1' for s in range(165)]
        if mode == 'parallel':
            lines += ['YOLO32_GROUP_PROFILE submit_cycles=1 wait_cycles=1']
    lines += ['YOLO32_RESULT PASS workers=bit_exact reference=serial']
    return '\n'.join(lines)


def benchmark_fixture():
    lines = [run_fixture(1, phase='baseline'), 'YOLO32_BENCH_BEGIN rounds=5 warmups=1 clock_hz=100000000']
    run = 2
    for mode in MODES:
        lines += [run_fixture(run, mode, 'warmup')]; run += 1
    for r in range(1, 6):
        for mode in MODES:
            lines += [run_fixture(run, mode, 'measure', r)]; run += 1
    for mode in MODES:
        b = 120 if mode == 'parallel' else 300
        g = b - 30
        lines += [f'YOLO32_BENCH mode={mode} samples=5 median_batch_cycles={b} median_graph_cycles={g} speedup_batch_milli={300000//b} speedup_graph_milli={270000//g} fps_milli={300000000000//b}']
    for mode in MODES:
        lines += [run_fixture(run, mode, 'analysis')]; run += 1
    lines += ['YOLO32_BENCH_RESULT PASS']
    return '\n'.join(lines)


class BenchmarkLogTests(unittest.TestCase):
    def test_different_images_compare_to_their_own_serial_reference(self):
        log = run_fixture(1, phase='baseline') + '\n' + run_fixture(2, 'parallel')
        self.assertEqual(validate(log), [])
        self.assertTrue(validate(run_fixture(2, 'parallel')))
        self.assertTrue(validate(run_fixture(1, phase='baseline') + '\n' +
                                 run_fixture(2, 'parallel', corrupt=True)))

    def test_complete_benchmark_and_profile(self):
        errors, runs = parse(benchmark_fixture())
        self.assertEqual(errors, [])
        self.assertEqual(len(runs), 29)

    def test_report_excludes_manual_runs_from_formal_median(self):
        errors, runs = parse(benchmark_fixture())
        self.assertEqual(errors, [])
        for i, r in enumerate(r for r in runs if r['mode'] == 'forward' and r['phase'] == 'measure'):
            r['batch'] = (i + 1) * 100_000_000
            r['graph'] = r['batch'] - 30
        _, manual = parse(run_fixture(100, phase='baseline') + '\n' + run_fixture(101))
        manual[-1]['batch'] = 900_000_000
        manual[-1]['graph'] = 899_999_970
        output = io.StringIO()
        with redirect_stdout(output):
            report(manual + runs)
        row = next(l.split() for l in output.getvalue().splitlines() if l.startswith('forward '))
        self.assertEqual(row[1], '5')
        self.assertEqual(int(row[3]), 300_000_000)
        output = io.StringIO()
        with redirect_stdout(output):
            report(manual)
        row = next(l.split() for l in output.getvalue().splitlines() if l.startswith('forward '))
        self.assertEqual(row[1], '1')
        self.assertEqual(int(row[3]), 900_000_000)

    def test_full_and_light_context_samples_are_reported_separately(self):
        _, full = parse(run_fixture(1,phase='baseline')+'\n'+run_fixture(2))
        _, light = parse(run_fixture(3,phase='baseline')+'\n'+run_fixture(4))
        for r in light:
            r['context']='light'
            r['batch']=100_000_000
            r['graph']=99_999_970
        output=io.StringIO()
        with redirect_stdout(output):
            report(full+light)
        rows=[l.split() for l in output.getvalue().splitlines() if l.startswith('forward ')]
        self.assertEqual([r[1] for r in rows],['1','1'])
        self.assertEqual([int(r[3]) for r in rows],[300,100_000_000])
        self.assertIn('Task context: full',output.getvalue())
        self.assertIn('Task context: light',output.getvalue())

    def test_fixed_and_runtime_plans_are_not_merged(self):
        text = run_fixture(1,phase='baseline')+'\n'+run_fixture(2)
        errors, runtime = parse(text)
        self.assertEqual(errors,[])
        errors, fixed = parse(text.replace('profile=0','profile=0 fixed_plans=1'))
        self.assertEqual(errors,[])
        output = io.StringIO()
        with redirect_stdout(output): report(runtime+fixed)
        self.assertEqual(len([l for l in output.getvalue().splitlines() if l.startswith('forward ')]),2)
        self.assertIn('fixed_plans=0',output.getvalue())
        self.assertIn('fixed_plans=1',output.getvalue())
        self.assertTrue(parse(text.replace('profile=0','profile=0 fixed_plans=2'))[0])
        boot = 'YOLO32_SCHED_CONFIG submit_burst=1 quantum_us=200 fixed_plans=0\n'
        self.assertTrue(parse(boot+text.replace('profile=0','profile=0 fixed_plans=1'))[0])

    def test_packet_and_geometry_plan_samples_are_not_merged(self):
        text = (run_fixture(1,phase='baseline')+'\n'+run_fixture(2)).replace('profile=0','profile=0 fixed_plans=1')
        errors, plans = parse(text)
        self.assertEqual(errors,[])
        errors, packets = parse(text.replace('fixed_plans=1','fixed_plans=1 fixed_packets=1'))
        self.assertEqual(errors,[])
        output = io.StringIO()
        with redirect_stdout(output): report(plans+packets)
        self.assertEqual(len([l for l in output.getvalue().splitlines() if l.startswith('forward ')]),2)
        self.assertIn('fixed_packets=0',output.getvalue())
        self.assertIn('fixed_packets=1',output.getvalue())
        for fields in ('fixed_packets=2','fixed_packets=1 fixed_plans=0'):
            self.assertTrue(parse(text.replace('fixed_plans=1',fields))[0])
        boot = 'YOLO32_SCHED_CONFIG submit_burst=1 quantum_us=200 fixed_plans=1 fixed_packets=0\n'
        self.assertTrue(parse(boot+text.replace('fixed_plans=1','fixed_plans=1 fixed_packets=1'))[0])

    def test_scheduled_packet_options_are_validated_and_not_merged(self):
        text=(run_fixture(1,phase='baseline')+'\n'+run_fixture(2)).replace(
            'profile=0','profile=0 fixed_plans=1 fixed_packets=1')
        errors,old=parse(text)
        self.assertEqual(errors,[])
        groups=[old]
        for idle,tail in ((1,0),(0,1),(1,1)):
            options=f'idle_priority={idle} tail_wait={tail}'
            errors,runs=parse(text.replace('fixed_packets=1','fixed_packets=1 '+options))
            self.assertEqual(errors,[])
            groups.append(runs)
        output=io.StringIO()
        with redirect_stdout(output):report([r for group in groups for r in group])
        self.assertEqual(len([l for l in output.getvalue().splitlines() if l.startswith('forward ')]),4)
        self.assertIn('graph_cycles',output.getvalue())
        self.assertNotIn('graph_ms',output.getvalue())
        for options in ('idle_priority=2','tail_wait=2','tail_wait=1 fixed_packets=0'):
            self.assertTrue(parse(text.replace('fixed_packets=1','fixed_packets=1 '+options))[0])
        boot='YOLO32_SCHED_CONFIG submit_burst=1 quantum_us=200 fixed_plans=1 fixed_packets=1 idle_priority=0 tail_wait=0\n'
        self.assertTrue(parse(boot+text.replace('fixed_packets=1','fixed_packets=1 idle_priority=1'))[0])
        self.assertTrue(parse(boot+text.replace('fixed_packets=1','fixed_packets=1 tail_wait=1'))[0])
        # A subsequent v13 boot resets v14 options, including absent legacy fields.
        errors,runs=parse('YOLO32_FIRMWARE v14\n'+boot+text+'\nYOLO32_FIRMWARE v13\n'+text)
        self.assertEqual(errors,[])
        self.assertTrue(all(not r['idle_priority'] and not r['tail_wait'] for r in runs))

    def test_prepared_backend_is_validated_reset_and_reported_separately(self):
        text=(run_fixture(1,phase='baseline')+'\n'+run_fixture(2)).replace(
            'profile=0','profile=0 fixed_plans=1 fixed_packets=1')
        e,old=parse(text)
        self.assertEqual(e,[])
        new_text=text.replace('fixed_packets=1','fixed_packets=1 prepared_packets=1')
        e,new=parse(new_text)
        self.assertEqual(e,[])
        output=io.StringIO()
        with redirect_stdout(output):report(old+new)
        self.assertEqual(len([l for l in output.getvalue().splitlines() if l.startswith('forward ')]),2)
        self.assertIn('prepared_packets=0',output.getvalue())
        self.assertIn('prepared_packets=1',output.getvalue())
        for value in ('prepared_packets=2','prepared_packets=1 fixed_packets=0'):
            self.assertTrue(parse(text.replace('fixed_packets=1','fixed_packets=1 '+value))[0])
        boot='YOLO32_SCHED_CONFIG submit_burst=1 quantum_us=200 fixed_plans=1 fixed_packets=1 prepared_packets=1\n'
        self.assertTrue(parse(boot+text.replace('fixed_packets=1','fixed_packets=1 prepared_packets=0')+'\n')[0])
        e,runs=parse('YOLO32_FIRMWARE v15\n'+boot+new_text+'\nYOLO32_FIRMWARE v14\n'+text)
        self.assertEqual(e,[])
        self.assertEqual([r['prepared_packets'] for r in runs],[1,1,0,0])

    def test_missing_or_forged_measurements_fail(self):
        log = benchmark_fixture()
        for old, new in [('round=5', 'round=4'), ('median_batch_cycles=120', 'median_batch_cycles=121'),
                         ('phase=warmup', 'phase=manual'), ('BENCH_RESULT PASS', 'BENCH_RESULT FAIL'),
                         ('triple_overlap_samples=10', 'triple_overlap_samples=0'),
                         ('requests2=500', 'requests2=499'), ('mismatches=0', 'mismatches=1'),
                         ('stage=164 ', 'stage=163 '), ('image=142', 'image=036')]:
            with self.subTest(field=old):
                self.assertTrue(validate(log.replace(old, new)))
        self.assertTrue(validate(log.rsplit('\n', 1)[0]))

    def test_missing_truncated_or_duplicate_records_fail(self):
        log = run_fixture(1, phase='baseline') + '\n' + run_fixture(2, 'parallel', 'analysis')
        for marker in ('YOLO32_COMPARE worker=2', 'YOLO32_WORKER worker=1', 'YOLO32_TIMING ',
                       'YOLO32_DETECTION worker=0', 'YOLO32_PROFILE worker=2', 'YOLO32_STAGE stage=164'):
            self.assertTrue(validate('\n'.join(l for l in log.splitlines() if not l.startswith(marker))))
        record = 'YOLO32_TIMING batch_cycles=120 graph_cycles=90 post_cycles=20'
        self.assertTrue(validate(log.replace(record, record+'\n'+record)))
        self.assertTrue(validate(log.rsplit('\n', 1)[0]))


class InputTests(unittest.TestCase):
    def test_existing_inputs_are_distinct_and_generation_is_reproducible(self):
        with tempfile.TemporaryDirectory() as d:
            out = Path(d)
            generate(out)
            before = {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in out.iterdir()}
            manifest = json.loads((out/'inputs_manifest.json').read_text())
            self.assertEqual([m['image'] for m in manifest], list(IMAGES))
            self.assertEqual({m['bytes'] for m in manifest}, {INPUT_BYTES})
            self.assertEqual(len({m['sha256'] for m in manifest}), 3)
            self.assertNotIn('yolov5nu_conv', (out/'inputs.c').read_text())
            generate(out)
            self.assertEqual(before, {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in out.iterdir()})

    def test_invalid_input_is_rejected(self):
        with tempfile.TemporaryDirectory() as d, patch('generate_inputs.INPUT_BYTES', 3):
            p = Path(d)/'params.h'
            for body in ('0,1', '0,1,128', '0,1,foo', '0,1,-129'):
                p.write_text(f'static const elem_t yolov5nu_input[3] = {{{body}}};')
                with self.assertRaises(ValueError):
                    extract(p)
            p.write_text('static const elem_t yolov5nu_input[3] = {-128,0,127};')
            self.assertEqual(extract(p), bytes([128, 0, 127]))


if __name__ == '__main__':
    unittest.main()
