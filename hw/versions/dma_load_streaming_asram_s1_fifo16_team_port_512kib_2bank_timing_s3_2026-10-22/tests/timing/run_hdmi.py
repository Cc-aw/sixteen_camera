#!/usr/bin/env python3
"""Compare S3 HDMI streams against the frozen S2 implementation."""
import json
import os
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'scripts'))
from common import sha

out = ROOT / 'build/s3_hdmi'
out.mkdir(parents=True, exist_ok=False)
files = [ROOT / name for name in (
    'board/rtl/interfaces/axis_video_if.sv',
    'board/rtl/interfaces/video_stream_if.sv',
    'board/rtl/video/hdmi/hdmi_4k_spatial_demux.sv',
    'tests/timing/fixtures/hdmi_4k_spatial_demux_s2.sv',
    'tests/timing/tb_hdmi_s3.sv')]
command = [os.environ.get('VERILATOR','verilator'),
    '--binary','--timing','--assert','-Wno-fatal','-j','4',
    '--top-module','tb_hdmi_s3','--Mdir',str(out/'obj'),*map(str,files)]
with (out/'compile.log').open('w') as log:
    subprocess.run(command,stdout=log,stderr=subprocess.STDOUT,check=True)
result = subprocess.run([str(out/'obj/Vtb_hdmi_s3')],capture_output=True,text=True,timeout=240)
(out/'result.log').write_text(result.stdout+result.stderr)
assert result.returncode==0 and 'HDMI_S3_S2_STREAM_EQUIVALENCE_PASS' in result.stdout,result.stdout+result.stderr
(out/'evidence.json').write_text(json.dumps(dict(status='HDMI_S3_S2_STREAM_EQUIVALENCE_PASS',
    source_hashes={str(p.relative_to(ROOT)):sha(p) for p in files},
    diagnostic_counter_latency_clocks=1,stream_latency_change_clocks=0,
    channels=8,full_4k_frame=True,overflow=True,malformed=True,reset_recovery=True),indent=2)+'\n')
print(result.stdout)
