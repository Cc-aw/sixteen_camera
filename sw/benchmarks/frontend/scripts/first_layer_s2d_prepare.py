#!/usr/bin/env python3
"""Generate an isolated first-layer experiment from locked native inputs."""
import json
import os
from pathlib import Path
import re

from parallel_cache_plan import regenerate, semantic, sha

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT.parents[2]
OUT = Path(os.environ.get('FRONTEND_BUILD', PROJECT / 'build/firmware/first-layer-s2d'))


def array(text, name):
    start = re.search(r'\b' + re.escape(name) + r'\[[^;]*?=\s*\{', text).end()
    return list(map(int, re.findall(r'-?\d+', text[start:text.index('};', start)])))


def fold_weights(weights):
    return [weights[(((2 * ky + dy) * 6 + 2 * kx + dx) * 3 + c) * 16 + o]
            for ky in range(3) for kx in range(3)
            for dy in range(2) for dx in range(2) for c in range(3) for o in range(16)]


def c_array(ctype, name, values):
    return f'static const {ctype} {name}[{len(values)}] __attribute__((aligned(64))) = {{\n' + \
        ',\n'.join(','.join(str(v) for v in values[i:i + 24]) for i in range(0, len(values), 24)) + '\n};\n'


def c_plan(name, plan):
    def words(values):
        return '{' + ','.join(f'UINT64_C({v})' for v in values) + '}'
    rows = ',\n'.join('{' + ','.join(words(p[k]) for k in ('geometry', 'offsets', 'launch')) + '}'
                      for p in plan['tiles'])
    return f'static const struct S2dPacket {name}_packets[] = {{\n{rows}\n}};\n' + \
        f'static const struct S2dPlan {name} = {{{words(plan["config"])},' + \
        f'{len(plan["tiles"])},{name}_packets}};\n'


def main():
    snap, gen = OUT / 'native', OUT / 'generated'
    frozen = json.loads((snap / 'fixed_plans.json').read_text())
    baseline = frozen['fixed_packets']['0']
    s = semantic(baseline)
    assert (s['ih'], s['iw'], s['ic'], s['oc'], s['kernel'], s['stride'], s['pad']) == (480, 640, 3, 16, 6, 2, 2)
    folded = dict(s, ih=240, iw=320, ic=12, istride=12, kernel=3, stride=1, pad=1)
    tile = [1, 30, 32, 16, 3, 3, 12]
    plans, capacities = regenerate(snap, [(0, 0, s, frozen['ordinary']['0']['tile']),
                                          (0, 1, folded, tile)], gen)
    if plans.get((0, 0)) != baseline:
        raise ValueError('First-layer frozen native roundtrip differs')
    if (0, 1) not in plans:
        raise ValueError('S2D first-layer plan exceeds native storage limits')
    params = next(snap.glob('*profile_params.h')).read_text()
    weights = array(params, 'yolov5nu_conv0_weights')
    bias = array(params, 'yolov5nu_conv0_bias')
    lut_text = (snap / 'prepared_packets.inc').read_text().split('packed_silu_luts[69][32] = {', 1)[1]
    lut = list(map(int, re.findall(r'UINT64_C\((\d+)\)', lut_text.split('}', 1)[0])))
    assert len(weights) == 1728 and len(bias) == 16 and len(lut) == 32
    header = '/* Private experiment: original math/FP16/LUT, permuted first-layer inputs and weights. */\n'
    header += c_array('int8_t', 'reference_weights', weights)
    header += c_array('int8_t', 's2d_weights', fold_weights(weights))
    header += c_array('int32_t', 'first_bias', bias)
    header += 'static const uint64_t first_lut[32] = {' + ','.join(f'UINT64_C({v})' for v in lut) + '};\n'
    header += c_plan('reference_plan', baseline) + c_plan('s2d_plan', plans[0, 1])
    (gen / 'first_layer_s2d_data.inc').write_text(header)
    description = dict(schema=1, baseline_shape=s, candidate_shape=folded, candidate_tile=tile,
                       capacity=capacities[0, 1], baseline=baseline, candidate=plans[0, 1],
                       reference_plan_sha256=sha(baseline), candidate_plan_sha256=sha(plans[0, 1]),
                       weights_sha256=sha(bytes(w & 255 for w in weights)),
                       input_sha256=sha((snap / 'inputs.c').read_bytes()),
                       generated_sha256=sha(header.encode()), status='BOARD_VALIDATION_PENDING')
    (gen / 'first_layer_s2d.json').write_text(json.dumps(description, indent=2) + '\n')
    print('S2D_PREPARE_PASS native_roundtrip=1 packets=80 ic=12 kernel=3 stride=1 default=reference')


if __name__ == '__main__':
    main()
