"""First full tile: compare six kernel-row contributions and accumulator reads."""
from collections import Counter, defaultdict, deque
import sys

mem = [[0] * 16 for _ in range(1024)]
ordinal = Counter()
queues = [deque() for _ in range(4)]
counts = Counter()
samples = defaultdict(list)

def record(kind, info):
    counts[kind] += 1
    if len(samples[kind]) < 8:
        samples[kind].append(info)

def value(addr, c):
    r, col = divmod(addr, 64)
    ir, ic = r * 2 - 2 + c % 6, col * 2 - 2 + (c * 5 + 1) % 6
    if ir < 0 or ic < 0:
        return 0
    i = (ir * 640 + ic) * 3 + c % 3
    return ((i * 7 + i // 31) % 17 - 8) * (-1 if c & 1 else 1)

for line in open(sys.argv[1]):
    p = line.split()
    if p[:2] not in (['TRACE', 'AW'], ['TRACE', 'AR'], ['TRACE', 'AD']):
        continue
    kind, cycle, bank = p[1], int(p[2]), int(p[3])
    counts[kind] += 1
    if kind == 'AR':
        queues[bank].append(bank * 256 + int(p[4]))
        continue
    data = int(p[-1], 16).to_bytes(64, 'little')
    values = [int.from_bytes(data[i:i+4], 'little', signed=True) for i in range(0, 64, 4)]
    if kind == 'AW':
        addr, acc = bank * 256 + int(p[4]), int(p[5])
        k = ordinal[addr] - 1
        for c, actual in enumerate(values):
            expected = c % 5 - 2 if not acc else (value(addr, c) if c % 6 == k else 0)
            if actual != expected:
                record('CONTRIBUTION_BAD', (cycle, addr, k, c, expected, actual))
            mem[addr][c] = mem[addr][c] + actual if acc else actual
        ordinal[addr] += 1
    else:
        addr = queues[bank].popleft()
        for c, actual in enumerate(values):
            if actual != mem[addr][c]:
                record('ACCUMULATION_BAD', (cycle, addr, c, mem[addr][c], actual))
            expected = c % 5 - 2 + value(addr, c)
            if actual != expected:
                record('READ_BAD', (cycle, addr, c, expected, actual))
print(dict(counts))
print('writes per address', dict(Counter(ordinal.values())))
for kind, details in samples.items():
    print(kind, details)
