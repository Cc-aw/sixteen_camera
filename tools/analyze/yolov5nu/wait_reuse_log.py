from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[3] / "sw/models/yolov5nu/codegen"))
"""Validate static WS/caller wait reuse independently of PPU overlap."""
from check_log import number
from wait_reuse import SITES_PER_WORKER, BASELINE_WAITS

FIELDS = {'sites_per_worker', 'merged0', 'merged1', 'merged2',
          'fallback0', 'fallback1', 'fallback2'}


def validate(run):
    record = run.get('wait_reuse_stats')
    if not run.get('wait_reuse') or run['mode'] != 'independent':
        if record is not None:
            raise ValueError('wait reuse record outside enabled independent run')
        return
    if record is None or set(record) != FIELDS:
        raise ValueError('missing/incomplete wait reuse record')
    if number(record, 'sites_per_worker') != SITES_PER_WORKER:
        raise ValueError('wait reuse site count differs from generated graph')
    if any(number(record, f'merged{w}') != SITES_PER_WORKER or
           number(record, f'fallback{w}') != 0 for w in range(3)):
        raise ValueError('wait reuse sites not all proven or unexpected fallback')
    extra = 0
    if run.get('memory_ops'):
        from memory_kernels import expected_counts
        extra = 3*expected_counts(run.get('resize_batch',0),run.get('resize_rows',0))['waits']
    if number(run['policy'], 'wait_yields') + 3*SITES_PER_WORKER != BASELINE_WAITS + extra:
        raise ValueError('wait handoffs plus reused sites differ from native graph')


def report(runs):
    for run in runs:
        if run.get('wait_reuse') and run['mode'] == 'independent' and run['analysis']:
            print(f"run={run['id']} reused WS/caller waits={3*SITES_PER_WORKER}; "
                  f"actual wait handoffs={number(run['policy'], 'wait_yields')}; "
                  'original helper DMA/retirement wait retained')
