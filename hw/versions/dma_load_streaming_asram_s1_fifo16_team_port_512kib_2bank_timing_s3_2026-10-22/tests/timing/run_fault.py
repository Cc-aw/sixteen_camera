#!/usr/bin/env python3
"""Run inherited three-lane denied/corrupt + reset test on the local RTL."""
import os
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]


def main():
    out = ROOT / 'build/s2_fault_fixed_abi'
    out.mkdir(parents=True, exist_ok=False)
    source = (ROOT / 'tests/asram/test_fault.py').read_text()
    source = source.replace('ROOT=Path(__file__).resolve().parents[4]', f'ROOT=Path({str(ROOT)!r})')
    source = source.replace("(Path(__file__).parent/'test_real_gemmini.py')",
                            f"(Path({str(ROOT / 'tests/merged_dma')!r})/'test_real_gemmini.py')")
    # Correct the inherited harness' historical project-depth spelling.
    source = source.replace("runner=runner.replace('project = feature.parents[2]'",
                            "runner=runner.replace('project = feature.parents[1]'")
    # The inherited test predates the fixed-mode ABI: unsupported mode 0
    # returns 2 before fault checks. Test a supported request while faulted,
    # and require reset to restore the production fixed mode 2.
    source = source.replace('control_rs1=0;control_rs2=0;', 'control_rs1=2;control_rs2=0;')
    source = source.replace('if(v!==0)$fatal(1,"Reset must restore legacy");',
                            'if(v!==2)$fatal(1,"Reset must restore fixed mode2");')
    source = source.replace('out.mkdir(parents=True,exist_ok=False)',
                            'out.mkdir(parents=True,exist_ok=True)')
    driver = out / 'driver.py'
    driver.write_text(source)
    env = dict(os.environ, STREAM_ASRAM_SIM='1',
               VIVADO_BIN=os.environ.get('VIVADO_BIN', 'vivado'))
    subprocess.run([sys.executable, str(driver), '--rtl',
                    str(Path(os.environ.get('S3_GENERATED_OUTPUT', str(ROOT / 'build/timing_generated_final'))) / 'gen-collateral'),
                    '--output', str(out / 'simulation')], env=env, check=True)
    print('S2_THREE_LANE_DENIED_CORRUPT_RESET_PASS')


if __name__ == '__main__':
    main()
