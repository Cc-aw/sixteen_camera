#!/usr/bin/env python3
"""Strict last-session parser for the isolated serial/parallel first-layer A/B."""
import argparse
import hashlib
import json
from pathlib import Path

PROFILES = ('reference', 'prepacked', 'rvv_online')
EXECUTORS = ('serial', 'parallel')
COUNTERS = ('rs_active', 'exec_active', 'load_req_wait', 'store_req_wait',
            'rdma_tl_wait', 'spad_a_wait', 'spad_b_wait', 'spad_d_wait')


def parse(text):
    lines = text.splitlines()
    starts = [i for i, line in enumerate(lines) if line.startswith('S2D1,BUILD,')]
    if not starts:
        raise ValueError('No S2D1 BUILD record')
    records = []
    for line in lines[starts[-1]:]:
        if 'S2D1,' not in line:
            continue
        if not line.startswith('S2D1,'):
            raise ValueError('Corrupt S2D1 record prefix')
        fields = line.split(',')
        kind, data = fields[1], {}
        if kind in ('FAIL', 'TRAP', 'DIFF'):
            raise ValueError('Firmware reported ' + line)
        for item in fields[2:]:
            if '=' not in item:
                raise ValueError('Malformed field: ' + line)
            key, value = item.split('=', 1)
            if not key or not value or key in data:
                raise ValueError('Missing or duplicate field: ' + line)
            data[key] = value
        records.append((kind, data))
    if not records or records[0][0] != 'BUILD' or records[-1][0] != 'PASS':
        raise ValueError('Incomplete session')
    if any(kind not in ('BUILD', 'RESULT', 'SUMMARY', 'PASS') for kind, _ in records):
        raise ValueError('Unknown record kind')
    if sum(kind == 'BUILD' for kind, _ in records) != 1 or sum(kind == 'PASS' for kind, _ in records) != 1:
        raise ValueError('Duplicate session markers')

    def number(data, key):
        value = data.get(key, '')
        if not value.isascii() or not value.isdecimal():
            raise ValueError('Missing or invalid integer: ' + key)
        return int(value)

    def expect(data, expected):
        for key, value in expected.items():
            if isinstance(value, int):
                if number(data, key) != value:
                    raise ValueError('Unexpected ' + key)
            elif data.get(key) != value:
                raise ValueError('Unexpected ' + key)

    expect(records[0][1], dict(schema=1, rounds=4, profiles=3, executors=2, frames_per_batch=3,
                               clock_hz=100000000, scope='first_conv', evict_bytes=4194304,
                               prepacked_excludes_pack=1, online_includes_pack=1))
    expect(records[-1][1], dict(measured_records=24, warmup_records=6, compared_bytes_per_record=3686400,
                                full_output_bit_exact=1, scope='first_conv'))
    result, summaries = {}, {}
    for kind, data in records[1:-1]:
        if kind == 'SUMMARY':
            profile = data.get('profile')
            if profile not in PROFILES or profile in summaries:
                raise ValueError('Unknown or duplicate summary')
            summaries[profile] = data
            continue
        if kind != 'RESULT':
            raise ValueError('Unexpected record ordering')
        profile, executor = data.get('profile'), data.get('executor')
        warmup, round_id = number(data, 'warmup'), number(data, 'round')
        key = profile, executor, warmup, round_id
        if profile not in PROFILES or executor not in EXECUTORS or key in result:
            raise ValueError('Unknown or duplicate result')
        expect(data, dict(frames=3, compared_bytes=3686400, bit_exact=1))
        values = {k: number(data, k) for k in ('batch_cycles', 'pack_cycles', *COUNTERS)}
        if not values['batch_cycles'] or not values['rs_active'] or not values['exec_active']:
            raise ValueError('Inactive measurement')
        if (profile == 'rvv_online') != bool(values['pack_cycles']):
            raise ValueError('Packing accounting differs from profile')
        if values['pack_cycles'] > values['batch_cycles']:
            raise ValueError('Packing cycles exceed the enclosing interval')
        result[key] = values
    expected = {(p, e, w, r) for p in PROFILES for e in EXECUTORS
                for w, rounds in ((1, (0,)), (0, range(4))) for r in rounds}
    if set(result) != expected or set(summaries) != set(PROFILES):
        raise ValueError('Missing or unexpected result/summary records')
    totals = {(p, e): sum(result[p, e, 0, r]['batch_cycles'] for r in range(4))
              for p in PROFILES for e in EXECUTORS}
    aggregate = []
    for p in PROFILES:
        serial, parallel = totals[p, 'serial'], totals[p, 'parallel']
        expect(summaries[p], dict(serial_cycles=serial, parallel_cycles=parallel,
               parallel_speedup_x1000=serial * 1000 // parallel,
               parallel_efficiency_x1000=serial * 1000 // (3 * parallel),
               serial_gain_x1000=totals['reference', 'serial'] * 1000 // serial,
               parallel_gain_x1000=totals['reference', 'parallel'] * 1000 // parallel,
               frames_per_executor=12))
        aggregate.append(dict(profile=p, serial_cycles=serial, parallel_cycles=parallel,
                              parallel_speedup=serial / parallel,
                              parallel_efficiency=serial / (3 * parallel),
                              serial_gain=totals['reference', 'serial'] / serial,
                              parallel_gain=totals['reference', 'parallel'] / parallel,
                              online_pack_serial_cycles=sum(result[p, 'serial', 0, r]['pack_cycles'] for r in range(4)),
                              online_pack_parallel_cycles=sum(result[p, 'parallel', 0, r]['pack_cycles'] for r in range(4))))
    return dict(status='PASS', scope='first_conv_only_not_full_model', prior_sessions_ignored=len(starts)-1,
                measured_records=24, warmup_records=6, compared_output_bytes=30 * 3686400,
                aggregate=aggregate, records=[dict(kind=k, **v) for k, v in records])


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('log', type=Path)
    parser.add_argument('--out', type=Path, default=Path('build/reports/first_layer_s2d'))
    args = parser.parse_args()
    raw = args.log.read_bytes()
    try:
        report = parse(raw.decode('utf-8', errors='replace'))
    except (ValueError, KeyError) as exc:
        parser.exit(1, 'S2D_LOG_FAIL: ' + str(exc) + '\n')
    report.update(source=str(args.log), sha256=hashlib.sha256(raw).hexdigest())
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.with_suffix('.json').write_text(json.dumps(report, indent=2) + '\n')
    lines = ['PASS: 仅首层，三张真实输入，完整输出逐字节一致；warmup排除。',
             '每项周期对应12帧；parallel speedup=串行/三路并行；gain=同执行方式reference/候选。',
             'profile          serial_cycles parallel_cycles parallel_x serial_gain parallel_gain efficiency']
    for row in report['aggregate']:
        lines.append(f'{row["profile"]:16} {row["serial_cycles"]:13} {row["parallel_cycles"]:15} '
                     f'{row["parallel_speedup"]:10.4f} {row["serial_gain"]:11.4f} '
                     f'{row["parallel_gain"]:13.4f} {row["parallel_efficiency"]:9.2%}')
    lines += ['prepacked不包含输入重排；rvv_online包含全部重排，并行时CPU重排与已启动卷积可重叠。',
              '4MiB eviction为统一缓存压力，不能保证所有行均冷；此结果不代表整网加速比。']
    summary = '\n'.join(lines) + '\n'
    args.out.with_suffix('.txt').write_text(summary)
    print(summary, end='')


if __name__ == '__main__':
    main()
