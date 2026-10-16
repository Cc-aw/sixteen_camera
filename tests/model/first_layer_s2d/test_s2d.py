#!/usr/bin/env python3
"""Packing ISA, real-input integer equivalence, native plans and log contract."""
import copy
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import sys
import unittest

import numpy as np

PROJECT = Path(__file__).resolve().parents[3]
ROOT = PROJECT / 'sw/benchmarks/frontend'
OUT = Path(os.environ.get('FRONTEND_BUILD', PROJECT / 'build/firmware/first-layer-s2d'))
sys.path.insert(0, str(ROOT / 'scripts'))
from first_layer_s2d_prepare import array, fold_weights
from analyze_first_layer_s2d import parse, COUNTERS, PROFILES, EXECUTORS


def fixture():
    records = [('BUILD', dict(schema=1, rounds=4, profiles=3, executors=2, frames_per_batch=3,
                clock_hz=100000000, scope='first_conv', evict_bytes=4194304,
                prepacked_excludes_pack=1, online_includes_pack=1))]
    totals = {}
    for pindex, profile in enumerate(PROFILES):
        for eindex, executor in enumerate(EXECUTORS):
            n = 12000 // (pindex + 1) // (eindex + 1)
            totals[profile, executor] = n * 4
            for warmup, rounds in ((1, (0,)), (0, range(4))):
                for round_id in rounds:
                    records.append(('RESULT', dict(profile=profile, executor=executor, warmup=warmup,
                        round=round_id, batch_cycles=n, pack_cycles=100 if pindex == 2 else 0,
                        frames=3, compared_bytes=3686400, bit_exact=1, **{c: 1 for c in COUNTERS})))
    for p in PROFILES:
        serial, parallel = totals[p, 'serial'], totals[p, 'parallel']
        records.append(('SUMMARY', dict(profile=p, serial_cycles=serial, parallel_cycles=parallel,
            parallel_speedup_x1000=serial * 1000 // parallel,
            parallel_efficiency_x1000=serial * 1000 // (3 * parallel),
            serial_gain_x1000=totals['reference', 'serial'] * 1000 // serial,
            parallel_gain_x1000=totals['reference', 'parallel'] * 1000 // parallel,
            frames_per_executor=12)))
    records.append(('PASS', dict(measured_records=24, warmup_records=6, compared_bytes_per_record=3686400,
                               full_output_bit_exact=1, scope='first_conv')))
    return records


def encode(records):
    return '\n'.join('S2D1,' + kind + ',' + ','.join(f'{k}={v}' for k, v in values.items())
                     for kind, values in records) + '\n'


