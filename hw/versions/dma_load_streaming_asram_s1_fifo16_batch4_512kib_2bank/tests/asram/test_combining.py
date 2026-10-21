#!/usr/bin/env python3
"""Independent read/credit/boundary checks for the finite-window trace model."""
import importlib.util
from pathlib import Path
import unittest
import tempfile

spec = importlib.util.spec_from_file_location('combining', Path(__file__).resolve().parents[1] / 'scripts/analyze_combining.py')
combining = importlib.util.module_from_spec(spec)
spec.loader.exec_module(combining)


def events(read_between=False):
    result=[]
    poison=bytes([0xa5]*32)
    def event(kind, cycle, cmd=0, mask=0, data=bytes(32), aux=0):
        result.append(dict(seq=len(result),cycle=cycle,event=kind,epoch=0,mode=2,stage=0,
                           bank=0,row=0,cmd=cmd,mask=mask,data=data,aux=aux))
    event('BEGIN',0);event('SNAPSHOT',0,mask=0xffffffff,data=poison)
    for cmd,cycle,mask,data in ((1,1,1,bytes([7])+bytes(31)),(2,4,2,bytes([0,8])+bytes(30))):
        event('LOAD_ACCEPT',cycle,cmd=cmd,aux=1)
        event('BANK_ACCEPT',cycle,cmd=cmd,mask=mask,data=data)
        event('BANK_COMMIT',cycle+1,cmd=cmd,mask=mask,data=data)
        event('LOAD_CREDIT',cycle+1,cmd=cmd,aux=1);event('CMD_COMPLETE',cycle+1,cmd=cmd)
        if read_between and cmd==1:
            event('READ_INTENT',3,cmd=100)
    if not read_between:event('READ_INTENT',7,cmd=100)
    event('READ_ACCEPT',8,cmd=100)
    event('READ_DATA',9,cmd=100,mask=0xffffffff,data=bytes([7,8])+poison[2:])
    event('BOUNDARY',10,aux=2);event('END',10)
    return result


class CombiningTest(unittest.TestCase):
    def test_cross_command_masks_and_all_observations(self):
        result=combining.analyze(events(),2,32,False)
        self.assertEqual(result['saved_writes'],1)
        self.assertEqual(result['cross_cmd_saved_writes'],1)
        self.assertEqual(result['read_observations'],1)

    def test_read_intent_freezes_merging(self):
        self.assertEqual(combining.analyze(events(True),2,32,False)['saved_writes'],0)

    def test_zero_age_is_exact_baseline(self):
        self.assertEqual(combining.analyze(events(),1,0,False)['saved_writes'],0)

    def test_bad_read_data_rejected(self):
        rows=events();rows[-3]['data']=bytes(32)
        with self.assertRaisesRegex(ValueError,'Actual SRAM read'):
            combining.analyze(rows,2,32,False)

    def test_missing_physical_commit_rejected(self):
        rows=[r for r in events() if not (r['event']=='BANK_COMMIT' and r['cmd']==2)]
        with self.assertRaisesRegex(ValueError,'read observation|drain'):
            combining.analyze(rows,2,32,False)

    def test_counter_closure_rejected(self):
        rows=events();rows[-2]['aux']=3
        with self.assertRaisesRegex(ValueError,'c22'):
            combining.analyze(rows,2,32,False)

    def test_truncated_trace_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            path=Path(directory)/'trace.csv'
            path.write_text('0,0,BEGIN,0,2,0,0,0,0,0,0,0\n')
            with self.assertRaisesRegex(ValueError,'BEGIN/END'):
                combining.load_trace(path)

    def test_missing_event_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            path=Path(directory)/'trace.csv'
            path.write_text('0,0,BEGIN,0,2,0,0,0,0,0,0,0\n2,0,END,0,2,0,0,0,0,0,0,0\n')
            with self.assertRaisesRegex(ValueError,'Missing/duplicate'):
                combining.load_trace(path)


if __name__ == '__main__':
    unittest.main()
