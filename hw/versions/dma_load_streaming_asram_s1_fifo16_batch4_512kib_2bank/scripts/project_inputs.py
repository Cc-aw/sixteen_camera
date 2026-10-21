#!/usr/bin/env python3
"""Materialize frozen IP configuration into a private project output directory."""
import argparse
import json
from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[1]

def q(value):
    value=str(value)
    if any(c in value for c in '{}\n\r'):raise ValueError('Unsupported Tcl path')
    return '{'+value+'}'


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
    out=a.output.resolve()
    if (ROOT/'build').resolve() not in out.parents:raise ValueError('Project output must be below this version build/')
    out.mkdir(parents=True,exist_ok=True)
    lines=[]
    text=(ROOT/'manifests/donor/rtl_manifest.tcl').read_text()
    # Include entries appended on the same line as `lappend RTL_SOURCES`.
    # The three memory-performance modules are required by the DDR subsystem.
    files=[ROOT/'board'/name for name in re.findall(r'(?<!\S)(rtl/[^\s}]+)',text)]
    files += [f for f in (ROOT/'generated/gen-collateral').rglob('*') if f.suffix in ('.v','.sv','.vh','.svh','.vhd','.vhdl','.mem','.mif')]
    for f in files:
        if not f.is_file():raise ValueError('Missing project input: '+str(f))
    lines.append('add_files -fileset sources_1 -norecurse [list '+ ' '.join(q(f) for f in files)+']')
    for path in sorted((ROOT/'board/ip/config').glob('*.json')):
        x=json.loads(path.read_text());name=x['ip_inst']['xci_name']
        destination=out/'ip_config'/name/(name+'.xci');destination.parent.mkdir(parents=True,exist_ok=True)
        x['ip_inst']['gen_directory']='../../ip_output/'+name
        # Runtime output paths are local; parameter values and VLNV stay frozen.
        destination.write_text(json.dumps(x,indent=2)+'\n')
        lines.append('read_ip '+q(destination))
    text=(ROOT/'manifests/donor/xdc_manifest.tcl').read_text()
    for name in re.findall(r'^\s*(xdc/[^\s}]+)',text,re.M):
        f=ROOT/'board'/name
        if not f.is_file():raise ValueError('Missing XDC: '+str(f))
        lines.append('add_files -fileset constrs_1 -norecurse '+q(f))
    (out/'version_inputs.tcl').write_text('\n'.join(lines)+'\n')
    print('S1_PROJECT_INPUTS_LOCAL files='+str(len(files)))

if __name__=='__main__':main()
