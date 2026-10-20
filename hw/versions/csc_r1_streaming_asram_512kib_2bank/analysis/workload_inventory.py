#!/usr/bin/env python3
"""Inventory native frozen packets without interpreting payload as RTL traffic."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT / 'sw/benchmarks/frontend/scripts'))
from parallel_cache_plan import regenerate, semantic, spans


def inventory(model, out):
    out.mkdir(parents=True, exist_ok=False)
    package = model.parent
    lock = json.loads((model / 'sources.lock.json').read_text())
    for item in lock['sources']:
        path = package / item['path']
        if hashlib.sha256(path.read_bytes()).hexdigest() != item['sha256']:
            raise ValueError('Frozen source mismatch: ' + str(path))
    frozen = json.loads((model / 'fixed_plans.json').read_text())
    requests = [(int(stage), 0, semantic(plan), frozen['ordinary'][stage]['tile'])
                for stage, plan in sorted(frozen['fixed_packets'].items(), key=lambda x: int(x[0]))]
    packed, capacities = regenerate(model, requests, out)
    stages = []
    for stage, _, shape, tile in requests:
        original = frozen['fixed_packets'][str(stage)]
        if packed.get((stage, 0)) != original:
            raise ValueError(f'Native roundtrip mismatch: stage {stage}')
        packets = original['tiles']
        payload = {role: sum(size for p in packets for _, size in spans(shape, p, role))
                   for role in ('input', 'weight', 'bias', 'output')}
        stages.append(dict(stage_id=stage, shape=shape, tile=tile, packets=len(packets),
                           capacity=capacities[stage, 0], native_logical_payload_bytes=payload,
                           retained_input_packets=sum(p['offsets'][3] == 0xffffffff for p in packets),
                           retained_weight_packets=sum(p['offsets'][0] == 0xffffffff for p in packets)))
    prepared = [dict(stage_id=int(stage), helper=plan['helper'], packets=plan['packets'],
                     step_kind_counts={str(kind): sum(step[0] == kind for step in plan['steps'])
                                       for kind in sorted({s[0] for s in plan['steps']})})
                for stage, plan in sorted(frozen['prepared_ws'].items(), key=lambda x: int(x[0]))]
    all_stages = sorted(set(map(int, re.findall(r'case (\d+)U:', (model / 'parallel_model.inc').read_text()))))
    result = dict(schema=1, status='NATIVE_ORDINARY_PACKET_ROUNDTRIP_PASS',
                  full_network_dynamic_trace=False, full_network_cycle_weights_available=False,
                  metric='Native logical payload only; excludes physical Get alignment, zero writes and timing',
                  ordinary_stage_count=len(stages), ordinary_packets_per_worker=sum(s['packets'] for s in stages),
                  prepared_stage_count=len(prepared), prepared_packets_per_worker=sum(s['packets'] for s in prepared),
                  model_stage_ids=all_stages, ordinary=stages, prepared=prepared,
                  untraced_boundaries='Prepared WS, HOST/PAD, frame epochs, Head/PPU and full-size execution',
                  sources_sha256={str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest()
                                  for p in sorted(model.rglob('*')) if p.is_file()})
    (out / 'inventory.json').write_text(json.dumps(result, indent=2) + '\n')
    print(result['status'], 'stages=', len(stages), 'packets=', result['ordinary_packets_per_worker'])
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--model', type=Path, default=ROOT / 'sw/board_tests/dma_load_streaming_asram_512kib_2bank/model')
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    inventory(args.model.resolve(), args.output.resolve())
