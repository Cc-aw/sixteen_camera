#!/usr/bin/env python3
"""Synthetic parser fixtures only; no hardware performance evidence."""
import importlib.util
from pathlib import Path
import unittest

ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('dma_log',ROOT/'scripts/analyze_dma_load.py')
log=importlib.util.module_from_spec(spec);spec.loader.exec_module(log)


def fixture(first):
    prefix='DMALF1' if first else 'DMAL1';identity=0x12345678
    def record(kind,**fields):return prefix+','+kind+','+','.join(f'{k}={v}' for k,v in fields.items())
    result=[record('BUILD',schema=1,rounds=4,clock_hz=100000000,l2_kib=512,l2_banks=2,
                   layout='original',build_id=identity,firmware_revision=2,ppu_runs='monotonic')]
    run_cursor=0
    totals={(m,e):0 for m in log.MODES for e in (0,1)}
    def window(mode,round_id,executor,warmup):
        nonlocal run_cursor
        elapsed=(100000 if executor==0 else 40000)//(log.MODES.index(mode)+1)
        if not warmup:totals[mode,executor]+=elapsed
        common=dict(mode=mode,round=round_id,warmup=warmup)
        if first:
            result.append(record('WINDOW',**common,parallel=executor))
            result.append('S2D1,RESULT,'+','.join(f'{k}={v}' for k,v in dict(profile='reference',
                executor='parallel' if executor else 'serial',round=round_id,warmup=warmup,
                batch_cycles=elapsed,pack_cycles=0,frames=3,compared_bytes=3686400,bit_exact=1).items()))
        else:
            result.append(record('BATCH_BEGIN',**common,executor=executor+1,run_before=run_cursor,frames=12))
            result.append(record('RESULT',**common,executor=executor+1,cycles=elapsed,frames=12,
                ppu_results_bit_exact=1,run_first=run_cursor+1,run_last=run_cursor+12))
            run_cursor+=12
        for lane in range(3):
            active=executor==1 or lane==0
            values={f'c{i}':0 for i in range(8,35)}
            if active:
                values.update(c8=32,c9=96,c33=128,c11=0 if mode=='legacy' else 1,
                              c21=37 if mode=='read_assembled' else 0)
            extra=dict(parallel=executor) if first else dict(executor=executor+1,build_id=identity)
            result.append(record('COUNTERS',**common,**extra,lane=lane,actual_mode=log.MODES.index(mode),**values))
    if not first:window('legacy',0,-1,1)
    for iteration in range(5):
        warmup=iteration==0;round_id=max(0,iteration-1)
        for mode in (log.MODES if not iteration%2 else log.MODES[::-1]):
            if not warmup:
                for executor in range(2):window(mode,round_id,executor,1)
            for executor in range(2):window(mode,round_id,executor,int(warmup))
    for mode in log.MODES:
        s,p=totals[mode,0],totals[mode,1]
        result.append(record('SUMMARY',mode=mode,serial_cycles=s,parallel_cycles=p,scaling_x1000=s*1000//p,
            serial_gain_x1000=totals['legacy',0]*1000//s,parallel_gain_x1000=totals['legacy',1]*1000//p))
    if not first:
        for mode in log.MODES:
            result.extend([record('PHASE_BEGIN',mode=mode,run_before=run_cursor),
                           record('PHASE_END',mode=mode,run_last=run_cursor+78)])
            run_cursor+=78
    result.append(record('PASS',build_id=identity,measured_records=24,warmup_records=30 if first else 31,
                         full_output_bit_exact=1,ppu_runs=run_cursor))
    return '\n'.join(result)+'\n'


class DmaLogTest(unittest.TestCase):
    def test_first_and_full_valid(self):
        for first in (False,True):
            parsed=log.parse(fixture(first),0x12345678)
            self.assertEqual(parsed['status'],'PASS');self.assertEqual(parsed['measured_records'],24)

    def test_last_session_is_complete(self):
        old=fixture(True)
        with self.assertRaises(ValueError):log.parse(old+old.rsplit('\n',2)[0])
        self.assertEqual(log.parse(old+old)['prior_sessions_ignored'],1)

    def test_missing_duplicate_and_failure(self):
        for first in (False,True):
            raw=fixture(first);rows=raw.splitlines()
            index=next(i for i,r in enumerate(rows) if ',COUNTERS,' in r)
            for broken in ('\n'.join(rows[:index]+rows[index+1:]),
                           '\n'.join(rows[:index]+[rows[index]]+rows[index:]),
                           raw.replace(',PASS,',',FAIL,',1),raw.replace(',actual_mode=2',',actual_mode=1')):
                with self.assertRaises(ValueError):log.parse(broken)
            with self.assertRaises(ValueError):log.parse(raw,0x87654321)

    def test_summary_and_faults(self):
        raw=fixture(True)
        for broken in (raw.replace('scaling_x1000=2500','scaling_x1000=2501'),
                       raw.replace(',c31=0',',c31=1',1),raw.replace(',c33=128',',c33=0',1)):
            with self.assertRaises(ValueError):log.parse(broken)

    def test_regressed_or_missing_run_ranges(self):
        raw=fixture(False)
        for broken in (raw.replace('run_before=36,','run_before=12,',1),
                       raw.replace('run_first=37,','run_first=13,',1),
                       raw.replace('run_last=48','run_last=24',1),
                       raw.replace('ppu_runs=894','ppu_runs=660'),
                       raw.replace('firmware_revision=2','firmware_revision=1')):
            with self.assertRaises(ValueError):log.parse(broken)


if __name__=='__main__':unittest.main(verbosity=2)
