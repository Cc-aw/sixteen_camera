#!/usr/bin/env python3
"""Execute original/folded first-layer kernels on three real DIM32 RTL lanes.

Uses compact 16x16 RGB inputs, real model weights/FP16/SiLU LUT, padding and
PixelRepeater. The existing delayed-DDR frontend rig is copied into build/;
production RTL and the original testbench remain read-only. Not a board test.
"""
import json
import os
from pathlib import Path
import subprocess
import sys
import argparse

PROJECT = Path(__file__).resolve().parents[4]
ROOT = PROJECT / 'sw/benchmarks/frontend'
OUT = Path(os.environ.get('FRONTEND_BUILD', PROJECT / 'build/firmware/first-layer-s2d'))
SIM = PROJECT / 'build/sim/first_layer_s2d'
sys.path.insert(0, str(ROOT / 'scripts'))
from first_layer_s2d_prepare import array, fold_weights
from parallel_cache_plan import regenerate, sha


def main():
    global SIM
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--rtl', type=Path)
    parser.add_argument('--output', type=Path)
    parser.add_argument('--dma-load-mode', choices=('legacy', 'read_coalesced', 'read_assembled', 'spad_assembled', 'all'))
    args = parser.parse_args()
    if args.output:
        SIM = args.output.resolve()
    SIM.mkdir(parents=True, exist_ok=True)
    feature = SIM / 'feature'
    (feature / 'reference').mkdir(parents=True, exist_ok=True)
    original_feature = PROJECT / 'tests/rtl/command_frontend'
    for name in ('MemoryLane.sv', 'tb_real_cluster.sv'):
        (feature / 'reference' / name).write_bytes((original_feature / 'reference' / name).read_bytes())
    description = json.loads((OUT / 'generated/first_layer_s2d.json').read_text())
    s = dict(description['baseline_shape'], ih=16, iw=16, oh=8, ow=8)
    folded = dict(description['candidate_shape'], ih=8, iw=8, oh=8, ow=8)
    plans, _ = regenerate(OUT / 'native', [(0, 0, s, [1, 8, 8, 16, 6, 6, 3]),
                                        (0, 1, folded, [1, 8, 8, 16, 3, 3, 12])], SIM)
    assert all(len(p['tiles']) == 1 for p in plans.values()) and len(plans) == 2
    params = next((OUT / 'native').glob('*profile_params.h')).read_text()
    weights = array(params, 'yolov5nu_conv0_weights')
    bias = array(params, 'yolov5nu_conv0_bias')
    lut_text = (OUT / 'generated/first_layer_s2d_data.inc').read_text().split('first_lut[32] = {', 1)[1]
    import re
    lut = list(map(int, re.findall(r'UINT64_C\((\d+)\)', lut_text.split('};', 1)[0])))
    code = '''task prepare_conv;
  for(integer i=0;i<768;i=i+1) memory['h3000+i]=8'((i*13+i/3*7+ID*11)%63-31);
  for(integer y=0;y<8;y=y+1)for(integer x=0;x<8;x=x+1)
    for(integer dy=0;dy<2;dy=dy+1)for(integer k=0;k<6;k=k+1)
      memory['h3800+(y*8+x)*12+dy*6+k]=memory['h3000+((2*y+dy)*16+2*x)*3+k];
'''
    for base, values in ((0x4000, weights), (0x4800, fold_weights(weights))):
        for i, value in enumerate(values): code += f"  memory['h{base+i:x}]=8'h{value&255:02x};\n"
    for i, value in enumerate(bias):
        for b in range(4): code += f"  memory['h{0x5000+4*i+b:x}]=8'h{(value>>(8*b))&255:02x};\n"
    for i, value in enumerate(lut): code += f"  raw(26,64'd{i*8},64'd{value},0);\n"
    for variant, bases in ((0, (0x4000, 0x5400, 0x5000, 0x3000)), (1, (0x4800, 0x5800, 0x5000, 0x3800))):
        plan = plans[0, variant]
        c = plan['config']
        commands = [(0, c[0], c[1]), (0, c[2], c[3])]
        p = plan['tiles'][0]
        commands += [(16, c[4], c[5])] + [(17+k, *p['geometry'][k*2:k*2+2]) for k in range(3)]
        for f, k in ((20, 0), (21, 2)):
            operands = ["64'd0" if p['offsets'][j] == 0xffffffff else f"64'(BASE)+64'd{bases[j]+p['offsets'][j]}" for j in (k, k+1)]
            commands.append((f, *operands))
        commands += [(15, *p['launch'])]
        for f, a, b in commands:
            aa, bb = f"64'd{a}" if isinstance(a, int) else a, f"64'd{b}" if isinstance(b, int) else b
            code += f'  raw({f},{aa},{bb},0);\n'
        code += "  entry(256'd1);\n"
    code += '''endtask
task check_conv;
  integer changed;
  changed=0;
  if(writes!=acks || gem_busy)$fatal(1,"S2D completion before store ACK");
  for(integer i=0;i<1024;i=i+1)begin
    if(memory['h5400+i]===8'ha5)$fatal(1,"S2D original output unwritten i=%0d",i);
    if(memory['h5400+i]!==memory['h5800+i])
      $fatal(1,"S2D lane=%0d byte=%0d original=%h folded=%h",ID,i,memory['h5400+i],memory['h5800+i]);
    if(memory['h5400+i]!=memory['h5400])changed=changed+1;
  end
  if(changed==0)$fatal(1,"S2D output is constant");
  $display("S2D_RTL_LANE_PASS,lane=%0d,output_bytes=1024,bit_exact=1",ID);
endtask
'''
    if args.dma_load_mode is not None:
        code = 'reg [7:0] dma_baseline[0:1023];reg baseline_valid=0;\n' + code
        code = code.replace('    if(changed==0)', '    if(changed==0)')
        code = code.replace('  if(changed==0)', '''  for(integer i=0;i<1024;i=i+1)begin
    if(dma_load_mode==0)dma_baseline[i]=memory['h5400+i];
    else if(baseline_valid && dma_baseline[i]!==memory['h5400+i])$fatal(1,"runtime mode output differs from legacy");
  end
  if(dma_load_mode==0)baseline_valid=1;
  if(changed==0)''')
    # A valid output can equal a poison byte. Use different poisons in each
    # output region so a matching unwritten pair cannot pass the comparison.
    code = code.replace("task prepare_conv;", "task prepare_conv;\n  for(integer i=0;i<1024;i=i+1)begin memory['h5400+i]=8'ha5;memory['h5800+i]=8'h5a;end")
    code = code.replace("    if(memory['h5400+i]===8'ha5)$fatal(1,\"S2D original output unwritten i=%0d\",i);\n", '')
    (feature / 'ConvWorkload.svh').write_text(code)
    runner = (Path(__file__).parent / 'test_real_gemmini.py').read_text()
    runner = runner.replace('feature = Path(__file__).resolve().parent', f'feature = Path({str(feature)!r})')
    runner = runner.replace('project = feature.parents[2]', f'project = Path({str(PROJECT)!r})')
    runner = runner.replace('out = project / "build/sim/command_frontend/real32"', f'out = Path({str(SIM)!r})')
    runner = runner.replace('i==0?116:115', 'i==0?93:92').replace('fetches!=116', 'fetches!=93').replace('fetches!=115', 'fetches!=92')
    # Record the exact production RTL closure used in this run.
    runner = runner.replace('for command in (', '(out/"rtl_hashes.json").write_text(json.dumps({str(p):__import__("hashlib").sha256(p.read_bytes()).hexdigest() for p in sources},indent=2))\nfor command in (', 1)
    script = SIM / 'run.py'
    script.write_text(runner)
    command = [sys.executable, '-B', str(script)]
    if args.rtl:
        command += ['--rtl', str(args.rtl.resolve()), '--output', str(SIM)]
    if args.dma_load_mode:
        command += ['--dma-load-mode', args.dma_load_mode]
    subprocess.run(command, check=True)
    log = (SIM / 'result.log').read_text()
    modes = len(json.loads((args.rtl.resolve().parent/'GENERATION_CONTEXT.json').read_text())['dma_load_supported_modes']) if args.dma_load_mode == 'all' else 1
    assert log.count('S2D_RTL_LANE_PASS') == 3 * modes and 'REAL_CLUSTER_PASS' in log
    hashes = json.loads((SIM / 'rtl_hashes.json').read_text())
    assert all(sha(Path(p).read_bytes()) == digest for p, digest in hashes.items()), 'RTL changed during simulation'
    evidence = dict(status='COMPACT_REAL_DIM32_RTL_PASS', board_validation='PENDING',
        scope='16x16 RGB -> 8x8x16; original/folded; three lanes; real first-layer weights/FP16/SiLU; all 3072 bytes',
        source_sha256=sha(Path(__file__).read_bytes()), log_sha256=sha(log.encode()), rtl_sha256=hashes)
    if args.rtl:
        evidence.update(candidate_rtl=str(args.rtl.resolve()), runtime_modes=args.dma_load_mode)
    destination = SIM if args.rtl else OUT
    (destination / 'rtl_evidence.json').write_text(json.dumps(evidence, indent=2) + '\n')
    print(f'S2D_RTL_PASS lanes=3 compared_bytes={3072*modes} board_executed=0')


if __name__ == '__main__':
    main()
