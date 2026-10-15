#!/usr/bin/env python3
"""Validate captured YOLO32 runs using worker 0, without historical goldens."""
import argparse
from pathlib import Path

SIGNATURES = ("raw_fnv", "mask_fnv", "logits_sum", "logits_fnv", "scores_sum",
              "scores_fnv", "dfl_sum", "dfl_fnv", "candidates", "detections")
DETECTION_FIELDS = ("class", "score", "cx", "cy", "width", "height")


def fields(line):
    result = {}
    for token in line.split()[1:]:
        key, separator, value = token.partition("=")
        if not separator or not key or key in result:
            raise ValueError(f"invalid field: {token}")
        result[key] = value
    return result


def number(record, key):
    value = record[key]
    return int(value, 16 if value.lower().startswith("0x") else 10)


def validate(text):
    if any(line.strip().startswith('YOLO32_BEGIN ') and 'images=' in line
           for line in text.splitlines()):
        from analyze_log import parse
        return parse(text)[0]
    errors = []
    active = None
    completed = 0

    def check_run(run, ending):
        prefix = f"run {run['id']}: "
        if ending != "YOLO32_RESULT PASS workers=bit_exact reference=worker0":
            errors.append(prefix + "missing consistency PASS or firmware reported FAIL")
        if run['mode'] == 'parallel':
            try:
                record = run['parallel']
                groups = number(record, 'tile_groups')
                overlaps = number(record, 'overlap_samples')
                triples = number(record, 'triple_overlap_samples')
                if (number(record, 'conv_groups') != 58 or groups <= 0
                        or any(number(record, f'requests{w}') != groups for w in range(3))
                        or not 0 < triples <= overlaps or number(record, 'busy_mask_seen') != 7
                        or run['parallel_result'] != 'YOLO32_PARALLEL_RESULT PASS'):
                    errors.append(prefix + 'invalid three-worker parallel evidence')
            except (KeyError, TypeError, ValueError) as error:
                errors.append(prefix + f'missing or malformed parallel evidence: {error}')
        if set(run["workers"]) != {0, 1, 2}:
            errors.append(prefix + "requires exactly workers 0, 1, 2")
            return
        for worker, record in run["workers"].items():
            try:
                values = {k: number(record, k) for k in SIGNATURES}
                cycles = number(record, "cycles")
                if cycles <= 0 or not 0 <= values["detections"] <= 10 or not 0 <= values["candidates"] <= 6300:
                    raise ValueError("invalid cycles or counts")
                for key in SIGNATURES:
                    if key not in ("candidates", "detections") and not 0 <= values[key] < (1 << 64):
                        raise ValueError(f"invalid {key}")
                baseline = run["workers"][0]
                if any(values[k] != number(baseline, k) for k in SIGNATURES):
                    errors.append(prefix + f"worker {worker} signature differs from worker 0")
                detections = run["detections"].get(worker, {})
                if set(detections) != set(range(values["detections"])):
                    errors.append(prefix + f"worker {worker} missing or extra detections")
                for index, detection in detections.items():
                    numeric = tuple(number(detection, k) for k in DETECTION_FIELDS)
                    if not 0 <= numeric[0] < 80 or any(not 0 <= v < (1 << 32) for v in numeric[1:]):
                        raise ValueError("invalid detection")
                    other = run["detections"].get(0, {}).get(index)
                    if other is None or numeric != tuple(number(other, k) for k in DETECTION_FIELDS):
                        errors.append(prefix + f"worker {worker} detection {index} differs")
            except (KeyError, ValueError) as error:
                errors.append(prefix + f"worker {worker} malformed record: {error}")
        if set(run["comparisons"]) != {1, 2}:
            errors.append(prefix + "missing byte comparisons for workers 1 and 2")
        for worker, record in run["comparisons"].items():
            try:
                if (number(record, "reference") != 0 or number(record, "mismatches") != 0
                        or record["first"] != "none" or number(record, "index") != 0):
                    errors.append(prefix + f"worker {worker} byte comparison failed")
            except (KeyError, ValueError) as error:
                errors.append(prefix + f"malformed comparison: {error}")

    for line in text.splitlines():
        line = line.strip()
        try:
            if line.startswith("YOLO32_BEGIN "):
                if active is not None:
                    errors.append(f"run {active['id']}: incomplete before next run")
                record = fields(line)
                active = {"id": number(record, "run"), "mode": record['mode'],
                          "workers": {}, "detections": {}, "comparisons": {}}
                if (record["image"] != "025" or number(record, "dim") != 32
                        or number(record, "workers") != 3 or record["reference"] != "worker0"
                        or record["mode"] not in ("forward", "reverse", "interleaved", "parallel")):
                    errors.append("invalid run configuration")
            elif active is not None and line.startswith('YOLO32_PARALLEL '):
                if 'parallel' in active:
                    raise ValueError('duplicate parallel evidence')
                active['parallel'] = fields(line)
            elif active is not None and line.startswith('YOLO32_PARALLEL_RESULT '):
                if 'parallel_result' in active:
                    raise ValueError('duplicate parallel result')
                active['parallel_result'] = line
            elif line.startswith("YOLO32_RESULT "):
                if active is not None:
                    check_run(active, line)
                    completed += 1
                    active = None
                else:
                    errors.append("result marker without an active three-worker run")
            elif active is not None and line.startswith(("YOLO32_WORKER ", "YOLO32_DETECTION ", "YOLO32_COMPARE ")):
                record = fields(line)
                worker = number(record, "worker")
                kind = line.split()[0]
                allowed = {1, 2} if kind == "YOLO32_COMPARE" else {0, 1, 2}
                if worker not in allowed:
                    raise ValueError("invalid worker id")
                if kind == "YOLO32_DETECTION":
                    target = active["detections"].setdefault(worker, {})
                    key = number(record, "index")
                else:
                    target = active["workers" if kind == "YOLO32_WORKER" else "comparisons"]
                    key = worker
                if key in target:
                    raise ValueError("duplicate record")
                target[key] = record
        except (KeyError, ValueError) as error:
            errors.append(f"malformed log line: {line}: {error}")
    if active is not None:
        errors.append(f"run {active['id']}: incomplete UART log")
    if not completed:
        errors.append("no complete three-worker run")
    return errors


def latest_session(text):
    lines=text.splitlines(keepends=True)
    boots=[i for i,line in enumerate(lines) if line.strip().startswith('YOLO32_FIRMWARE ')]
    return ''.join(lines[boots[-1]:]) if boots else text


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("log", type=Path, help="saved UART log; does not access UART")
    parser.add_argument('--latest',action='store_true',help='check only the last firmware boot session')
    args = parser.parse_args()
    text=args.log.read_text(errors="replace")
    errors = validate(latest_session(text) if args.latest else text)
    for error in errors:
        print(f"FAIL: {error}")
    print("YOLO32_LOG_CHECK=" + ("FAIL" if errors else "PASS"))
    return bool(errors)


if __name__ == "__main__":
    raise SystemExit(main())
