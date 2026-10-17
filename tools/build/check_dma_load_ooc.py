#!/usr/bin/env python3
"""Place/route all runtime paths of the candidate's DMA modules at 100MHz."""
import argparse
import importlib.util
import json
import re
import sys
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT/'tools/soc'))
spec = importlib.util.spec_from_file_location('dma_candidate', ROOT/'tools/soc/dma_load_candidate.py')
candidate = importlib.util.module_from_spec(spec)
spec.loader.exec_module(candidate)


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--context', type=Path, required=True)
    p.add_argument('--output', type=Path, required=True)
    p.add_argument('--vivado', default='/mnt/data/Vivado/Vivado/2023.2/bin/vivado')
    args = p.parse_args()
    context, rtl = candidate.validate(args.context)
    out = args.output.resolve()
    out.mkdir(parents=True, exist_ok=False)
    results = []
    for top in ('DmaLoadGroup', 'DmaLoadRowAssembler', 'StreamReader'):
        dest = out/top
        dest.mkdir()
        sources = candidate.closure(rtl, [top])
        tcl = ['set_param general.maxThreads 4',
               'read_verilog -sv [list '+' '.join('{'+str(f)+'}' for f in sources)+']',
               f'synth_design -mode out_of_context -top {top} -part xcvu13p-fhga2104-2-i',
               'create_clock -name dma_clk -period 10.0 [get_ports clock]',
               'set_input_delay 1.0 -clock dma_clk [get_ports -filter {DIRECTION == IN && NAME != clock}]',
               'set_output_delay 1.0 -clock dma_clk [all_outputs]',
               'opt_design', 'place_design', 'route_design',
               'report_timing_summary -file timing.rpt',
               'report_utilization -file utilization.rpt',
               'check_timing -verbose -file check_timing.rpt',
               'set fd [open result.txt w]',
               'set path [get_timing_paths -delay_type max -max_paths 1]',
               'if {[llength $path] != 1} {error "No constrained timing path"}',
               'set slack [get_property SLACK $path]',
               'puts $fd "WNS_NS=$slack"', 'close $fd',
               'if {$slack < 0} {error "DMA OOC setup timing failed"}',
               'set hold [get_timing_paths -delay_type min -max_paths 1]',
               'if {[llength $hold] != 1 || [get_property SLACK $hold] < 0} {error "DMA OOC hold timing failed"}']
        script = dest/'run.tcl'
        script.write_text('\n'.join(tcl)+'\n')
        with (dest/'console.log').open('w') as log:
            subprocess.run([args.vivado,'-mode','batch','-source',str(script)], cwd=dest,
                           stdout=log,stderr=subprocess.STDOUT,check=True)
        values = dict(line.split('=',1) for line in (dest/'result.txt').read_text().splitlines())
        summary=(dest/'timing.rpt').read_text().split('Design Timing Summary',1)[1]
        match=re.search(r'^\s*(-?\d+\.\d+)\s+(-?\d+\.\d+)\s+(\d+)\s+(\d+)\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)\s+(\d+)\s+(\d+)\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)\s+(\d+)\s+(\d+)\s*$',summary,re.M)
        if not match or any(int(match[i]) for i in (3,7,11)) or any(float(match[i])<0 for i in (1,5,9)):
            raise SystemExit('OOC setup/hold/pulse timing failed: '+str(dest/'timing.rpt'))
        results.append(dict(top=top,wns_ns=float(values['WNS_NS']),whs_ns=float(match[5]),wpws_ns=float(match[9]),
                            timing_report_sha256=candidate.sha(dest/'timing.rpt'),
                            rtl_sha256={str(f):candidate.sha(f) for f in sources}))
        print('DMA_LOAD_OOC_PASS top='+top+' wns='+values['WNS_NS'],flush=True)
    candidate.validate(args.context)
    (out/'evidence.json').write_text(json.dumps(dict(status='OOC_PASS',full_chip_timing_proven=False,
        build_id=context['dma_load_build_id'],results=results),indent=2)+'\n')


if __name__ == '__main__':
    main()
