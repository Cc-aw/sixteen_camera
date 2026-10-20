#!/usr/bin/env python3
"""Bounded independent command/credit/TL/bank ledger for the actual G1 trace.

Credit/ROB completion is deliberately allowed before pending bank commits.
Physical accepted writes retain their original owner until their commit.
"""
import argparse
from bisect import bisect_right
from collections import Counter, defaultdict, deque
import csv
import gzip
import json
from pathlib import Path

from compare_candidate import sha


class Transactions:
    def __init__(self,symbols=None):
        self.tags,self.robs,self.reserved,self.active={},{},{},{}
        self.banks=[deque() for _ in range(8)]
        self.stats=Counter()
        self.stages=defaultdict(Counter)
        self.markers=set()
        self.pending_skips=0
        self.symbols=sorted((value['base'],value['base']+value['bytes'],
            'bias' if name.endswith('_bias') else 'weight') for name,value in (symbols or {}).items())
        self.bases=[value[0] for value in self.symbols]

    def role(self,address,zero):
        if zero:return 'zero'
        index=bisect_right(self.bases,address)-1
        if index>=0 and address<self.symbols[index][1]:return self.symbols[index][2]
        return 'input'

    def record(self,row):
        event=row[0]
        stage=int(row[4])
        stat=self.stages[stage]
        if event=='R':
            first,last,index,rows,tag,source,dest,acc,cols,repeats,scale,wide,zero,block,pixels,stride,rob=map(int,row[6:])
            if first:
                old=self.tags.get(tag)
                if old and (old['credit'] or not old['retired']):raise ValueError('Early DMA tag reuse')
                if old and any(owner is old for queue in self.banks for payload,owner in queue):
                    stat['dma_tag_reuse_before_last_bank_commit']+=1
                if rob in self.robs:raise ValueError('Early ROB reuse')
                if index or rows<=0 or cols<=0:raise ValueError('Malformed first Load row')
                load=dict(credit=cols*rows*(4 if wide else 1),retired=False,last=False,index=0,rows=rows,
                    role=self.role(source,zero),stage=stage)
                self.tags[tag]=self.robs[rob]=load
                stat['mvin_commands']+=1
                stat[load['role']+'_mvin_commands']+=1
                stat['credit_expected']+=load['credit']
            load=self.tags[tag]
            if index!=load['index'] or bool(first)!=(index==0) or load['last']:raise ValueError('Reordered Load rows')
            load['index']+=1
            load['last']=bool(last)
            if last and load['index']!=load['rows']:raise ValueError('Truncated whole Load')
            stat['dma_rows']+=1
        elif event=='Y':
            tag,credit=map(int,row[6:])
            load=self.tags[tag]
            if credit<=0 or load['credit']<credit:raise ValueError('Double/oversized DMA credit')
            load['credit']-=credit
            self.stages[load['stage']]['credit_returned']+=credit
        elif event=='X':
            rob=int(row[6]);load=self.robs.pop(rob)
            if load['credit'] or not load['last'] or load['retired']:raise ValueError('Early/double ROB retirement')
            load['retired']=True
            self.stages[load['stage']]['mvin_retired']+=1
        elif event=='G':
            source,tag=map(int,row[6:])
            # The merged Gemmini TL mux prefixes Reader IDs with bit 5.
            source+=32
            if source in self.reserved or source in self.active:raise ValueError('Reader source reused before completion')
            if self.tags[tag]['role']=='zero':raise ValueError('Zero writer allocated a physical Get')
            self.reserved[source]=self.tags[tag]
        elif event=='T' and int(row[6])==4:
            source,size=map(int,row[7:9])
            load=self.reserved.pop(source)
            if source in self.active:raise ValueError('Duplicate physical Get')
            self.active[source]=dict(size=size,beat=0,beats=2 if size==6 else 1,owner=load,opcode=1,a_remaining=0)
            owner=self.stages[load['stage']]
            owner['get_requests']+=1;owner['get_bytes']+=1<<size
            owner[load['role']+'_get_bytes']+=1<<size
        elif event=='T' and int(row[6]) in (0,1):
            source,size=map(int,row[7:9])
            if source not in self.active:
                self.active[source]=dict(size=size,beat=0,beats=1,owner=None,opcode=0,a_remaining=2 if size==6 else 1)
            transaction=self.active[source]
            if transaction['opcode']!=0 or transaction['size']!=size or transaction['a_remaining']<=0:
                raise ValueError('Malformed Put continuation')
            transaction['a_remaining']-=1
            stat['put_beats']+=1
        elif event=='D':
            source,size,opcode,beat=map(int,row[6:10])
            transaction=self.active[source]
            if size!=transaction['size'] or beat!=transaction['beat'] or opcode!=transaction['opcode'] or transaction['a_remaining']:
                raise ValueError('Early/malformed TL response')
            transaction['beat']+=1
            if transaction['beat']==transaction['beats']:del self.active[source]
        elif event=='A':
            bank,kind,tag=map(int,(row[6],row[9],row[10]))
            owner=None if kind==1 else self.tags[tag]
            self.banks[bank].append((tuple(row[7:]),owner))
            stat['bank_accepts']+=1
        elif event=='W':
            bank=int(row[6])
            if not self.banks[bank] or self.banks[bank].popleft()[0]!=tuple(row[7:]):raise ValueError('Bank commit without original accepted payload/owner')
            stat['bank_commits']+=1
            stat['spad_write_bytes']+=int(row[8]).bit_count()
        elif event=='C':stat['native_words']+=1
        elif event=='B':
            stat['native_words']+=1
            if int(row[6])==253:
                if stage in self.markers:raise ValueError('Duplicate native stage')
                self.markers.add(stage)
        elif event=='K':
            skip,supported,half,rows=map(int,row[6:10])
            source=int(row[10],16)&((1<<40)-1)
            stat['input_tiles']+=1;stat['supported_tiles']+=supported
            stat['native_null_tiles']+=source==0
            if skip:
                if not supported or not source or half not in (0,1) or not 0<rows<=8192:
                    raise ValueError('Illegal whole Input skip or existing reuse counted again')
                stat['skipped_tiles']+=1;self.pending_skips+=1
        elif event=='N':
            if self.pending_skips<=0:raise ValueError('Fabricated replacement completion')
            self.pending_skips-=1;stat['replacement_completions']+=1
        elif event=='S':
            for key,value in zip(('functional_cycles','ex_active','a_wait','b_wait','d_wait','load_busy','row_backpressure','operand_wait_union'),row[6:]):
                stat[key]+=int(value)

    def finish(self):
        if self.robs or self.reserved or self.active or any(self.banks) or self.pending_skips:
            raise ValueError('Unfinished command, physical transfer, bank write, or replacement token')
        if any(load['credit'] or not load['retired'] or not load['last'] for load in self.tags.values()):
            raise ValueError('Unfinished Load')
        totals=Counter()
        for stat in self.stages.values():totals.update(stat)
        if totals['credit_expected']!=totals['credit_returned']:raise ValueError('Credit ledger does not balance')
        if totals['mvin_commands']!=totals['mvin_retired']:raise ValueError('Load retirement ledger does not balance')
        if totals['bank_accepts']!=totals['bank_commits']:raise ValueError('Physical commit ledger does not balance')
        return totals


