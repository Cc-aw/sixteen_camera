#!/usr/bin/env python3
"""Independent deletion model must detect altered consumer-visible values."""
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'analysis'))
from validate_elision import ElisionReplay
from test_full_lifecycle import Fixture


class ElisionTests(unittest.TestCase):
    def replay(self, fixture, expected=32):
        model = ElisionReplay({2: dict(get_bytes=expected, spad_bytes=1)})
        for row in fixture.rows:
            model.consume(row)
        return model.finish()

    def test_whole_duplicate_elision_preserves_real_read(self):
        f = Fixture(); f.load(); f.load(tag=1); f.emit('Q', 0, 0); f.emit('V', 0, f.word())
        result = self.replay(f)
        self.assertEqual(result['elided_actual_get_bytes'], 32)
        self.assertEqual(result['unchanged_spad_read_responses'], 1)
        self.assertEqual(result['retained_original_completion_tokens'], 2)

    def test_wrong_same_source_claim_changes_real_read(self):
        f = Fixture(); f.load(); f.load(tag=1, byte=43); f.emit('Q', 0, 0); f.emit('V', 0, f.word(43))
        with self.assertRaises(ValueError):
            self.replay(f)

    def test_relocatable_load_cannot_be_deleted(self):
        f = Fixture(); f.load(); f.load(tag=1, dest=1); f.emit('Q', 0, 1); f.emit('V', 0, f.word())
        with self.assertRaises(ValueError):
            self.replay(f)

    def test_wrong_traffic_claim_is_rejected(self):
        f = Fixture(); f.load(); f.load(tag=1)
        with self.assertRaises(ValueError):
            self.replay(f, expected=64)


if __name__ == '__main__':
    unittest.main(verbosity=2)
