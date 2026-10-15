"""Validate the hardware-only PPU schema while reusing common run checks."""
from check_log import fields, number


def parse_hardware(text):
    from analyze_log import parse
    lines, errors, extras = [], [], []
    active = None
    for raw in text.splitlines():
        line = raw.strip()
        try:
            if line.startswith('YOLO32_BEGIN '):
                r = fields(line)
                if r.get('postprocess') != 'hardware':
                    raise ValueError('cannot mix CPU and hardware runs')
                active = {'core': {}, 'total': None}
                extras.append(active)
                lines.append(line.replace(' postprocess=hardware', ''))
            elif active is not None and line.startswith('YOLO32_WORKER '):
                r = fields(line)
                allowed = {'worker', 'image', 'raw_fnv', 'ppu_fnv', 'detections', 'ppu_core_cycles', 'ppu_wall_cycles', 'cycles'}
                if set(r) != allowed:
                    raise ValueError('invalid hardware result fields or CPU postprocessing record')
                w = number(r, 'worker')
                core, wall = number(r, 'ppu_core_cycles'), number(r, 'ppu_wall_cycles')
                if not 0 < core < 2**32 or not 0 < wall < 2**64:
                    raise ValueError('missing PPU core/wall timing')
                active['core'][w] = core
                # Common validator compares these signatures against the serial
                # reference for this image. They encode raw heads and PPU words.
                lines.append(f"YOLO32_WORKER worker={r['worker']} image={r['image']} raw_fnv={r['raw_fnv']} "
                    f"mask_fnv={r['ppu_fnv']} logits_sum=0 logits_fnv=0 scores_sum=0 scores_fnv=0 dfl_sum=0 dfl_fnv=0 "
                    f"candidates=0 detections={r['detections']} cycles={r['cycles']}")
            elif active is not None and line.startswith('YOLO32_DETECTION '):
                r = fields(line)
                if set(r) != {'worker', 'index', 'xy0', 'xy1', 'score_class', 'word3'}:
                    raise ValueError('invalid hardware detection fields')
                words = [number(r, k) for k in ('xy0', 'xy1', 'score_class', 'word3')]
                if any(v < 0 or v >= 2**32 for v in words):
                    raise ValueError('invalid PPU result word')
                cls = (words[2] >> 16) & 127
                lines.append(f"YOLO32_DETECTION worker={r['worker']} index={r['index']} class={cls} "
                    f"score={words[2]} cx={words[0]} cy={words[1]} width={words[3]} height=0")
            elif active is not None and line.startswith('YOLO32_TIMING '):
                r = fields(line)
                if set(r) != {'batch_cycles', 'graph_cycles', 'ppu_tail_cycles', 'ppu_core_cycles'}:
                    raise ValueError('invalid timing fields or CPU post_cycles present')
                active['total'] = number(r, 'ppu_core_cycles')
                lines.append(f"YOLO32_TIMING batch_cycles={r['batch_cycles']} graph_cycles={r['graph_cycles']} post_cycles={r['ppu_tail_cycles']}")
            else:
                lines.append(line)
            if line.startswith('YOLO32_RESULT '):
                if active is not None and (set(active['core']) != {0, 1, 2} or active['total'] != sum(active['core'].values())):
                    raise ValueError('missing PPU timings or aggregate core cycles mismatch')
                active = None
        except (KeyError, ValueError) as e:
            errors.append(f'malformed hardware log line: {line}: {e}')
            # Preserve the malformed source so common validation also rejects
            # missing records rather than treating them as successful runs.
            # Remove the hardware dispatch marker even on a malformed BEGIN;
            # otherwise the common parser dispatches back here recursively.
            lines.append(line.replace(' postprocess=hardware','') if line.startswith('YOLO32_BEGIN ') else line)
    common_errors, runs = parse('\n'.join(lines))
    for run, extra in zip(runs, extras):
        run['hardware'] = True
        run['ppu_core'] = extra['total']
    return errors + common_errors, runs
