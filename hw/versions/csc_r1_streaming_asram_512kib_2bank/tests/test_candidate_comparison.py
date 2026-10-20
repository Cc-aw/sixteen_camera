#!/usr/bin/env python3
"""Negative controls for the independent C1a numerical comparator."""
import gzip
import importlib.util
from pathlib import Path
import tempfile
import unittest

PATH = Path(__file__).resolve().parents[1] / 'analysis/compare_candidate.py'
spec = importlib.util.spec_from_file_location('compare_candidate', PATH)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class CandidateComparisonTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)

    def tearDown(self):
        self.temp.cleanup()

    def trace(self, name, data=7, read=None, stores=None, zero_tail=True):
        path = self.root / name
        value = data if read is None else read
        word = f'{data:064x}'
        events = [f'W,1,0,0,0,0,0,3,1,0,0,{word}',
                  'Q,2,0,0,0,1,0,3', f'V,3,0,0,0,2,0,{value:064x}']
        if stores is not None:
            events.append(f'T,4,0,0,0,3,0,0,5,536870912,1,{stores:064x}')
        with gzip.open(path, 'wt') as f:
            f.write('\n'.join(events)+'\n')
        return path

    def test_identical(self):
        a, b = self.trace('a.gz', stores=9), self.trace('b.gz', stores=9)
        result = module.compare(a, b, self.root / 'compare')
        self.assertEqual(result['status'], 'PASS')
        self.assertEqual(result['baseline']['reads'], 1)

    def test_changed_consumer_byte(self):
        with self.assertRaises(ValueError):
            module.compare(self.trace('a.gz'), self.trace('b.gz', data=8), self.root / 'compare')

    def test_forged_read_response(self):
        with self.assertRaisesRegex(ValueError, 'response mismatch'):
            module.normalize(self.trace('a.gz', read=8), self.root / 'normalized')

    def test_changed_store_byte(self):
        with self.assertRaises(ValueError):
            module.compare(self.trace('a.gz', stores=1), self.trace('b.gz', stores=2), self.root / 'compare')

    def test_masked_store_bytes_ignored(self):
        module.compare(self.trace('a.gz', stores=1), self.trace('b.gz', stores=257), self.root / 'compare')

    def test_missing_replacement_completion(self):
        path = self.trace('a.gz')
        with gzip.open(path, 'at') as f:
            f.write('K,5,0,0,0,4,1,1,0,64,123\n')
        with self.assertRaisesRegex(ValueError, 'completion ledger'):
            module.normalize(path, self.root / 'normalized')


if __name__ == '__main__':
    unittest.main()
