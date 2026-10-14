#!/usr/bin/env python3
"""Check registered video timing boundaries with complete-frame and stall tests."""
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "build/sim/video_timing_pipeline"
CASES = {
    "tb_mosaic_pipeline": ["hw/rtl/interfaces/axi4_if.sv", "hw/rtl/interfaces/axis_video_if.sv",
        "hw/rtl/video/display/rgb565_to_rgb888.sv", "hw/rtl/video/display/mosaic_rgb565_reader.sv"],
    "tb_event_pipeline": ["hw/rtl/video/camera/dvp_event_bridge.sv"],
    "tb_ui_return_stress": ["hw/rtl/interfaces/axi4_if.sv", "hw/rtl/bus/cdc_payload_fifo.sv",
        "hw/rtl/bus/axi4_ui_read_cdc.sv", "hw/rtl/bus/axi4_ui_write_cdc.sv"],
}
for top, sources in CASES.items():
    work = OUT / top
    work.mkdir(parents=True, exist_ok=True)
    bench = f"tests/rtl/benches/timing/{top}.sv"
    with (work / "compile.log").open("w") as log:
        subprocess.run(["verilator", "--binary", "--timing", "--assert", "-Wno-fatal", "-j", "4",
            "--top-module", top, "--Mdir", str(work), *[str(ROOT / s) for s in [*sources, bench]]],
            cwd=ROOT, stdout=log, stderr=subprocess.STDOUT, check=True)
    result = subprocess.run([str(work / f"V{top}")], cwd=ROOT, capture_output=True, text=True, check=True)
    (work / "simulation.log").write_text(result.stdout + result.stderr)
    print(result.stdout.strip(), flush=True)
print("VIDEO_TIMING_PIPELINE_TESTS=PASS")
