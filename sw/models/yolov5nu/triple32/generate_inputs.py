#!/usr/bin/env python3
"""Extract only the already quantized inputs; never duplicate model weights."""
import hashlib
import json
from pathlib import Path
import re
import sys

HERE = Path(__file__).resolve().parent
SOURCE = HERE.parents[3] / 'tests/data/yolov5nu/v17a'
IMAGES = ('025', '036', '142')
INPUT_BYTES = 640 * 480 * 3


def extract(path):
    text = path.read_text()
    match = re.search(r'\byolov5nu_input\[[^]]+\][^{=]*=\s*\{([^}]+)\}', text)
    if not match:
        raise ValueError(f'{path}: missing input array')
    body = match[1]
    if re.sub(r'-?\d+|[\s,]', '', body):
        raise ValueError(f'{path}: input must contain literal integers')
    values = [int(v) for v in re.findall(r'-?\d+', body)]
    if len(values) != INPUT_BYTES or any(v < -128 or v > 127 for v in values):
        raise ValueError(f'{path}: invalid NHWC INT8 input')
    return bytes(v & 255 for v in values)


def generate(out):
    out.mkdir(parents=True, exist_ok=True)
    rows, manifest = [], []
    for image in IMAGES:
        path = SOURCE / f'image{image}.bin'
        raw = path.read_bytes()
        if len(raw) != INPUT_BYTES:
            raise ValueError(f'{path}: invalid input length')
        manifest.append({'image': image, 'bytes': len(raw),
                         'sha256': hashlib.sha256(raw).hexdigest(),
                         'source': str(path.relative_to(HERE.parents[3]))})
        values = [str(v if v < 128 else v - 256) for v in raw]
        rows.append('{\n' + '\n'.join(','.join(values[i:i+32]) + ','
                                     for i in range(0, len(values), 32)) + '\n}')
    if len({m['sha256'] for m in manifest}) != 3:
        raise ValueError('The three test images must differ')
    (out / 'inputs.h').write_text(
        '#ifndef YOLO32_INPUTS_H\n#define YOLO32_INPUTS_H\n#include <stdint.h>\n'
        '#define YOLO32_INPUT_BYTES (640U * 480U * 3U)\n'
        'extern const int8_t yolo32_inputs[3][YOLO32_INPUT_BYTES];\n'
        'extern const char *const yolo32_image_ids[3];\n#endif\n')
    (out / 'inputs.c').write_text('#include "inputs.h"\n'
        'const int8_t yolo32_inputs[3][YOLO32_INPUT_BYTES] __attribute__((aligned(64))) = {\n'
        + ',\n'.join(rows) + '\n};\n'
        'const char *const yolo32_image_ids[3] = {"025", "036", "142"};\n')
    (out / 'inputs_manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print('Generated three independent INT8 inputs: 025, 036, 142')


if __name__ == '__main__':
    generate(Path(sys.argv[1]))
