#!/usr/bin/env python3
"""Bind firmware to audited merged RTL; no bitstream or board is required."""
import argparse
import hashlib
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
REPO=ROOT.parents[2]


def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--context',type=Path,required=True)
    args=p.parse_args();path=args.context.resolve();c=json.loads(path.read_text())
    if (c.get('hardware_variant')!=ROOT.name or not c.get('activation_sram_enabled') or
            not c.get('dma_load_streaming_enable') or c.get('dma_load_pipeline_version')!='row_ready_v1' or
            c.get('l2_banks')!=2 or c.get('l2_capacity_kib')!=512):
        raise ValueError('Expected merged streaming + ASRAM 512 KiB / 2 bank candidate')
    rtl=path.parent/'gen-collateral'
    for name,digest in c['final_rtl_sha256'].items():
        if sha(rtl/name)!=digest:raise ValueError('RTL changed: '+name)
    header=next((rtl/'include').glob('*custom0*.h'))
    if header.read_bytes()!=(ROOT/'hardware/gemmini_params_custom0.h').read_bytes():
        raise ValueError('Generated Gemmini parameter header differs')
    old=json.loads((ROOT/'hardware/target.json').read_text())
    old.update(hardware_build_id=c['dma_load_build_id'],generation_context=str(path.relative_to(REPO)),
               generation_context_sha256=sha(path),bitstream=None,bitstream_sha256=None,
               artifact_state='RTL_SIMULATION_ONLY',dma_load_streaming_enable=True,
               dma_load_pipeline_version='row_ready_v1',routed_wns_ns=None,routed_whs_ns=None,
               board_validation='NOT_RUN')
    (ROOT/'hardware/target.json').write_text(json.dumps(old,indent=2)+'\n')
    print('MERGED_FIRMWARE_BOUND hardware_id='+c['dma_load_build_id']+' bitstream=NOT_GENERATED')


if __name__=='__main__':main()
