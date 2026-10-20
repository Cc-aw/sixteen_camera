#!/usr/bin/env python3
"""Positive/negative tests for the full-workload physical lifecycle auditor."""
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'analysis'))
from full_lifecycle import FullLedger, footprint


class Fixture:
    def __init__(self, zero_owners=False):
        self.ledger = FullLedger(zero_owners=zero_owners)
        self.seq = 0
        self.frame = 0
        self.rows = []
        self.emit('B', 253, 0, 0)

    def emit(self, event, *values):
        row = [event, self.seq, 0, self.frame, 0, self.seq, *values]
        self.seq += 1
        self.rows.append(list(map(str, row)))
        self.ledger.consume(list(map(str, row)))

    @staticmethod
    def word(byte=42):
        return (bytes([byte]) + bytes(31))[::-1].hex()

    def begin(self, tag=0, source=0x80000000, dest=0, scale=0x3c00):
        self.emit('R', 1, 1, 0, 1, tag, source, dest, 0, 1, 0, scale, 0, 0, 1, 1, 1, tag)

    def finish(self, tag=0, dest=0, byte=42):
        self.emit('G', 0, tag)
        self.emit('T', 4, 32, 5, self.ledger.tags[tag].key[0] & ~31, 0xffffffff, self.word(0))
        self.emit('D', 32, 5, 1, 0, self.word(byte))
        bank, address = divmod(dest, 2048)
        self.emit('A', bank, address, 1, 0, tag, self.word(byte))
        self.emit('Y', tag, 1)
        self.emit('X', tag)
        self.emit('W', bank, address, 1, 0, tag, self.word(byte))

    def load(self, tag=0, source=0x80000000, dest=0, scale=0x3c00, byte=42):
        self.begin(tag, source, dest, scale)
        self.finish(tag, dest, byte)

    def ex_write(self, byte=42):
        self.emit('A', 0, 0, 1, 1, 0, self.word(byte))
        self.emit('W', 0, 0, 1, 1, 0, self.word(byte))

    def zero_load(self, tag=0):
        self.emit('R', 1, 1, 0, 1, tag, 0, 0, 0, 1, 0, 0x3c00, 0, 1, 1, 1, 1, tag)
        self.emit('A', 0, 0, 1, 2, tag, self.word(0))
        self.emit('Y', tag, 1); self.emit('X', tag)
        self.emit('W', 0, 0, 1, 2, tag, self.word(0))

    def hits(self):
        return self.ledger.stat(0, 0)['eligible_exact_mvin_commands']


