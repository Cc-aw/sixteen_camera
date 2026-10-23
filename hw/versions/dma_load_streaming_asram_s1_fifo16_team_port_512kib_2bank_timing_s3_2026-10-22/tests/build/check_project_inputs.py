#!/usr/bin/env python3
"""Verify the actual reconstruction list contains the frozen board RTL closure."""
import argparse
import json
from pathlib import Path
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[2]


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--generated',type=Path,required=True)
    parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args();out=args.output.resolve()
    if ROOT/'build' not in out.parents or out.exists():raise ValueError('Use a fresh candidate build output')
    subprocess.run([sys.executable,str(ROOT/'scripts/project_inputs.py'),'--generated',
        str(args.generated.resolve()),'--output',str(out)],check=True)
    text=(out/'version_inputs.tcl').read_text()
    production=[p for p in (ROOT/'board/rtl').rglob('*')
        if p.suffix in ('.v','.sv','.vh','.svh','.vhd','.vhdl')]
    for path in production:
        if text.count('{'+str(path)+'}')!=1:raise ValueError('Missing/duplicate board input: '+str(path))
    bridge=ROOT/'board/rtl/memory/tensor_coherent_write_cdc.sv'
    if bridge not in production or 'module tensor_coherent_write_cdc' not in bridge.read_text():
        raise ValueError('Expected production tensor CDC module')
    result=dict(status='PASS',board_rtl_files=len(production),all_listed_once=True,
        tensor_coherent_write_cdc=True,selected_hardware=json.loads((out/'selected_hardware.json').read_text()))
    (out/'evidence.json').write_text(json.dumps(result,indent=2)+'\n')
    print('BOARD_RTL_PROJECT_CLOSURE_PASS',len(production),flush=True)


if __name__=='__main__':main()
