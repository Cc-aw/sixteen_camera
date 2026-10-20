#!/usr/bin/env python3
"""Validate the selected S1 hardware and live-video firmware ABI, offline."""
import argparse
import json
import os
import re
import sys
from current_product import ROOT, local_path, product, sha

NAME = 'dma_load_streaming_asram_s1_512kib_2bank'
HW_ID = 'e037701c8d7cfc59'
BIT_SHA = 'cb907a77e0c0bf97f5074208956884517d349485003a8d6613ca61b9f7e93a01'


def require(condition, message):
    if not condition:
        raise ValueError(message)


def validate(p):
    expected = dict(schema=2, hardware_alias=NAME, hardware_build_id=HW_ID,
                    hardware_directory='hw/soc/version/' + NAME,
                    software_directory='sw/video_runtime/' + NAME,
                    worker_count=3, gemmini_dim=32, clock_hz=100000000,
                    runtime_profile='s1_live_video', bitstream_sha256=BIT_SHA,
                    bitstream_bytes=113318492)
    for key, value in expected.items():
        require(p[key] == value, 'Production identity mismatch: ' + key)
    for selector, wanted in [('SOC_VARIANT', NAME), ('SOC_CONFIG', p['soc_config'])]:
        require(os.environ.get(selector, '') in ('', wanted), 'Unsupported ' + selector)
    hw = local_path(p['hardware_directory'])
    sw = local_path(p['software_directory'])
    require(p['soc_directory'] == p['hardware_directory'] + '/generated', 'SoC directory mismatch')
    require(p['collateral_directory'] == p['soc_directory'] + '/gen-collateral', 'Collateral mismatch')
    require(p['generation_context'] == p['soc_directory'] + '/GENERATION_CONTEXT.json', 'Context path mismatch')
    require(p['bitstream'] == p['hardware_directory'] + '/bitstream/top_wrapper.bit', 'Bitstream path mismatch')
    require(p['video_build'] == p['software_directory'] + '/build', 'Software build mismatch')
    require(p['video_elf'] == p['video_build'] + '/s1_video_runtime.elf', 'ELF mismatch')
    context_path = local_path(p['generation_context'])
    context = json.loads(context_path.read_text())
    h = json.loads((hw / 'manifests/hardware.json').read_text())
    require(sha(context_path) == p['generation_context_sha256'] == h['generation_context_sha256'], 'Context hash mismatch')
    require(context['config'] == p['soc_config'], 'Generated SoC config mismatch')
    require(context['dma_load_build_id'] == h['hardware_build_id'] == HW_ID, 'Hardware build ID mismatch')
    require(h['bitstream_sha256'] == BIT_SHA and h['bitstream_bytes'] == p['bitstream_bytes'], 'Bitstream identity mismatch')
    require(context['dma_load_fixed_mode'] == p['dma']['fixed_mode'] == 2 and
            context['dma_load_mode_ids'] == [2] and
            context['dma_load_capability_word'] == p['dma']['capability_word'] == '0x00010004' and
            context['dma_load_streaming_enable'] and context['activation_sram_enabled'], 'DMA/ASRAM ABI mismatch')
    require(p['l2'] == dict(banks=2, capacity_bytes=524288, ways=8, sets_per_bank=512, line_bytes=64), 'L2 identity mismatch')
    metadata = list((hw / 'generated').glob('*.l2.json'))
    require(len(metadata) == 1, 'Expected one L2 geometry')
    banks = json.loads(metadata[0].read_text())['banks']
    require(len(banks) == 2 and all(b['ways'] == 8 and len(b['setBits']) == 9 and b['blockBytes'] == 64 for b in banks), 'Generated L2 geometry mismatch')
    require(p['asram'] == dict(bases=[0x20000000, 0x20400000, 0x20800000],
                              physical_bytes_per_bank=2359296, control_base=0x20c00000), 'ASRAM map mismatch')
    require(p['command_frontend'] == dict(fifo_depth=8, get_bytes=32), 'Frontend dimensions mismatch')
    require(p['firmware_compatibility'] == dict(status='ready', control_opcode='custom3',
            worker_opcodes=['custom0', 'custom1', 'custom2'], irq=13), 'Firmware ABI mismatch')
    lock = json.loads((hw / 'manifests/LOCAL_FILES.json').read_text())['files']
    for lane in range(3):
        name = 'generated/gen-collateral/include/gemmini_params_32x32_ws_dual_int8_dsp_inference_ram_custom%d_xcvu13p.h' % lane
        require(sha(hw / name) == lock[name], 'Generated parameter header mismatch')
    require((sw / 'hardware/gemmini_params_custom0.h').read_bytes() ==
            (hw / 'generated/gen-collateral/include/gemmini_params_32x32_ws_dual_int8_dsp_inference_ram_custom0_xcvu13p.h').read_bytes(), 'Software parameter snapshot mismatch')
    # The package independently checks its full source/flags/ELF identity before downloading.
    sys.path.insert(0, str(sw / 'scripts'))
    import build
    require(build.HW_ID == HW_ID and build.BIT_SHA == BIT_SHA and build.BIT == local_path(p['bitstream']), 'Software hardware binding mismatch')
    for relative in ['Makefile', 'sources.mk', 'src/main.c', 'src/live_backend.inc',
                     'runtime/drivers/tensor/ai_tensor_device.c', 'tests/run.py']:
        require((sw / relative).is_file(), 'Missing firmware source: ' + relative)
    retired = ROOT / 'hw/soc' / ('tsmcchip.fpga.taihangsoc.TaihangSoCFPGATestHarness.'
              'TaihangSoC1Rocket1RVV3Gemmini32x32MemoryParallelV3TensorIngressConfig')
    require(not retired.exists() and not (ROOT / 'sw/src/main.c').exists(), 'Retired default remains')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--tcl', action='store_true')
    parser.add_argument('--firmware', action='store_true')
    parser.add_argument('--benchmark', action='store_true')
    args = parser.parse_args()
    try:
        p = product()
        validate(p)
        if args.tcl:
            keys = ('hardware_alias', 'soc_config', 'collateral_directory')
            require(all(re.fullmatch(r'[A-Za-z0-9_./-]+', p[k]) for k in keys), 'Invalid Tcl field')
            print(' '.join(k + ' ' + p[k] for k in keys))
        else:
            print('CURRENT_PRODUCT=PASS ' + NAME + ' hardware_id=' + HW_ID)
            print('FIRMWARE_COMPATIBILITY=ready l2=512KiB/2bank dma=2 streaming=1 asram=1')
    except (ValueError, KeyError, OSError) as error:
        print('CURRENT_PRODUCT=FAIL ' + str(error), file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
