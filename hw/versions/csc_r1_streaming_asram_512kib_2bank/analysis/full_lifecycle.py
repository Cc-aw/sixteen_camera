#!/usr/bin/env python3
"""Streaming physical SRAM/credit/read/source-generation audit for full C0.

Only completed whole-load descriptors can match. Every intervening overlapping
writer invalidates the descriptor, including writes of numerically equal data.
Source epochs are tracked per physical byte, including masked Put beats. This counts
opportunities in the baseline trace, not a tested hardware bypass.
"""
from array import array
from collections import Counter, deque
from dataclasses import dataclass, field


def footprint(source, dest, cols, repeats, block_stride, pixels, rows, source_stride):
    if not (0 <= dest < 16384 and source >= 0 and source_stride >= 0 and
            0 < cols <= 128 and 0 < pixels <= 255 and 0 < rows <= 32):
        raise ValueError('Unsupported full Load geometry')
    cells, pages = set(), set()
    for row in range(rows):
        address = source + row * source_stride
        pages.update(range(address // 32, (address + cols - 1) // 32 + 1))
        for block in range((cols + 31) // 32):
            width = min(32, cols - block * 32)
            for repeat in range(repeats + 1):
                target = (dest + row + block * block_stride + repeat) % 16384
                floor = 0 if target < 8192 else 8192
                for pixel in reversed(range(pixels)):
                    if target < floor + pixel:
                        continue
                    for byte in range(width):
                        offset = pixel * width + byte
                        if offset < 32:
                            cells.add((target - pixel) * 32 + offset)
    return cells, tuple(sorted(pages))


@dataclass
class Load:
    logical: int
    key: tuple
    frame: int
    stage: int
    credit: int
    acc: bool
    zero: bool
    cells: set = field(default_factory=set)
    pages: tuple = ()
    versions: tuple = ()
    written: set = field(default_factory=set)
    pending: int = 0
    next_row: int = 0
    last: bool = False
    retired: bool = False
    finished: bool = False
    valid: bool = True
    candidate: bool = False
    candidate_valid: bool = False
    gets: int = 0
    get_bytes: int = 0
    prior: int = 0
    issue_cycle: int = 0
    completion_cycle: int = 0
    prior_complete_cycle: int = 0
    write_bytes: int = 0


class FullLedger:
    def __init__(self, weights=(), zero_owners=False, biases=()):
        self.memory = bytearray(524288)
        self.owner = array('I', [0]) * 524288
        self.pending = array('H', [0]) * 524288
        self.bank_queues = [deque() for _ in range(8)]
        self.reads = [deque() for _ in range(8)]
        self.loads, self.tags, self.robs, self.cache = {}, {}, {}, {}
        self.source_cache = {}
        self.candidates = set()
        self.reserved, self.transactions = {}, {}
        self.versions = {}
        self.version = self.logical = self.sequence = 0
        self.cycle = -1
        self.frame = None
        self.stages = set()
        self.stats = {}
        self.examples = []
        self.qualified = []
        self.example_counts = Counter()
        self.invalidations = Counter()
        self.weights = weights
        self.biases = biases
        self.zero_owners = zero_owners

    def stat(self, frame, stage):
        return self.stats.setdefault((frame, stage), Counter())

    def role(self, load):
        source = load.key[0]
        if load.zero:
            return 'zero'
        if any(a <= source < b for a, b in self.weights):
            return 'weight'
        if any(a <= source < b for a, b in self.biases):
            return 'bias'
        return 'input'

    @staticmethod
    def source_key(load):
        return load.key[:1] + load.key[2:]

    def source_versions(self, load):
        if load.zero:
            return ()
        source, cols, rows, stride = load.key[0], load.key[3], load.key[10], load.key[11]
        result = []
        for row in range(rows):
            address = source + row * stride
            for byte in range(cols):
                page, offset = divmod(address + byte, 32)
                versions = self.versions.get(page)
                result.append(versions[offset] if versions is not None else 0)
        return tuple(result)

    def mutate(self, address, length, mask=None):
        self.version += 1
        for byte in range(length):
            if mask is not None and not (mask >> byte & 1):
                continue
            page, offset = divmod(address + byte, 32)
            if page not in self.versions:
                self.versions[page] = array('I', [0]) * 32
            self.versions[page][offset] = self.version

    def invalidate(self, logical, reason):
        load = self.loads.get(logical)
        if load is None:
            return
        if load.valid:
            load.valid = False
            self.invalidations[reason] += 1
            if self.cache.get(load.key) == logical:
                del self.cache[load.key]
            source_key = self.source_key(load)
            existing = self.source_cache.get(source_key)
            if existing is not None:
                existing.discard(logical)
                if not existing:
                    del self.source_cache[source_key]
        if load.finished:
            self.loads.pop(logical, None)

    def finish(self, load):
        if load.finished or load.credit or not load.retired or not load.last or load.pending:
            return
        if not load.acc and (not load.zero or self.zero_owners) and load.written != load.cells:
            # Credits can precede the last SRAM commit; completion alone never
            # proves residency. A later W event can complete this descriptor.
            return
        load.finished = True
        load.completion_cycle = self.cycle
        stat = self.stat(load.frame, load.stage)
        stat['completed_mvin_commands'] += 1
        if load.candidate:
            self.candidates.discard(load.logical)
            if load.candidate_valid and self.source_versions(load) == load.versions:
                stat['eligible_exact_mvin_commands'] += 1
                stat['eligible_exact_get_bytes'] += load.get_bytes
                stat['eligible_exact_spad_bytes'] += load.write_bytes
                stat['eligible_load_lifetime_cycles_sum'] += self.cycle - load.issue_cycle + 1
                if load.zero:
                    stat['eligible_exact_zero_commands'] += 1
                source = load.key[0]
                role = self.role(load)
                stat[role + '_eligible_exact_get_bytes'] += load.get_bytes
                self.qualified.append(dict(frame=load.frame, stage=load.stage, logical=load.logical,
                    previous_command=load.prior, role=role, get_bytes=load.get_bytes,
                    spad_bytes=load.write_bytes, accept_cycle=load.issue_cycle,
                    full_commit_cycle=load.completion_cycle))
                example_key = load.frame, load.stage, role
                if self.example_counts[example_key] < 2:
                    self.example_counts[example_key] += 1
                    self.examples.append(dict(frame=load.frame, stage=load.stage, command=load.logical,
                        previous_command=load.prior, source=source, destination_row=load.key[1],
                        get_bytes=load.get_bytes, spad_bytes=load.write_bytes, resident_footprint_bytes=len(load.cells), role=role,
                        previous_full_commit_cycle=load.prior_complete_cycle, accept_cycle=load.issue_cycle,
                        full_commit_cycle=load.completion_cycle, reuse_distance_mvin=load.logical-load.prior))
            else:
                self.invalidations['candidate_invalidated_before_full_commit'] += 1
        if not load.acc and (not load.zero or self.zero_owners) and load.valid and self.source_versions(load) == load.versions:
            prior = self.cache.get(load.key)
            if prior and prior != load.logical:
                self.invalidate(prior, 'descriptor_replaced')
            self.cache[load.key] = load.logical
            self.source_cache.setdefault(self.source_key(load), set()).add(load.logical)
            load.written.clear()
        else:
            self.loads.pop(load.logical, None)

    @staticmethod
    def word(value):
        if len(value) != 64 or any(c not in '0123456789abcdef' for c in value.lower()):
            raise ValueError('Nonconcrete SRAM data')
        return bytes.fromhex(value)[::-1]

    def consume(self, row):
        event = row[0]
        cycle, lane, frame, stage, sequence = map(int, row[1:6])
        if sequence != self.sequence or cycle < self.cycle:
            raise ValueError('Trace sequence gap/time reversal')
        self.sequence += 1
        self.cycle = cycle
        stat = self.stat(frame, stage)
        stat['events'] += 1
        if event == 'B':
            stat['native_words'] += 1
            kind, a, b = map(int, row[6:])
            if kind == 253:
                if self.frame != frame:
                    for logical in list(self.cache.values()):
                        self.invalidate(logical, 'frame_switch')
                    self.frame = frame
                if (frame, stage) in self.stages:
                    raise ValueError('Duplicate stage marker')
                self.stages.add((frame, stage))
            elif kind in (254, 255):
                if (kind == 255 and (a or b)) or (kind == 254 and bool(a) != bool(b)):
                    raise ValueError('Unknown native boundary mutation')
                if self.transactions or self.reserved or any(self.bank_queues) or any(self.reads) or any(
                        not load.finished for load in self.loads.values()):
                    raise ValueError('Native boundary before full completion')
                if kind == 254 and a and b:
                    self.mutate(b, 17 * 22 * 128)
                    stat['host_pad_updates'] += 1
            else:
                raise ValueError('Unknown native boundary')
            return
        if event == 'C':
            stat['native_words'] += 1
            stat['native_raw_words'] += 1
            return
        if event == 'R':
            v = list(map(int, row[6:]))
            if len(v) != 17:
                raise ValueError('Malformed DMA row')
            first, last, index, rows, tag, source, dest, acc, cols, repeats, scale, wide, zero, block, pixels, stride, rob = v
            if first:
                if tag in self.tags and (self.tags[tag].credit or not self.tags[tag].retired):
                    raise ValueError('DMA tag reused before credit/ROB retirement')
                self.logical += 1
                key = (source, dest, acc, cols, repeats, scale, wide, zero, block, pixels, rows, stride)
                load = Load(self.logical, key, frame, stage, cols * rows * (4 if wide else 1), bool(acc), bool(zero))
                load.issue_cycle = cycle
                if not acc and (not zero or self.zero_owners):
                    if wide:
                        raise ValueError('Unsupported wide SPAD write')
                    load.cells, load.pages = footprint(source, dest, cols, repeats, block, pixels, rows, stride)
                    load.versions = self.source_versions(load)
                    prior = self.loads.get(self.cache.get(key))
                    if prior and prior.finished and prior.valid and self.source_versions(prior) == prior.versions:
                        if all(self.owner[c] == prior.logical and not self.pending[c] for c in load.cells):
                            load.candidate = load.candidate_valid = True
                            load.prior = prior.logical
                            load.prior_complete_cycle = prior.completion_cycle
                            self.candidates.add(load.logical)
                        else:
                            self.invalidations['overwritten_or_pending_at_accept'] += 1
                    elif prior:
                        self.invalidations['source_generation_changed'] += 1
                    if not load.candidate:
                        for logical in self.source_cache.get(self.source_key(load), ()):
                            other = self.loads[logical]
                            if other.key[1] != dest and len(other.cells) == len(load.cells) and self.source_versions(other) == other.versions and all(
                                    self.owner[c] == logical and not self.pending[c] for c in other.cells):
                                stat['same_source_diff_destination_commands'] += 1
                                break
                self.loads[load.logical] = load
                self.tags[tag] = self.robs[rob] = load
                stat['all_mvin_commands'] += 1
                stat[self.role(load) + '_mvin_commands'] += 1
                stat['acc_mvin_commands' if acc else 'spad_mvin_commands'] += 1
            load = self.tags[tag]
            if index != load.next_row or (first != (index == 0)) or load.last:
                raise ValueError('Incomplete/reordered Load rows')
            load.next_row += 1
            load.last = bool(last)
            if last and load.next_row != rows:
                raise ValueError('Truncated Load')
            stat['dma_rows'] += 1
            self.finish(load)
            return
        if event == 'Y':
            tag, credit = map(int, row[6:])
            load = self.tags[tag]
            load.credit -= credit
            if load.credit < 0:
                raise ValueError('Double/oversized DMA credit')
            self.finish(load)
            return
        if event == 'X':
            load = self.robs[int(row[6])]
            if load.retired or load.credit:
                raise ValueError('Early/double Load ROB retirement')
            load.retired = True
            self.finish(load)
            return
        if event == 'G':
            source, tag = map(int, row[6:])
            if source in self.reserved:
                raise ValueError('Reader source reserved twice')
            self.reserved[source] = self.tags[tag]
            return
        if event == 'T':
            opcode, source, size, address, mask = map(int, row[6:11])
            if opcode == 4:
                if source in self.transactions:
                    raise ValueError('TL Get source reused')
                load = self.reserved[source - 32]
                if not load.acc and not load.zero and not set(range(address // 32, (address + (1 << size) - 1) // 32 + 1)).intersection(load.pages):
                    raise ValueError('Physical Get outside its attributed Load source range')
                self.transactions[source] = [size, max(1, (1 << size) // 32), 1, 0]
                load.gets += 1
                load.get_bytes += 1 << size
                self.stat(load.frame, load.stage)['all_tl_get_requests'] += 1
                self.stat(load.frame, load.stage)['all_tl_get_bytes'] += 1 << size
                self.stat(load.frame, load.stage)[self.role(load) + '_tl_get_bytes'] += 1 << size
            elif opcode in (0, 1):
                if source not in self.transactions:
                    self.transactions[source] = [size, 1, 0, max(1, (1 << size) // 32)]
                t = self.transactions[source]
                if t[0] != size or t[2] != 0 or not t[3]:
                    raise ValueError('Malformed Put continuation')
                beat = max(1, (1 << size) // 32) - t[3]
                t[3] -= 1
                # Source producer epochs are conservative per physical word.
                self.mutate((address & ~31) + beat * 32, 32, mask)
            else:
                raise ValueError('Unexpected TL A opcode')
            return
        if event == 'D':
            source, size, opcode, beat = map(int, row[6:10])
            t = self.transactions[source]
            if (size, opcode) != (t[0], t[2]) or t[3]:
                raise ValueError('Early/wrong TL response')
            t[1] -= 1
            if t[1] == 0:
                del self.transactions[source]
                if opcode == 1:
                    del self.reserved[source - 32]
            return
        if event in ('A', 'W'):
            bank, address, mask, kind, tag = map(int, row[6:11])
            if not (0 <= bank < 8 and 0 <= address < 2048 and 0 < mask <= 0xffffffff):
                raise ValueError('Invalid physical SPAD write')
            word = self.word(row[11])
            cells = [(bank * 2048 + address) * 32 + b for b in range(32) if mask >> b & 1]
            if event == 'A':
                load = self.tags[tag] if kind == 0 or (kind == 2 and self.zero_owners) else None
                if load and load.finished:
                    raise ValueError('Bank write accepted after its Load fully finished')
                if load and bool(kind == 2) != load.zero:
                    raise ValueError('Zero/DMA write attributed to wrong command type')
                logical = load.logical if load else 0
                self.bank_queues[bank].append((address, mask, kind, tag, word, logical))
                for candidate in list(self.candidates):
                    active = self.loads[candidate]
                    if candidate != logical and not active.cells.isdisjoint(cells):
                        active.candidate_valid = False
                prior_writers = {self.owner[cell] for cell in cells}
                for prior in prior_writers - {0, logical}:
                    self.invalidate(prior, 'intervening_ex_zero_or_dma_write')
                for cell in cells:
                    self.owner[cell] = logical
                    self.pending[cell] += 1
                if load:
                    load.pending += 1
                return
            accepted = self.bank_queues[bank].popleft()
            if accepted[:5] != (address, mask, kind, tag, word):
                raise ValueError('SRAM acceptance/commit mismatch')
            logical = accepted[5]
            load = self.loads[logical] if logical else None
            for byte in range(32):
                if not mask >> byte & 1:
                    continue
                cell = (bank * 2048 + address) * 32 + byte
                if not self.pending[cell]:
                    raise ValueError('Commit without pending write')
                self.pending[cell] -= 1
                if load:
                    if cell not in load.cells:
                        raise ValueError('Real SRAM byte outside reconstructed Load footprint')
                    load.written.add(cell)
                    if load.candidate and self.memory[cell] != word[byte]:
                        load.candidate_valid = False
                self.memory[cell] = word[byte]
            stat['physical_spad_commits'] += 1
            stat['converted_spad_write_bytes'] += mask.bit_count()
            stat[('ex' if kind == 1 else 'zero' if kind == 2 else 'dma') + '_spad_write_bytes'] += mask.bit_count()
            if load:
                load.write_bytes += mask.bit_count()
                load.pending -= 1
                self.finish(load)
            return
        if event == 'I':
            stat['ex_read_intent_cycles'] += 1
            return
        if event == 'S':
            fields = ('functional_stage_cycles', 'ex_active_cycles', 'spad_a_wait_cycles',
                      'spad_b_wait_cycles', 'spad_d_wait_cycles', 'load_busy_cycles',
                      'row_backpressure_cycles', 'spad_operand_wait_union_cycles')
            if len(row[6:]) != len(fields) or 'functional_stage_cycles' in stat:
                raise ValueError('Malformed/duplicate stage metrics')
            metrics = list(map(int, row[6:]))
            if any(value > metrics[0] for value in metrics[1:]):
                raise ValueError('Cycle metric exceeds stage duration')
            stat.update(dict(zip(fields, metrics)))
            return
        if event == 'Q':
            bank, address = map(int, row[6:])
            offset = (bank * 2048 + address) * 32
            self.reads[bank].append(bytes(self.memory[offset:offset+32]))
            stat['accepted_spad_reads'] += 1
            return
        if event == 'V':
            bank = int(row[6])
            if self.reads[bank].popleft() != self.word(row[7]):
                raise ValueError('SRAM read differs from committed state')
            return
        raise ValueError('Unknown full trace event: ' + event)

    def check_end(self):
        if self.transactions or self.reserved or any(self.bank_queues) or any(self.reads):
            raise ValueError('Unclosed memory/SRAM/read lifecycle')
        if any(not load.finished for load in self.loads.values()):
            raise ValueError('Unfinished Load descriptor/credit/ROB lifecycle')
