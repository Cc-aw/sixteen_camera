#!/usr/bin/env python3
"""Protocol-negative controls, including legal credit before bank commit."""
import sys
from pathlib import Path
import unittest

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'analysis'))
from g1_transactions import Transactions


def event(kind,*fields):
    return [kind,'1','0','0','2','0',*map(str,fields)]


def load(tag=0,rob=0,source=0,zero=True):
    return event('R',1,1,0,1,tag,source,0,0,8,0,0x3c00,0,int(zero),1,1,8,rob)


class TransactionTest(unittest.TestCase):
    def test_balanced(self):
        x=Transactions();x.record(load());x.record(event('Y',0,8));x.record(event('X',0))
        self.assertEqual(x.finish()['mvin_retired'],1)

    def test_reader_source_prefix(self):
        x=Transactions();x.record(load(source=64,zero=False))
        x.record(event('G',0,0));x.record(event('T',4,32,3,64,255,'0'*64))
        x.record(event('D',32,3,1,0,'0'*64))
        x.record(event('Y',0,8));x.record(event('X',0))
        self.assertEqual(x.finish()['get_bytes'],8)

    def test_put_ack_after_all_request_beats(self):
        x=Transactions()
        x.record(event('T',0,0,6,64,0xffffffff,'0'*64))
        x.record(event('T',0,0,6,64,0xffffffff,'0'*64))
        x.record(event('D',0,6,0,0,'0'*64))
        self.assertEqual(x.finish()['put_beats'],2)

    def test_early_put_ack(self):
        x=Transactions();x.record(event('T',0,0,6,64,0xffffffff,'0'*64))
        with self.assertRaisesRegex(ValueError,'TL response'):x.record(event('D',0,6,0,0,'0'*64))

    def test_tag_reuse_before_bank_commit_is_legal(self):
        x=Transactions();x.record(load())
        payload=(0,0,255,2,0,'0'*64)
        x.record(event('A',*payload));x.record(event('Y',0,8));x.record(event('X',0))
        x.record(load());x.record(event('W',*payload));x.record(event('Y',0,8));x.record(event('X',0))
        self.assertEqual(x.finish()['dma_tag_reuse_before_last_bank_commit'],1)

    def test_early_tag_reuse(self):
        x=Transactions();x.record(load())
        with self.assertRaisesRegex(ValueError,'Early DMA tag'):x.record(load(0,1))

    def test_oversized_credit(self):
        x=Transactions();x.record(load())
        with self.assertRaisesRegex(ValueError,'credit'):x.record(event('Y',0,9))

    def test_early_rob(self):
        x=Transactions();x.record(load())
        with self.assertRaisesRegex(ValueError,'ROB retirement'):x.record(event('X',0))

    def test_pending_bank_is_not_complete(self):
        x=Transactions();x.record(load());x.record(event('A',0,0,255,2,0,'0'*64))
        x.record(event('Y',0,8));x.record(event('X',0))
        with self.assertRaisesRegex(ValueError,'Unfinished'):x.finish()

    def test_fake_replacement_completion(self):
        with self.assertRaisesRegex(ValueError,'Fabricated'):Transactions().record(event('N'))

    def test_original_native_null_is_not_new_reuse(self):
        with self.assertRaisesRegex(ValueError,'existing reuse'):
            Transactions().record(event('K',1,1,0,16,'0'*64))


if __name__=='__main__':unittest.main()
