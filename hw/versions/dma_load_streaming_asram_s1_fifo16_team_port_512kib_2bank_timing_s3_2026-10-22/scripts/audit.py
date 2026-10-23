#!/usr/bin/env python3
"""Check the generated frontend configuration and retained S1 parameter ABI."""
import argparse
import json
from pathlib import Path
import re

from common import ROOT, baseline, source_root, audit_identity, build_inputs, build_parameters, identity, scala_hashes, selected_output, sha


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--generated', type=Path, default=ROOT / 'generated')
    args = parser.parse_args()
    frozen = baseline()
    original = frozen['baseline_context']
    source = source_root()
    sources = scala_hashes(source)
    changed = sorted(name for name in sources
                     if sources[name] != original['effective_scala'].get(name))
    generated, context = selected_output(args.generated)
    hardware = json.loads((generated / 'hardware.json').read_text())
    context_path = generated / 'GENERATION_CONTEXT.json'
    if sha(context_path) != hardware['generation_context_sha256']:
        raise ValueError('Generation context changed')
    context = json.loads(context_path.read_text())
    digest = audit_identity(context_path, sources)
    if (context['effective_scala'] != sources or context['source_identity_sha256'] != digest or
            context['build_parameters'] != build_parameters() or
            context['dma_load_build_id'] != hardware['hardware_build_id'] or
            context['dma_load_build_id'] != digest[:16] or context['build_method'] != 'FULL_SOURCE_SBT'):
        raise ValueError('Generated hardware/source identity mismatch')
    for key in ('config', 'build_sbt_sha256', 'activation_sram_enabled', 'dma_load_streaming_enable',
                'dma_load_pipeline_version', 'dma_load_fixed_mode', 'dma_load_mode_ids',
                'dma_load_capability_word', 'l2_banks', 'l2_capacity_kib', 'l2_implementation'):
        if context[key] != original[key]:
            raise ValueError('S1 configuration changed: ' + key)
    rtl = generated / 'gen-collateral'
    actual_rtl = context['final_rtl_sha256']
    for name, digest in original['final_rtl_sha256'].items():
        if name.startswith('include/') and actual_rtl.get(name) != digest:
            raise ValueError('Mathematical/software ABI header changed: ' + name)
    engine = (rtl / 'CommandFrontendEngine.sv').read_text()
    mux = (rtl / 'CommandFrontendMemoryMux.sv').read_text()
    cluster = (rtl / 'CommandFrontendCluster.sv').read_text()
    if not all(token in engine for token in ('fifo_15', 'io_mem_req_size', 'io_mem_resp_last')):
        raise ValueError('Missing FIFO16/batch engine')
    if not all(token in mux for token in ('batchActive', 'batchLeft', 'io_f_req_size', 'io_f_resp_last')):
        raise ValueError('Missing split-fetch memory adapter')
    for value in (hardware['hardware_build_id'], '10004'):
        if f"64'h{value}" not in cluster.lower():
            raise ValueError('S1 build ID/capability diagnostics missing')
    if not re.search(r'\[32:0\]\s+io_g_a_address', mux) or not re.search(r'\[5:0\]\s+io_g_a_source', mux):
        raise ValueError('DMA address/source width changed')
    report = dict(status='TEAM_PORT_SOURCE_RTL_AUDIT_PASS', hardware_build_id=hardware['hardware_build_id'],
                  generated_output=str(generated), build_parameters=context['build_parameters'],
                  changed_scala=changed,
                  generated_files=len(actual_rtl), math_abi_headers='BYTE_IDENTICAL_TO_S1',
                  bitstream=hardware['bitstream'],
                  board_validation='NOT_RUN',
                  audit_scope='LOCAL_RECONSTRUCTED_SOURCE_AND_GENERATED_RTL')
    (ROOT / 'validation').mkdir(exist_ok=True)
    (ROOT / 'validation/source_rtl_audit.json').write_text(json.dumps(report, indent=2) + '\n')
    print(report['status'] + ' hardware_id=' + hardware['hardware_build_id'])


if __name__ == '__main__':
    main()
