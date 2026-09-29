"""Check first full-size fixture's SRAM writes/read responses and input layout."""
from collections import Counter, deque
import sys

mem = [[0] * 64 for _ in range(8192)]
written = [[None] * 64 for _ in range(8192)]
requests = [deque() for _ in range(8)]
counts = Counter()
examples = {}

def expected(addr, lane):
    # This tiler reserves orows*stride + kernel_dim - 1, i.e. 21x133,
    # including one trailing row/column unused by the 8x64 output tile.
    if 0 <= addr < 2793 and lane < 18:
        r, col = divmod(addr, 133)
        col += lane // 3
        if col >= 133:
            return None  # Unused windows crossing the tile row boundary.
        if r < 2 or col < 2:
            return 0
        i = ((r - 2) * 640 + col - 2) * 3 + lane % 3
        return ((i * 7 + i // 31) % 17 - 8) & 255
    if 3988 <= addr < 4096 and lane < 16:
        kr, rem = divmod(addr - 3988, 18)
        kc, ic = divmod(rem, 3)
        return (255 if lane & 1 else 1) if (kr, kc, ic) == (lane % 6, (lane * 5 + 1) % 6, lane % 3) else 0
    return None

def mismatch(kind, detail):
    counts[kind] += 1
    examples.setdefault(kind, [])
    if len(examples[kind]) < 8:
        examples[kind].append(detail)

for line in open(sys.argv[1]):
    p = line.split()
    if len(p) < 4 or p[0] != 'TRACE' or p[1] not in ('SW', 'SR', 'SD'):
        continue
    kind, cycle, bank = p[1], int(p[2]), int(p[3])
    counts[kind] += 1
    if kind == 'SW':
        addr = bank * 1024 + int(p[4])
        mask, data = int(p[5], 16), int(p[6], 16).to_bytes(64, 'little')
        for lane, value in enumerate(data):
            if mask >> lane & 1:
                mem[addr][lane] = value
                written[addr][lane] = cycle
                exp = expected(addr, lane)
                if exp is not None and value != exp:
                    mismatch('WRITE_BAD', (cycle, addr, lane, exp, value))
    elif kind == 'SR':
        addr = bank * 1024 + int(p[4])
        requests[bank].append((cycle, addr, mem[addr][:], written[addr][:]))
    else:
        req_cycle, addr, shadow, last = requests[bank].popleft()
        data = int(p[4], 16).to_bytes(64, 'little')
        for lane, value in enumerate(data):
            if value != shadow[lane]:
                mismatch('MEMORY_MODEL_BAD', (req_cycle, addr, lane, shadow[lane], value))
            exp = expected(addr, lane)
            if exp is not None and value != exp:
                mismatch('READ_BAD', (req_cycle, addr, lane, exp, value, last[lane]))
for addr in range(4096):
    for lane in range(64):
        exp = expected(addr, lane)
        if exp is not None and written[addr][lane] is not None and mem[addr][lane] != exp:
            mismatch('FINAL_BAD', (addr, lane, exp, mem[addr][lane], written[addr][lane]))
print(dict(counts))
for kind, values in examples.items():
    print(kind, values)
print('pending reads', [len(q) for q in requests])