class FullLifecycleTests(unittest.TestCase):
    def test_completed_whole_load_same_location_matches(self):
        f = Fixture(); f.load(); f.load(tag=1)
        self.assertEqual(f.hits(), 1)
        self.assertEqual(f.ledger.stat(0, 0)['eligible_exact_get_bytes'], 32)
        f.ledger.check_end()

    def test_same_source_other_destination_cannot_match(self):
        f = Fixture(); f.load(); f.load(tag=1, dest=1)
        self.assertEqual(f.hits(), 0)
        self.assertEqual(f.ledger.stat(0, 0)['same_source_diff_destination_commands'], 1)

    def test_same_values_other_source_cannot_match(self):
        f = Fixture(); f.load(); f.load(tag=1, source=0x80000020)
        self.assertEqual(f.hits(), 0)

    def test_scale_is_part_of_complete_descriptor(self):
        f = Fixture(); f.load(); f.load(tag=1, scale=0x4000)
        self.assertEqual(f.hits(), 0)

    def test_same_source_changed_producer_generation(self):
        f = Fixture(); f.load(); f.ledger.mutate(0x80000000, 1); f.load(tag=1)
        self.assertEqual(f.hits(), 0)

    def test_frame_switch_invalidates_residency(self):
        f = Fixture(); f.load(); f.frame = 1; f.emit('B', 253, 0, 0); f.load(tag=1)
        self.assertEqual(f.ledger.stat(1, 0)['eligible_exact_mvin_commands'], 0)

    def test_same_value_ex_write_still_invalidates(self):
        f = Fixture(); f.load(); f.ex_write(); f.load(tag=1)
        self.assertEqual(f.hits(), 0)

    def test_intervening_other_dma_invalidates(self):
        f = Fixture(); f.load(); f.load(tag=1, source=0x80000020); f.load()
        self.assertEqual(f.hits(), 0)

    def test_actual_new_processed_bytes_must_also_match(self):
        f = Fixture(); f.load(); f.load(tag=1, byte=43)
        self.assertEqual(f.hits(), 0)

    def test_credit_and_rob_do_not_prove_sram_commit(self):
        f = Fixture(); f.begin(); f.emit('A', 0, 0, 1, 0, 0, f.word())
        f.emit('Y', 0, 1); f.emit('X', 0)
        self.assertFalse(f.ledger.cache)
        f.emit('W', 0, 0, 1, 0, 0, f.word())
        self.assertEqual(len(f.ledger.cache), 1)

    def test_unfinished_prior_load_cannot_match(self):
        f = Fixture(); f.begin(); f.begin(tag=1)
        self.assertFalse(f.ledger.tags[1].candidate)

    def test_tag_can_recycle_while_old_physical_write_is_pending(self):
        f = Fixture(); f.begin(); f.emit('A', 0, 0, 1, 0, 0, f.word())
        old = f.ledger.tags[0]
        f.emit('Y', 0, 1); f.emit('X', 0); f.begin(tag=0, dest=1)
        self.assertFalse(f.ledger.tags[0].candidate)
        f.emit('W', 0, 0, 1, 0, 0, f.word())
        self.assertTrue(old.finished)

    def test_intervening_write_after_candidate_accept_invalidates(self):
        f = Fixture(); f.load(); f.begin(tag=1); f.ex_write(); f.finish(tag=1)
        self.assertEqual(f.hits(), 0)

    def test_wrong_physical_commit_fails(self):
        f = Fixture(); f.begin(); f.emit('A', 0, 0, 1, 0, 0, f.word())
        with self.assertRaises(ValueError):
            f.emit('W', 0, 1, 1, 0, 0, f.word())

    def test_commit_outside_whole_load_footprint_fails(self):
        f = Fixture(); f.begin(); f.emit('A', 0, 1, 1, 0, 0, f.word())
        with self.assertRaises(ValueError):
            f.emit('W', 0, 1, 1, 0, 0, f.word())

    def test_read_response_checks_committed_value(self):
        f = Fixture(); f.load(); f.emit('Q', 0, 0); f.emit('V', 0, f.word())
        f.ledger.check_end()

    def test_wrong_read_response_fails(self):
        f = Fixture(); f.load(); f.emit('Q', 0, 0)
        with self.assertRaises(ValueError):
            f.emit('V', 0, f.word(43))

    def test_oversized_credit_fails(self):
        f = Fixture(); f.begin()
        with self.assertRaises(ValueError):
            f.emit('Y', 0, 2)

    def test_early_retirement_fails(self):
        f = Fixture(); f.begin()
        with self.assertRaises(ValueError):
            f.emit('X', 0)

    def test_unfinished_dataset_fails(self):
        f = Fixture(); f.begin()
        with self.assertRaises(ValueError):
            f.ledger.check_end()

    def test_sequence_gap_fails(self):
        f = Fixture(); f.seq += 1
        with self.assertRaises(ValueError):
            f.emit('C', 26, 0, 0)

    def test_unknown_get_owner_fails(self):
        f = Fixture()
        with self.assertRaises(KeyError):
            f.emit('T', 4, 32, 5, 0x80000000, 0xffffffff, f.word())

    def test_pixel_repeats_clip_at_half_boundary(self):
        cells, _ = footprint(0x80000000, 8192, 3, 0, 1, 3, 1, 3)
        self.assertEqual(cells, set(range(8192 * 32, 8192 * 32 + 3)))

    def test_channel_block_stride_and_tail(self):
        cells, _ = footprint(0x80000000, 10, 35, 0, 20, 1, 2, 35)
        self.assertEqual(len(cells), 70)
        self.assertIn(30 * 32 + 2, cells)
        self.assertNotIn(30 * 32 + 3, cells)

    def test_zero_stride_source_repeats(self):
        cells, pages = footprint(0x80000000, 0, 4, 1, 1, 1, 1, 0)
        self.assertEqual(len(cells), 8)
        self.assertEqual(pages, (0x80000000 // 32,))

    def test_unrelated_source_write_does_not_invalidate(self):
        f = Fixture(); f.load(); f.ledger.mutate(0x90000000, 32); f.load(tag=1)
        self.assertEqual(f.hits(), 1)

    def test_neighbor_byte_source_update_does_not_invalidate(self):
        f = Fixture(); f.load(); f.ledger.mutate(0x80000001, 1); f.load(tag=1)
        self.assertEqual(f.hits(), 1)

    def test_complete_zero_load_qualifies_without_get_savings(self):
        f = Fixture(zero_owners=True); f.zero_load(); f.zero_load(tag=1)
        self.assertEqual(f.hits(), 1)
        self.assertEqual(f.ledger.stat(0, 0)['eligible_exact_zero_commands'], 1)
        self.assertEqual(f.ledger.stat(0, 0)['zero_mvin_commands'], 2)
        self.assertEqual(f.ledger.stat(0, 0)['eligible_exact_get_bytes'], 0)
        f.ledger.check_end()

    def test_equal_ex_zero_write_invalidates_zero_descriptor(self):
        f = Fixture(zero_owners=True); f.zero_load(); f.ex_write(0); f.zero_load(tag=1)
        self.assertEqual(f.hits(), 0)

    def test_zero_write_owner_must_match_zero_command(self):
        f = Fixture(zero_owners=True); f.begin()
        with self.assertRaises(ValueError):
            f.emit('A', 0, 0, 1, 2, 0, f.word(0))

    def test_overlapping_mask_changes_only_actual_source_bytes(self):
        f = Fixture(); f.load(); f.ledger.mutate(0x80000000, 32, 2); f.load(tag=1)
        self.assertEqual(f.hits(), 1)

    def test_stage_counter_cannot_exceed_elapsed_cycles(self):
        f = Fixture()
        with self.assertRaises(ValueError):
            f.emit('S', 1, 2, 0, 0, 0, 0, 0, 0)

    def test_second_put_beat_updates_its_actual_source_bytes(self):
        f = Fixture(); f.load(source=0x80000020)
        f.emit('T', 0, 0, 6, 0x80000000, 1, f.word())
        f.emit('T', 0, 0, 6, 0x80000000, 1, f.word())
        f.emit('D', 0, 6, 0, 0, f.word())
        f.load(tag=1, source=0x80000020)
        self.assertEqual(f.hits(), 0)

    def test_get_must_intersect_its_real_load_source(self):
        f = Fixture(); f.begin(); f.emit('G', 0, 0)
        with self.assertRaises(ValueError):
            f.emit('T', 4, 32, 5, 0x80001000, 0xffffffff, f.word())


if __name__ == '__main__':
    unittest.main(verbosity=2)
