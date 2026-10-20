#!/usr/bin/env python3
"""Byte-level SPAD reconstruction; rejects truncated or inconsistent traces."""
from collections import Counter
from bisect import bisect_left
import csv


class ResidencyTrace:
    def __init__(self, banks=8, rows=2048):
        self.banks, self.rows = banks, rows
        self.memory = {}
        self.history = {}
        self.intents = {}
        self.reads = {}
        self.loads = {}
        self.accepted = {bank: [] for bank in range(banks)}
        self.counts = Counter()
        self.by_stage = {}
        self.next_seq = 0
        self.last_cycle = -1
        self.stage_commits = 0
        self.ended = False

    @staticmethod
    def bytes_value(word, mask=0xffffffff):
        if len(word) > 64:
            raise ValueError('Unknown or oversized SPAD data: ' + word)
        word = word.zfill(64)
        result = bytearray(32)
        for byte in range(32):
            if mask >> byte & 1:
                value = word[62 - 2 * byte:64 - 2 * byte]
                if any(c not in '0123456789abcdefABCDEF' for c in value):
                    raise ValueError('Unknown selected SPAD data: ' + word)
                result[byte] = int(value, 16)
        return bytes(result)

    def consume(self, values):
        if len(values) != 12:
            raise ValueError('Malformed SPAD event')
        seq, cycle, event, epoch, mode, stage, bank, row, mask, data, owner, aux = values
        seq, cycle, stage, bank, row, owner, aux = map(int, (seq, cycle, stage, bank, row, owner, aux))
        mask = int(mask, 16)
        if self.ended or seq != self.next_seq or cycle < self.last_cycle or int(mode) != 2:
            raise ValueError('Noncontiguous, out-of-order, or wrong-mode trace')
        self.next_seq += 1
        self.last_cycle = cycle
        self.counts[event] += 1
        stats = self.by_stage.setdefault(stage, Counter())
        stats[event] += 1
        if event in ('SNAPSHOT', 'BANK_ACCEPT', 'BANK_COMMIT', 'DMA_CANDIDATE', 'READ_ACCEPT', 'READ_INTENT'):
            if not (0 <= bank < self.banks and 0 <= row < self.rows):
                raise ValueError('SPAD address out of range')
        key = bank, row
        if event == 'SNAPSHOT':
            if key in self.memory:
                raise ValueError('Duplicate initial row')
            self.memory[key] = bytearray(self.bytes_value(data))
            self.history[key] = [(seq, bytes(self.memory[key]), mask, -1)]
        elif event == 'BEGIN':
            if seq != 0:
                raise ValueError('BEGIN must be first')
        elif event == 'LOAD_ACCEPT':
            if owner in self.loads:
                raise ValueError('Reused logical command sequence')
            self.loads[owner] = dict(stage=stage, seq=seq, credit=aux, complete=False,
                                     write_bytes=0, equal_bytes=0, dma_writes=0, commits=[])
        elif event == 'LOAD_CREDIT':
            cmd = self.loads[owner]
            cmd['credit'] -= aux
            if cmd['credit'] < 0:
                raise ValueError('Load credit underflow')
        elif event == 'CMD_COMPLETE':
            cmd = self.loads[owner]
            if cmd['complete'] or cmd['credit']:
                raise ValueError('Early or double load completion')
            cmd['complete'] = True
        elif event == 'BANK_ACCEPT':
            word = self.bytes_value(data, mask)
            self.accepted[bank].append((row, mask, word, owner, aux))
        elif event == 'BANK_COMMIT':
            word = self.bytes_value(data, mask)
            if not self.accepted[bank] or self.accepted[bank].pop(0) != (row, mask, word, owner, aux):
                raise ValueError('Bank acceptance/commit ledger mismatch')
            resident = self.memory[key]
            selected = [i for i in range(32) if mask >> i & 1]
            equal = sum(resident[i] == word[i] for i in selected)
            stats['committed_spad_bytes'] += len(selected)
            if aux == 0:
                cmd = self.loads[owner]
                cmd['dma_writes'] += 1
                cmd['write_bytes'] += len(selected)
                cmd['equal_bytes'] += equal
                cmd['commits'].append((seq, key, mask, word))
                stats['dma_spad_bytes'] += len(selected)
                stats['same_value_spad_bytes'] += equal
            for i in selected:
                resident[i] = word[i]
            self.history[key].append((seq, bytes(resident), mask, owner))
            self.stage_commits += 1
        elif event == 'READ_INTENT':
            if owner in self.intents:
                raise ValueError('Duplicate read intent')
            self.intents[owner] = (bank, row)
        elif event == 'READ_ACCEPT':
            if self.intents.pop(owner) != key or owner in self.reads:
                raise ValueError('Read accepted at wrong address')
            self.reads[owner] = bytes(self.memory[key])
        elif event == 'READ_DATA':
            if self.reads.pop(owner) != self.bytes_value(data):
                raise ValueError('Read differs from reconstructed physical SRAM bytes')
        elif event == 'BOUNDARY':
            if aux != self.stage_commits:
                raise ValueError('SPAD counter/trace commit count mismatch')
            if self.reads or self.intents or any(self.accepted.values()):
                raise ValueError('Unfinished bank/read lifecycle at stage boundary')
            self.stage_commits = 0
        elif event == 'END':
            self.ended = True
        elif event != 'DMA_CANDIDATE':
            raise ValueError('Unknown event: ' + event)

    def finish(self):
        if not self.ended or self.counts['BEGIN'] != 1 or self.counts['END'] != 1:
            raise ValueError('Incomplete trace')
        if len(self.memory) != self.banks * self.rows:
            raise ValueError('Missing initial SRAM state')
        if self.intents or self.reads or any(self.accepted.values()):
            raise ValueError('Unclosed physical transactions')
        if any(c['credit'] or not c['complete'] for c in self.loads.values()):
            raise ValueError('Unclosed logical load completion/credit')
        for owner, command in self.loads.items():
            resident = command['write_bytes'] > 0
            interfered = False
            for commit_seq, key, mask, word in command['commits']:
                history = self.history[key]
                first = bisect_left(history, command['seq'], key=lambda item: item[0])
                if not first:
                    raise ValueError('Load precedes known initial SRAM state')
                at_issue = history[first - 1][1]
                resident &= all(at_issue[i] == word[i] for i in range(32) if mask >> i & 1)
                last = bisect_left(history, commit_seq, key=lambda item: item[0])
                interfered |= any(entry[2] & mask and entry[3] != owner for entry in history[first:last])
            command['all_written_values_resident_at_issue'] = bool(resident)
            command['intervening_other_writer'] = bool(interfered)
            command['stable_value_residency_diagnostic'] = bool(resident and not interfered)
        return self


def reconstruct(path):
    trace = ResidencyTrace()
    with path.open() as handle:
        for row in csv.reader(handle):
            trace.consume(row)
    return trace.finish()
