#!/usr/bin/env bash
set -euo pipefail
project_root=$(cd "$(dirname "$0")/../.." && pwd)
python3 - "$project_root" <<'PY'
from pathlib import Path
import importlib.util
import sys

spec = importlib.util.spec_from_file_location(
    'elf_audit', Path(sys.argv[1]) / 'tools/check/check_v17a_firmware.py')
audit = importlib.util.module_from_spec(spec)
spec.loader.exec_module(audit)
root = 'ai_ppu_queue_submit'
device = 'ai_ppu_device_queue_submit_ready'
functions = {root: f'j 123 <{device}>', device: 'jal 234 <yolo32_ppu_io_barrier>'}
audit.check_ppu_ordering(functions, root)
audit.check_ppu_ordering({root: 'jal 234 <yolo32_ppu_io_barrier>'}, root)
for bad_body in ('ret', 'fence iorw,iorw\njal 234 <yolo32_ppu_io_barrier>'):
    try:
        audit.check_ppu_ordering({root: f'j 123 <{device}>', device: bad_body}, root)
    except RuntimeError:
        pass
    else:
        raise AssertionError('adapter concealed a broken device ordering contract')
print('V17A_ELF_ADAPTER_AUDIT=PASS inline nested_tail_call missing_barrier nested_global_fence')
PY
