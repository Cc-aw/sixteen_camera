#!/usr/bin/env python3
"""Negative tests for byte reconstruction and experiment adapters."""
from pathlib import Path
import sys
import tempfile
import unittest

FEATURE = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(FEATURE / 'analysis'))
from trace_lifecycle import ResidencyTrace
from analyze_residency import physical_traffic


class TestResidencyTrace(unittest.TestCase):
    def setUp(self):
        self.trace = ResidencyTrace(banks=1, rows=1)

    def event(self, name, *, mask=0, data=0, owner=1, aux=0, seq=None):
        t = self.trace
        t.consume(list(map(str, (t.next_seq if seq is None else seq, t.next_seq, name,
                                0, 2, 0, 0, 0, format(mask, 'x'), format(data, '064x'), owner, aux))))

    def start(self):
        self.event('BEGIN')
        self.event('SNAPSHOT', mask=0xffffffff)

    def test_masked_writes_and_observed_read(self):
        self.start()
        self.event('LOAD_ACCEPT', aux=1)
        self.event('BANK_ACCEPT', mask=1, data=255)
        self.event('BANK_COMMIT', mask=1, data=255)
        self.event('READ_INTENT', owner=100)
        self.event('READ_ACCEPT', owner=100)
        self.event('READ_DATA', data=255, owner=100)
        self.event('LOAD_CREDIT', aux=1)
        self.event('CMD_COMPLETE')
        self.event('BOUNDARY', aux=1)
        self.event('END')
        self.trace.finish()
        self.assertEqual(self.trace.memory[0, 0], bytes([255]) + bytes(31))

    def test_truncation_fails(self):
        self.start()
        with self.assertRaisesRegex(ValueError, 'Incomplete'):
            self.trace.finish()

    def test_sequence_gap_fails(self):
        with self.assertRaisesRegex(ValueError, 'Noncontiguous'):
            self.event('BEGIN', seq=1)

    def test_unaccepted_write_fails(self):
        self.start()
        with self.assertRaisesRegex(ValueError, 'ledger mismatch'):
            self.event('BANK_COMMIT', mask=1)

    def test_wrong_read_value_fails(self):
        self.start()
        self.event('READ_INTENT', owner=100)
        self.event('READ_ACCEPT', owner=100)
        with self.assertRaisesRegex(ValueError, 'physical SRAM'):
            self.event('READ_DATA', owner=100, data=1)

    def test_early_completion_fails(self):
        self.start()
        self.event('LOAD_ACCEPT', aux=32)
        with self.assertRaisesRegex(ValueError, 'Early'):
            self.event('CMD_COMPLETE')

    def test_id_reuse_fails(self):
        self.start()
        self.event('LOAD_ACCEPT', aux=1)
        with self.assertRaisesRegex(ValueError, 'Reused logical'):
            self.event('LOAD_ACCEPT', aux=1)

    def test_unknown_data_fails(self):
        with self.assertRaisesRegex(ValueError, 'Unknown'):
            self.trace.bytes_value('x')

    def test_masked_off_unknown_bytes_are_unobserved(self):
        self.assertEqual(self.trace.bytes_value('x' * 62 + 'ff', mask=1), bytes([255]) + bytes(31))

    def test_pending_read_cannot_cross_boundary(self):
        self.start()
        self.event('READ_INTENT', owner=100)
        with self.assertRaisesRegex(ValueError, 'Unfinished'):
            self.event('BOUNDARY')

    def test_counter_missing_commit_fails(self):
        self.start()
        with self.assertRaisesRegex(ValueError, 'counter/trace'):
            self.event('BOUNDARY', aux=1)

    def test_equal_at_commit_is_not_equal_at_issue(self):
        self.start()
        self.event('LOAD_ACCEPT', owner=1, aux=1)
        self.event('LOAD_ACCEPT', owner=2, aux=1)
        for owner in (1, 2):
            self.event('BANK_ACCEPT', owner=owner, mask=1, data=255)
            self.event('BANK_COMMIT', owner=owner, mask=1, data=255)
            self.event('LOAD_CREDIT', owner=owner, aux=1)
            self.event('CMD_COMPLETE', owner=owner)
        self.event('BOUNDARY', aux=2)
        self.event('END')
        self.trace.finish()
        self.assertEqual(self.trace.loads[2]['equal_bytes'], 1)
        self.assertFalse(self.trace.loads[2]['all_written_values_resident_at_issue'])

    def test_intervening_other_writer_invalidates_diagnostic(self):
        self.start()
        self.event('LOAD_ACCEPT', owner=1, aux=1)
        self.event('BANK_ACCEPT', owner=-1, mask=1, data=99, aux=1)
        self.event('BANK_COMMIT', owner=-1, mask=1, data=99, aux=1)
        self.event('BANK_ACCEPT', owner=1, mask=1, data=0)
        self.event('BANK_COMMIT', owner=1, mask=1, data=0)
        self.event('LOAD_CREDIT', owner=1, aux=1)
        self.event('CMD_COMPLETE', owner=1)
        self.event('BOUNDARY', aux=2)
        self.event('END')
        self.trace.finish()
        self.assertTrue(self.trace.loads[1]['all_written_values_resident_at_issue'])
        self.assertFalse(self.trace.loads[1]['stable_value_residency_diagnostic'])


class TestPhysicalTraffic(unittest.TestCase):
    def run_trace(self, payloads):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'lifecycle.csv'
            path.write_text(''.join(f'{i},{i},0,2,0,{payload}\n' for i, payload in enumerate(payloads)))
            return physical_traffic(path)

    def test_get_64_has_two_responses(self):
        counts = self.run_trace(['TL_A,4,1,6,80004000,ffffffff,0',
                                 'TL_D,1,1,6,0,0,0', 'TL_D,1,1,6,0,0,0'])
        self.assertEqual(counts[0]['tl_get_bytes'], 64)
        self.assertEqual(counts[0]['tl_gets'], 1)
        self.assertEqual(counts[0]['tl_d_beats'], 2)

    def test_truncated_multibeat_fails(self):
        with self.assertRaisesRegex(ValueError, 'Unreturned'):
            self.run_trace(['TL_A,4,1,6,80004000,ffffffff,0', 'TL_D,1,1,6,0,0,0'])

    def test_denied_fails(self):
        with self.assertRaisesRegex(ValueError, 'Denied'):
            self.run_trace(['TL_A,4,1,5,80004000,ffffffff,0', 'TL_D,1,1,5,1,0,0'])

    def test_source_reuse_fails(self):
        with self.assertRaisesRegex(ValueError, 'reused'):
            self.run_trace(['TL_A,4,1,5,80004000,ffffffff,0', 'TL_A,4,1,5,80004020,ffffffff,0'])

    def test_wrong_response_size_fails(self):
        with self.assertRaisesRegex(ValueError, 'size/opcode'):
            self.run_trace(['TL_A,4,1,5,80004000,ffffffff,0', 'TL_D,1,1,6,0,0,0'])

    def test_put_64_counts_one_transaction(self):
        counts = self.run_trace(['TL_A,0,1,6,80004000,ffffffff,0', 'TL_A,0,1,6,80004000,ffffffff,0',
                                 'TL_D,0,1,6,0,0,0'])
        self.assertEqual(counts[0]['tl_puts'], 1)

    def test_early_put_ack_fails(self):
        with self.assertRaisesRegex(ValueError, 'last A beat'):
            self.run_trace(['TL_A,0,1,6,80004000,ffffffff,0', 'TL_D,0,1,6,0,0,0'])


if __name__ == '__main__':
    unittest.main()
