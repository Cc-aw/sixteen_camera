#!/usr/bin/env python3
"""Freeze a phase's RTL before invoking the standalone Vivado timing gate."""
from pathlib import Path
import argparse, hashlib, shutil, subprocess
root=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser()
p.add_argument('phase')
p.add_argument('--period',type=float,default=10.0)
p.add_argument('--script',default='scripts/check_yolov5nu_postprocess_synthesis.tcl')
a=p.parse_args()
if not a.phase.replace('_','').replace('-','').isalnum(): p.error('invalid phase name')
out=root/'build/ppu_phase2'/a.phase
out.mkdir(parents=True,exist_ok=True)
src=out/'rtl/ai/postprocess'
shutil.copytree(root/'rtl/ai/postprocess',src,dirs_exist_ok=True)
shutil.copytree(root/'rtl/interfaces',out/'rtl/interfaces',dirs_exist_ok=True)
(out/'sim').mkdir(exist_ok=True)
for harness in (root/'sim').glob('*synthesis_top.sv'): shutil.copy2(harness,out/'sim'/harness.name)
tcl=(root/a.script).read_text()
tcl=tcl.replace(tcl.splitlines()[0],f'set root {{{out}}}')
tcl=tcl.replace('-period 10.000',f'-period {a.period:.3f}')
tcl=tcl.replace('100 MHz',f'{1000/a.period:.3f} MHz')
(out/'synth.tcl').write_text(tcl)
(out/'sources.sha256').write_text(''.join(f'{hashlib.sha256(f.read_bytes()).hexdigest()}  {f.name}\n' for f in sorted(src.glob('*.sv'))))
with (out/'synth.console').open('w') as log:
    r=subprocess.run(['/mnt/data/Vivado/Vivado/2023.2/bin/vivado','-mode','batch','-nojournal','-log',str(out/'synth.log'),'-source',str(out/'synth.tcl')],cwd=out,stdout=log,stderr=subprocess.STDOUT)
text=(out/'synth.console').read_text()
if r.returncode or '\nYOLOV5NU_POSTPROCESS_SYNTHESIS=PASS\n' not in text:
    raise SystemExit(f'{a.phase}: synthesis failed; see {out}/synth.console')
print(f'{a.phase}: SYNTHESIS=PASS period={a.period}ns log={out}/synth.console')
