#!/usr/bin/env python3
"""Audit the imported immutable S1 bitstream and its local source closure."""
import hashlib
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]

def sha(path):
    value=hashlib.sha256()
    with path.open('rb') as stream:
        for chunk in iter(lambda:stream.read(1024*1024),b''):value.update(chunk)
    return value.hexdigest()


def main():
    hardware=json.loads((ROOT/'manifests/hardware.json').read_text())
    context_path=ROOT/hardware['generation_context']
    if sha(context_path)!=hardware['generation_context_sha256']:raise ValueError('Generation context changed')
    context=json.loads(context_path.read_text())
    if (context['dma_load_build_id']!='e037701c8d7cfc59' or context['dma_load_fixed_mode']!=2 or
        context['dma_load_mode_ids']!=[2] or context['dma_load_capability_word']!='0x00010004' or
        not context['activation_sram_enabled'] or not context['dma_load_streaming_enable']):
        raise ValueError('Expected fixed-mode S1 streaming/ASRAM identity')
    source=ROOT/'source/chipyard'
    actual={str(p.relative_to(source)):sha(p) for folder in ('generators','fpga/src')
            for p in (source/folder).rglob('*.scala') if 'target' not in p.parts}
    if actual!=context['effective_scala']:raise ValueError('Effective Scala differs from imported generation')
    if sha(source/'build.sbt')!=context['build_sbt_sha256']:raise ValueError('build.sbt changed')
    rtl=ROOT/'generated/gen-collateral'
    actual={str(p.relative_to(rtl)):sha(p) for p in rtl.rglob('*') if p.is_file()}
    if actual!=context['final_rtl_sha256']:raise ValueError('Imported generated RTL changed')
    bit=ROOT/hardware['bitstream']
    if bit.stat().st_size!=hardware['bitstream_bytes'] or sha(bit)!=hardware['bitstream_sha256']:
        raise ValueError('Imported bitstream changed')
    locks=json.loads((ROOT/'manifests/LOCAL_FILES.json').read_text())
    from lock import files
    if locks['files']!=files():raise ValueError('Local source/build input changed; inspect before refreshing lock')
    engine=(rtl/'CommandFrontendEngine.sv').read_text()
    if 'fifo_7' not in engine or 'fifo_15' in engine:raise ValueError('Unexpected frontend FIFO')
    mux=(rtl/'CommandFrontendMemoryMux.sv').read_text()
    if "chooseF ? 4'h5" not in mux:raise ValueError('Unexpected command Get size')
    print('S1_IMPORT_AUDIT_PASS hardware_id='+hardware['hardware_build_id']+
          ' scala='+str(len(context['effective_scala']))+' generated='+str(len(actual))+
          ' bitstream_sha256='+hardware['bitstream_sha256']+' board_validation=NOT_RUN_THIS_IMPORT')


if __name__=='__main__':main()
