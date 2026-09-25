#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
test_tmp="${PPU_TEST_CACHE:-$root/build/ppu_phase2/cache}/queue"
mkdir -p "$test_tmp"
iverilog -g2012 -s tb_ppu_descriptor_fifo -o "$test_tmp/descriptor" \
 "$root/rtl/ai/postprocess/ppu_descriptor_fifo.sv" \
 "$root/rtl/ai/postprocess/ppu_command_queue.sv" "$root/sim/tb_ppu_descriptor_fifo.sv"
vvp "$test_tmp/descriptor"
iverilog -g2012 -s tb_ppu_result_fifo -o "$test_tmp/result" \
 "$root/rtl/ai/postprocess/ppu_descriptor_fifo.sv" \
 "$root/rtl/ai/postprocess/ppu_result_capture.sv" "$root/rtl/ai/postprocess/ppu_result_fifo.sv" \
 "$root/rtl/ai/postprocess/ppu_overlay_label.sv" "$root/rtl/ai/postprocess/ppu_result_manager.sv" \
 "$root/rtl/ai/postprocess/ppu_result_csr.sv" "$root/rtl/ai/postprocess/ppu_result_path.sv" \
 "$root/sim/tb_ppu_result_fifo.sv"
vvp "$test_tmp/result"
python3 - "$root" "$test_tmp/labels.hex" <<'PY'
from pathlib import Path
import sys,re
root=Path(sys.argv[1])
s=(root/'sw/src/ai_class_names.c').read_text().split('coco_names[80] = {',1)[1].split('};',1)[0]
names=re.findall(r'"([^"]+)"',s)+['unknown']
with open(sys.argv[2],'w') as f:
 for score in range(65536):
  label=(names[score%81]+' '+str(min(100,(score*100+16384)>>15))+'%').encode()[:16].ljust(16,b'\0')
  f.write(f'{int.from_bytes(label,"little"):032x}\n')
PY
iverilog -g2012 -s tb_ppu_overlay_label -o "$test_tmp/label" \
 "$root/rtl/ai/postprocess/ppu_overlay_label.sv" "$root/sim/tb_ppu_overlay_label.sv"
vvp "$test_tmp/label" "+GOLDEN=$test_tmp/labels.hex"
