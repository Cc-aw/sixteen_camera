#!/usr/bin/env python3
"""Verify the S3 patch closure and optionally compare freshly generated RTL."""
import argparse
import hashlib
import json
from pathlib import Path

from common import ROOT, REPO, prepared_sources, sha, selected_output
from source_overlay import digest_map


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--generated', type=Path)
    args = parser.parse_args()
    frozen = json.loads((ROOT / 'manifests/TIMING_SOURCE.json').read_text())
    parent = json.loads((ROOT / 'manifests/PARENT.json').read_text())
    if sha(REPO / parent['directory'] / 'manifests/SOURCE_OVERLAY.json') != parent['source_recipe_sha256']:
        raise ValueError('Team parent recipe changed')
    prepared = prepared_sources()
    if (len(prepared.files) != frozen['effective_source_files'] or
        digest_map(prepared.files) != frozen['effective_source_tree_sha256']):
        raise ValueError('Restored sources differ from the tested S3 source closure')
    for name, expected in frozen['locked_files_sha256'].items():
        if sha(ROOT / name) != expected:
            raise ValueError('S3 board/postprocessing source changed: ' + name)
    for name in ('activation_sram_map.h', 's1_direct_a32.h'):
        if sha(ROOT / 'tests/abi' / name) != frozen['donor_final_rtl_sha256']['include/' + name]:
            raise ValueError('S3 software ABI changed: ' + name)
    generated_result = None
    if args.generated:
        generated, context = selected_output(args.generated)
        if context['effective_scala'] != {n:h for n,h in prepared.files.items()
                if n.endswith('.scala') and n.startswith(('generators/', 'fpga/src/')) and 'target' not in Path(n).parts}:
            raise ValueError('Generated Scala sources differ from the S3 patch closure')
        expected = frozen['donor_final_rtl_sha256']
        actual = context['final_rtl_sha256']
        if set(actual) != set(expected):
            raise ValueError('S3 generated collateral inventory differs')
        normalized = []
        for name, value in actual.items():
            if value == expected[name]:
                continue
            if name != 'CommandFrontendCluster.sv':
                raise ValueError('S3 RTL differs from tested donor: ' + name)
            data = (generated / 'gen-collateral' / name).read_bytes()
            local_id = context['dma_load_build_id'].upper().encode()
            if data.count(local_id) != 3:
                raise ValueError('Expected exactly three worker hardware ID literals')
            data = data.replace(local_id, frozen['donor_hardware_build_id'].upper().encode())
            if hashlib.sha256(data).hexdigest() != expected[name]:
                raise ValueError('Frontend differs beyond its three hardware ID literals')
            normalized.append(name)
        generated_result = dict(hardware_build_id=context['dma_load_build_id'],
                                files=len(actual), id_normalized_files=normalized,
                                status='BYTE_IDENTICAL_EXCEPT_BUILD_ID')
    result = dict(status='S3_PORT_SOURCE_AUDIT_PASS', source_files=len(prepared.files),
                  changed_scala=frozen['changed_sources'], board_files=len(frozen['locked_files_sha256']),
                  source_tree_sha256=digest_map(prepared.files), generated=generated_result,
                  board_validation='NOT_RUN_FOR_LOCAL_REBUILD', board_accessed=False)
    destination = ROOT / 'validation/source_port.json'
    destination.parent.mkdir(exist_ok=True)
    destination.write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
