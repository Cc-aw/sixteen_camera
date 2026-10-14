#!/usr/bin/env python3
"""Build the V3 TensorIngress video firmware with the v26 worker scheduler."""
from pathlib import Path
import argparse
import hashlib
import json
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[2]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    build = ROOT / "build/firmware/triple32_v3_tensor"
    subprocess.run([
        "make", "-C", str(ROOT / "sw"), "-j4", "SOC_VARIANT=triple32_v3_tensor",
        "AI_MODEL=yolov5nu", "TENSOR_INGRESS_STATS=1", "V26_CREDIT_LIMIT=4",
        "V26_DIAGNOSTIC=0", f"BUILD={build}", "all",
    ], check=True)
    built = build / "hdmi_tx_test.elf"
    output = (args.output or ROOT / "build/firmware/gemmini_triple32_v3_tensor_video_yolov5nu.elf").resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    if built.resolve() != output:
        shutil.copy2(built, output)
    config = "tsmcchip.fpga.taihangsoc.TaihangSoCFPGATestHarness.TaihangSoC1Rocket1RVV3Gemmini32x32MemoryParallelV3TensorIngressConfig"
    params = ROOT / "hw/soc" / config / "gen-collateral/include/gemmini_params_32x32_ws_dual_int8_dsp_inference_ram_custom3_xcvu13p.h"
    manifest = {
        "soc_variant": "triple32_v3_tensor", "firmware": "v26",
        "soc_config": config, "params_sha256": hashlib.sha256(params.read_bytes()).hexdigest(),
        "hardware_generation_sha256": hashlib.sha256((ROOT / "hw/soc" / config / "GENERATION_CONTEXT.json").read_bytes()).hexdigest(),
        "source_lock_sha256": hashlib.sha256((ROOT / "sw/models/yolov5nu/triple32/sources.lock.json").read_bytes()).hexdigest(),
        "native_config_sha256": hashlib.sha256((build / "v26/native-config.stamp").read_bytes()).hexdigest(),
        "memory_kernels_sha256": hashlib.sha256((build / "v26/memory_kernels.json").read_bytes()).hexdigest(),
        "fixed_plans_sha256": hashlib.sha256((build / "v26/fixed_plans.json").read_bytes()).hexdigest(),
        "credit_limit": 4, "diagnostic_build": 0, "wait_reuse": True,
        "credit_query": True, "packet_dispatch": True, "memory_ops": True,
        "resize_batch": True, "resize_rows": 0, "software_batch": False,
        "workers": 3, "dim": 32, "clock_hz": 100000000,
        "head_admission": "graph_complete", "head_publication": "local_completion",
        "elf": str(output.relative_to(ROOT)) if output.is_relative_to(ROOT) else str(output),
        "elf_sha256": hashlib.sha256(output.read_bytes()).hexdigest(),
    }
    output.with_suffix(".json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"TRIPLE32_V26_VIDEO_ELF={output}")
    print(f"TRIPLE32_V26_VIDEO_SHA256={manifest['elf_sha256']}")
    print("TRIPLE32_V26_VIDEO_BUILD=PASS")


if __name__ == "__main__":
    main()
