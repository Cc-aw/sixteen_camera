#!/usr/bin/env python3
import random
import unittest
from reference import Load, apply_updates, original_updates, physical_reads, source_rows


class LoadReferenceTest(unittest.TestCase):
    def test_original_mapping_and_poison(self):
        c = Load(0x80000001, 2, 3, 3, 6, 3)
        rows = source_rows(c, lambda a: a & 255)
        initial = {i: bytes([0xa5] * 32) for i in range(5)}
        actual = apply_updates(c, rows, initial)
        self.assertEqual(actual[0][6:15], b''.join(rows))
        self.assertEqual(actual[4][:3], rows[-1])
        self.assertTrue(all(data[18:] == bytes([0xa5] * 14) for data in actual.values()))
        self.assertTrue(all(row >= 0 for row, _, _ in original_updates(c, rows)))

    def test_fragments_cover_logical_bytes_once(self):
        cases = 0
        for cols in (1, 2, 3, 4, 7, 8, 12, 15, 16, 24, 31):
            for rows in (1, 2, 3, 31, 32):
                for residue in range(64):
                    c = Load(0x80000fc0 + residue, 64, cols, rows, 1, cols)
                    covered = []
                    for start, size, valid, count in physical_reads(c, True):
                        self.assertEqual(start % size, 0)
                        self.assertEqual(start // 4096, (start + size - 1) // 4096)
                        self.assertLessEqual(start, valid)
                        self.assertLessEqual(valid + count, start + size)
                        covered.extend(range(valid, valid + count))
                    self.assertEqual(covered, list(range(c.address, c.address + cols * rows)))
                    self.assertLessEqual(len(list(physical_reads(c, True))),
                                         len(list(physical_reads(c, False))))
                    cases += 1
        self.assertEqual(cases, 3520)

    def test_independent_command_tails_and_zeros(self):
        rng = random.Random(281016)
        initial = {i: bytes(rng.randrange(256) for _ in range(32)) for i in range(80)}
        first = Load(0x80000000, 10, 3, 32, 6, 3)
        second = Load(0, 42, 3, 2, 6, 3, True)
        after = apply_updates(first, source_rows(first, lambda a: a & 255), initial)
        final = apply_updates(second, source_rows(second, lambda a: 0xff), after)
        self.assertEqual(final[42][:3], bytes(3))
        self.assertEqual(final[42][3:6], bytes(3))
        self.assertEqual(final[43][:3], bytes(3))
        self.assertEqual(final[43][3:], initial[43][3:])


if __name__ == '__main__':
    unittest.main(verbosity=2)
