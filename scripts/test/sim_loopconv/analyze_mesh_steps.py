"""Locate first-full-tile operand misalignment at actual mesh advance cycles."""
import sys

phase = -1
steps = 0
bad_a = []
nonzero_d = []
for line in open(sys.argv[1]):
    p = line.split()
    if p[:2] != ['TRACE', 'MS']:
        continue
    cycle, row, a, d = int(p[2]), int(p[3]), int(p[4], 16), int(p[5], 16)
    if row == 0:
        phase += 1
    steps += 1
    if d:
        lanes = [i for i in range(64) if d >> (i * 8) & 255]
        # Each fixture output channel has one nonzero kernel coefficient.
        c = lanes[0]
        kr, kc, ic = c % 6, (c * 5 + 1) % 6, c % 3
        expected_row = 63 - (kc * 3 + ic)
        nonzero_d.append((cycle, phase, kr, expected_row, row, lanes))
    if 1 <= phase <= 48:
        kr, out_r = divmod(phase - 1, 8)
        for lane in range(64):
            ir, ic = out_r * 2 + kr - 2, row * 2 + lane // 3 - 2
            i = (ir * 640 + ic) * 3 + lane % 3
            expected = ((i * 7 + i // 31) % 17 - 8) & 255 if lane < 18 and ir >= 0 and ic >= 0 else 0
            actual = a >> (lane * 8) & 255
            if expected != actual:
                bad_a.append((cycle, phase, row, lane, expected, actual))
assert steps == 49 * 64, f'Incomplete first-tile trace: {steps} steps'
print('mesh steps:', steps, 'input byte mismatches:', len(bad_a))
print('first input mismatches:', bad_a[:8])
print('weight cycle / phase / kernel row / expected step / actual step / channels')
for entry in nonzero_d:
    print(*entry, 'OK' if entry[3] == entry[4] else 'MISALIGNED')