class FirstLayerTest(unittest.TestCase):
    def test_pack_host_and_rvv_isa(self):
        test_dir = OUT / 'tests'
        test_dir.mkdir(exist_ok=True)
        source = Path(__file__).with_name('test_pack.c')
        flags = ['-O2', '-std=gnu11', '-Wall', '-Wextra', '-Werror', '-fno-tree-vectorize',
                 '-fno-builtin', '-ffreestanding', '-I' + str(ROOT / 'include')]
        host = test_dir / 'pack_host'
        subprocess.run(shlex.split(os.environ.get('HOST_CC', 'cc')) + flags + [str(source), '-o', str(host)], check=True)
        subprocess.run([str(host)], check=True)
        qemu = shutil.which('qemu-riscv64')
        self.assertIsNotNone(qemu, 'qemu-riscv64 required to execute the actual RVV packing instructions')
        start = test_dir / 'start.S'
        start.write_text('''.section .text.init,"ax",@progbits
.global _start
_start:
    call main
    li a7,93
    ecall
1:  j 1b
''')
        elf = test_dir / 'pack_rvv.elf'
        cross = os.environ.get('CROSS', 'riscv64-unknown-elf-')
        subprocess.run([cross + 'gcc', *flags, '-march=rv64gcv', '-mabi=lp64d', '-nostdlib',
                        '-nostartfiles', '-Wl,-e,_start', str(start), str(source), '-o', str(elf)], check=True)
        for vlen in (128, 256, 512):
            subprocess.run([qemu, '-cpu', f'rv64,v=true,vlen={vlen},elen=64,vext_spec=v1.0', str(elf)],
                           check=True, timeout=60)

    def test_real_model_full_integer_equivalence(self):
        snap = OUT / 'native'
        text = next(snap.glob('*profile_params.h')).read_text()
        weights = np.array(array(text, 'yolov5nu_conv0_weights'), dtype=np.int32).reshape(6, 6, 3, 16)
        bias = np.array(array(text, 'yolov5nu_conv0_bias'), dtype=np.int32)
        folded_weights = np.array(fold_weights(weights.reshape(-1).tolist()), dtype=np.int32).reshape(3, 3, 12, 16)
        body = (snap / 'inputs.c').read_text().split('= {', 1)[1].split('};', 1)[0]
        body = re.sub(r',+', ',', re.sub(r'[{}\s]+', '', body)).strip(',')
        inputs = np.fromstring(body, dtype=np.int32, sep=',').reshape(3, 480, 640, 3)
        # Conservative bound ensures no int32 overflow in any prefix/order.
        self.assertLess(108 * 128 * np.abs(weights).max() + np.abs(bias).max(), 2**31)
        for x in inputs:
            z = x.reshape(240, 2, 320, 2, 3).transpose(0, 2, 1, 3, 4).reshape(240, 320, 12)
            padded = np.pad(x, ((2, 2), (2, 2), (0, 0)))
            patches = np.lib.stride_tricks.sliding_window_view(padded, (6, 6), axis=(0, 1))[::2, ::2]
            original = patches.transpose(0, 1, 3, 4, 2).reshape(-1, 108) @ weights.reshape(108, 16) + bias
            padded = np.pad(z, ((1, 1), (1, 1), (0, 0)))
            patches = np.lib.stride_tricks.sliding_window_view(padded, (3, 3), axis=(0, 1))
            folded = patches.transpose(0, 1, 3, 4, 2).reshape(-1, 108) @ folded_weights.reshape(108, 16) + bias
            np.testing.assert_array_equal(original, folded)

    def test_native_math_and_null_reuse_retained(self):
        r = json.loads((OUT / 'generated/first_layer_s2d.json').read_text())
        for index in (0, 1, 3):
            self.assertEqual(r['baseline']['config'][index], r['candidate']['config'][index])
        # The EX configuration's input stride must change from 2 to 1;
        # activation, scaling and the other configuration bits stay fixed.
        for key, stride in (('baseline', 2), ('candidate', 1)):
            self.assertEqual(r[key]['config'][2] >> 16, stride)
        self.assertEqual(r['baseline']['config'][2] & 0xffff, r['candidate']['config'][2] & 0xffff)
        self.assertEqual(len(r['baseline']['tiles']), 80)
        self.assertEqual(len(r['candidate']['tiles']), 80)
        self.assertEqual(sum(p['offsets'][0] != 0xffffffff for p in r['baseline']['tiles']),
                         sum(p['offsets'][0] != 0xffffffff for p in r['candidate']['tiles']))
        self.assertEqual(r['candidate_shape']['scale_bits'], r['baseline_shape']['scale_bits'])
        self.assertEqual(r['candidate_shape']['act'], r['baseline_shape']['act'])

    def test_complete_log_speedups(self):
        report = parse(encode(fixture()))
        self.assertEqual(report['measured_records'], 24)
        self.assertEqual(report['aggregate'][0]['parallel_speedup'], 2)
        self.assertEqual(report['aggregate'][2]['serial_gain'], 3)

    def test_missing_duplicate_or_truncated_log_fails(self):
        original = fixture()
        for modified in (original[:-1], original[:2] + original[3:], original[:2] + original[1:]):
            with self.assertRaises(ValueError): parse(encode(modified))

    def test_failure_and_inconsistent_summary_fail(self):
        records = fixture()
        with self.assertRaises(ValueError): parse(encode(records[:-1]) + 'S2D1,FAIL,reason=output_mismatch\n' + encode(records[-1:]))
        wrong = copy.deepcopy(records)
        wrong[-2][1]['parallel_cycles'] += 1
        with self.assertRaises(ValueError): parse(encode(wrong))
        wrong = copy.deepcopy(records)
        wrong[1][1]['pack_cycles'] = 1
        with self.assertRaises(ValueError): parse(encode(wrong))

    def test_latest_session_never_fills_missing_records_from_old(self):
        records = fixture()
        text = encode(records)
        self.assertEqual(parse(text + text)['prior_sessions_ignored'], 1)
        with self.assertRaises(ValueError): parse(text + encode(records[:-1]))


if __name__ == '__main__':
    unittest.main(verbosity=2)
