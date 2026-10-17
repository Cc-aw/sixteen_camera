#!/usr/bin/env python3
"""Offline contracts only: fake MMIO, corrupt/truncated logs and local isolation."""
import copy
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))
sys.path.insert(0, str(ROOT / 'tests/reference'))
from analyze import parse, compare
from package import check, local, sources
from test_log import fixture


class Package(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.manifest = check()
        cls.exe = ROOT / 'build/smoke_fake_io'
        subprocess.run([os.environ.get('HOST_CC', 'cc'), '-std=gnu11', '-O2', '-Wall', '-Wextra', '-Werror',
                        '-I' + str(ROOT / 'include'), str(ROOT / 'tests/smoke_fake_io.c'), '-o', str(cls.exe)], check=True)
        cls.smoke = subprocess.check_output([str(cls.exe)], text=True)
        cls.manifest = check()
        cls.diag = (ROOT / 'build/test_boundary/boundary_synthetic_case11.log').read_text()

    def header(self, kind):
        return f"L2BTEST,BUILD,schema=1,test={kind},build_id={self.manifest['build_id']},source={self.manifest['source_revision']}\n"

    def test_actual_cpu_smoke_complete(self):
        result = parse(self.header('smoke') + self.smoke, self.manifest)
        self.assertTrue(result['valid'])
        self.assertEqual(len(result['result']['blocks']), 4)

    def test_actual_smoke_rejects_mmio_and_data_faults(self):
        expected = ['hardware_geometry', 'statistics_timeout', 'bank_not_exercised',
                    'snapshot_sequence', 'memory_data', 'selector_readback', 'mshr_peak_out_of_range']
        for fault, reason in enumerate(expected, 1):
            with self.subTest(fault=fault):
                result = subprocess.run([str(self.exe), str(fault)], text=True, capture_output=True, timeout=10)
                self.assertEqual(result.returncode, 1, result.stderr)
                self.assertIn('HOST_REJECTED=' + reason, result.stderr)
                with self.assertRaises(ValueError):
                    parse(self.header('smoke') + result.stdout, self.manifest)

    def test_smoke_missing_duplicate_and_out_of_order_counters(self):
        lines = (self.header('smoke') + self.smoke).splitlines()
        at = next(i for i, line in enumerate(lines) if line.startswith('L2BTEST,BLOCK,window=0,id=14,'))
        for mutation in [lines[:at] + lines[at + 1:], lines[:at] + [lines[at]] + lines[at:],
                         lines[:at] + [lines[at].replace('id=14,', 'id=15,')] + lines[at + 1:], lines[:-1]]:
            with self.assertRaises(ValueError):
                parse('\n'.join(mutation), self.manifest)

    def test_wrong_boot_identity_and_mixed_logs(self):
        good = self.header('smoke') + self.smoke
        for text in [good.replace(self.manifest['build_id'], 'wrong'), good + good,
                     good + 'L2BTEST,FAIL,reason=late_fault,value=1\n', self.smoke]:
            with self.assertRaises(ValueError):
                parse(text, self.manifest)

    def test_formal_workload_and_comparison_are_same_elf(self):
        result = parse(self.header('reference') + fixture(), self.manifest)
        before = copy.deepcopy(result); before['comparison_group'] = 'old_2bank'
        after = copy.deepcopy(result); after['comparison_group'] = 'new_4bank'
        with self.assertRaises(ValueError):
            compare([before, after])
        before['elf_identity'] = after['elf_identity'] = 'DOWNLOAD_RECEIPT_VERIFIED'
        report = compare([before, after])
        self.assertEqual(report['groups']['new_4bank']['median_cycles'], 500000)
        after['elf_sha256'] = 'other'
        with self.assertRaises(ValueError):
            compare([before, after])

    def test_diagnostic_four_bank_complete_and_partial_pass(self):
        result = parse(self.header('diagnostic') + self.diag, self.manifest)
        self.assertTrue(result['valid'])
        cut = self.diag.index('ATSOFT1,PASS,')
        early_pass = self.diag[:cut] + self.diag[cut:].splitlines()[0] + '\n'
        with self.assertRaises(ValueError):
            parse(self.header('diagnostic') + early_pass, self.manifest)
        with self.assertRaises(ValueError):
            parse(self.header('diagnostic') + self.diag.replace('blocks=16', 'blocks=14', 1), self.manifest)

    def test_local_inputs_and_path_escape(self):
        self.assertGreater(len(sources()), 70)
        for path in ['../frontend/src/main.c', '/etc/passwd']:
            with self.assertRaises(ValueError):
                local(path)
        self.assertFalse(any(p.is_symlink() for p in ROOT.rglob('*')))

    def test_unrelated_parent_file_does_not_invalidate(self):
        before = sources()
        with tempfile.NamedTemporaryFile(dir=ROOT.parent, prefix='unrelated_feature_'):
            self.assertEqual(sources(), before)
            check()


if __name__ == '__main__':
    unittest.main(verbosity=2)