def audit(trace,workload,output,lane):
    identity=json.loads(workload.read_text())
    ledger=Transactions(identity['weight_symbols'])
    with gzip.open(trace,'rt') as source:
        for row in csv.reader(source):
            if int(row[2])!=lane:raise ValueError('Physical lane mismatch')
            if int(row[3])!=0:raise ValueError('G1 audit expects complete first frame only')
            ledger.record(row)
    totals=ledger.finish()
    if ledger.markers!=set(range(166)) or totals['native_words']!=11049 or totals['input_tiles']!=462:
        raise ValueError('Incomplete native workload coverage')
    output.mkdir(parents=True,exist_ok=False)
    fields=sorted(set().union(*(stat.keys() for stat in ledger.stages.values())))
    with (output/'per_stage.csv').open('w',newline='') as dest:
        writer=csv.DictWriter(dest,fieldnames=['lane','stage',*fields]);writer.writeheader()
        for stage in sorted(ledger.stages):writer.writerow(dict(lane=lane,stage=stage,**ledger.stages[stage]))
    result=dict(schema=1,status='PASS',lane=lane,frames=1,stages=166,totals=totals,
        credit_and_rob_before_final_bank_commit_allowed=True,all_transfers_drained=True,
        full_system_performance_model=False,
        sha256={str(p):sha(p) for p in (trace,workload,Path(__file__).resolve())})
    (output/'transactions.json').write_text(json.dumps(result,indent=2)+'\n')
    print('CSC_G1_TRANSACTION_LEDGER_PASS',lane,dict(totals))


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--trace',type=Path,required=True)
    parser.add_argument('--workload',type=Path,required=True)
    parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--lane',type=int,choices=(0,1,2),required=True)
    args=parser.parse_args()
    audit(args.trace.resolve(),args.workload.resolve(),args.output.resolve(),args.lane)
