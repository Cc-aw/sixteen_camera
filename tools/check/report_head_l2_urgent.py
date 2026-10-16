#!/usr/bin/env python3
"""Capture final source/RTL provenance and combine actual validation records."""
import hashlib
import json
from pathlib import Path
import re
import subprocess
import datetime

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'build/reports/head_l2_urgent'


def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    product = json.loads((ROOT / 'hw/manifests/current.json').read_text())
    generated = ROOT / product['soc_directory']
    context = json.loads((generated / 'GENERATION_CONTEXT.json').read_text())
    workspace = Path(context['source_workspace'])
    files = set(subprocess.check_output(['git','diff','--name-only','-z'],cwd=ROOT).decode().split('\0'))
    files.update(subprocess.check_output(['git','ls-files','--others','--exclude-standard','-z'],cwd=ROOT).decode().split('\0'))
    sources = {p:sha(ROOT/p) for p in sorted(files) if p and (ROOT/p).is_file() and '/gen-collateral/' not in p}
    effective = {p:sha(workspace/p) for p in context['effective_scala'] if p.endswith((
        'inclusivecache/src/Parameters.scala','inclusivecache/src/Configs.scala','MemoryParallelV3.scala'))}
    for name, digest in effective.items():
        assert digest == context['effective_scala'][name], 'Stale elaboration source: '+name
    rtl = generated / 'gen-collateral'
    for name, digest in context['final_rtl_sha256'].items():
        assert sha(rtl/name) == digest, 'Generated RTL digest mismatch: '+name
    statefile = OUT / 'implementation_state.json'
    state = json.loads(statefile.read_text()) if statefile.exists() else {'build_state':'NOT_RUN','synthesis_state':'NOT_RUN'}
    if state.get('synthesis_state') == 'COMPLETE':
        checkpoint = Path(state['synthesis_dcp'])
        state['synthesis_dcp_sha256'] = sha(checkpoint)
    manifest = dict(baseline_commit='3440bc10a15467f7ba42bb2ffac21a343e1956d6',
        current_commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
        updated_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
        head_read_decouple=product['head_read_decouple'], l2_secondary_entries=product['l2_secondary_entries'],
        preserved=dict(banks=2,l2_bytes=524288,mshrs_normal_per_bank=32,mshrs_coherent_per_bank=2,
            logical_queues_per_bank=102,response_credits=4,clock_hz=100000000,
            soc_memory='512/ID2',tensor='256/ID5',gemmini='3xDIM32',mpv3_abi='1.1',frontend_abi=2),
        modified_sources_sha256=sources, effective_scala_sha256=effective,
        generation_context=str(generated/'GENERATION_CONTEXT.json'), generation_context_sha256=sha(generated/'GENERATION_CONTEXT.json'),
        final_rtl_sha256=context['final_rtl_sha256'],
        generator_assembly_sha256=sha(workspace/'.classpath_cache/chipyard_fpga.jar'),
        build_sbt_sha256=context['build_sbt_sha256'],
        parameter_headers_sha256={str(p.relative_to(ROOT)):sha(p) for p in (rtl/'include').glob('*.h')},
        test_sources_sha256={str(p.relative_to(ROOT)):sha(p) for d in
            [ROOT/'tests/rtl/head_l2_urgent',ROOT/'tests/rtl/scala'] for p in d.glob('*') if p.is_file()},
        patches_sha256={p.name:sha(p) for p in (OUT/'patches').glob('*.patch')},
        tools=dict(vivado='2023.2',head_verilator='5.022',failed_head_verilator='5.044 (internal fault)',
                   scala='2.13.16',chisel='6.7.0'),
        implementation=state,BOARD_RUN='NOT_RUN',MODEL_THROUGHPUT='NOT_MEASURED',SPEEDUP_2P8_OR_3P0='NOT_CLAIMED')
    records={}
    for p in sorted(OUT.glob('*_results.json')):
        if p.name != 'validation_results.json':
            for item in json.loads(p.read_text()):records[item['name']]=item
    for item in records.values():
        log=Path(item['log'])
        if log.is_file():item['log_sha256']=sha(log)
    (OUT/'validation_results.json').write_text(json.dumps(list(records.values()),indent=2)+'\n')
    manifest['validation_results_sha256'] = sha(OUT/'validation_results.json')
    (OUT/'implementation_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    (OUT/'validation_summary.txt').write_text(''.join(f"{r['name']}={r['status']} log={r['log']} {r['reason']}\n" for r in records.values()))
    print(f"HEAD_L2_MANIFEST=PASS rtl_files={len(context['final_rtl_sha256'])} validations={len(records)}")


if __name__ == '__main__':
    main()
