#!/usr/bin/env python3
"""Read-only Tcl source selection for merged/parent and rejection paths."""
import argparse
from pathlib import Path
import subprocess
import tempfile

FEATURE=Path(__file__).resolve().parents[1]
ROOT=FEATURE.parents[2]


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--context',type=Path,required=True)
    args=p.parse_args()
    prefix=f'''set root {{{ROOT}}}
set ::env(ASRAM_CANDIDATE_CONTEXT) {{{args.context.resolve()}}}
set ::env(VIVADO_PROJECT) [file join $root build experiments dma_stream_asram fixture new.xpr]
unset -nocomplain ::env(DMA_LOAD_CANDIDATE_CONTEXT) ::env(SOC_CONFIG) ::env(SOC_VARIANT)
'''
    with tempfile.TemporaryDirectory(prefix='stream-asram-manifest-') as directory:
        script=Path(directory)/'selection.tcl'
        for variant,ok in ((FEATURE.name,True),('unknown',False)):
            script.write_text(prefix+f'set ::env(ASRAM_FEATURE_VARIANT) {variant}\n'+
                'source [file join $root hw manifests soc_manifest.tcl]\n'+
                f'if {{$SOC_VARIANT ne "{FEATURE.name}" || !$SOC_ASRAM_PRIVATE || $SOC_ASRAM_EXPERIMENT ne "dma_stream_asram"}} {{error "Wrong selection"}}\n'+
                'puts "MERGED_MANIFEST_SELECTION=PASS"\n')
            result=subprocess.run(['tclsh',str(script)],capture_output=True,text=True)
            assert (result.returncode==0)==ok,result.stdout+result.stderr
        script.write_text(prefix+f'set ::env(ASRAM_FEATURE_VARIANT) {FEATURE.name}\n'+
            'set ::env(VIVADO_PROJECT) [file join $root hw vivado production.xpr]\n'+
            'source [file join $root hw manifests soc_manifest.tcl]\n')
        result=subprocess.run(['tclsh',str(script)],capture_output=True,text=True)
        assert result.returncode!=0 and 'private project' in result.stderr
    print('MERGED_MANIFEST_SELECTION=PASS unknown_variant=reject production_project=reject board_accessed=0')


if __name__=='__main__':main()
