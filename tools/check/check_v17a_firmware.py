#!/usr/bin/env python3
"""Verify the built V17 A ELF's PPU ordering, context mode and identity."""
from pathlib import Path
import argparse
import hashlib
import json
import os
import re
import subprocess

ROOT = Path(__file__).resolve().parents[2]


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def ppu_call_bodies(functions, root):
    """Follow PPU adapters to device functions, including compiler tail calls."""
    pending = [root]
    visited = set()
    bodies = []
    while pending:
        name = pending.pop()
        if name in visited:
            continue
        visited.add(name)
        require(name in functions, f"{name}: missing PPU function")
        body = functions[name]
        bodies.append(body)
        for target in re.findall(r"<([^>+]+)>", body):
            if target.startswith("ai_ppu_") and target in functions:
                pending.append(target)
    return "\n".join(bodies)


def check_ppu_ordering(functions, root):
    body = ppu_call_bodies(functions, root)
    require(not re.search(r"\bfence(?:\.|\s)", body), f"{root}: unexpected global fence")
    require("yolo32_ppu_io_barrier" in body, f"{root}: missing PPU read barrier")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--elf", type=Path, default=ROOT / "build/firmware/gemmini_triple32_v3_tensor_video_yolov5nu.elf")
    args = parser.parse_args()
    elf = args.elf.resolve()
    objdump = (os.environ.get("TOOLCHAIN") or "riscv64-unknown-elf-") + "objdump"
    disassembly = subprocess.check_output([objdump, "-d", str(elf)], text=True)
    blocks = re.split(r"^([0-9a-f]+) <([^>]+)>:\n", disassembly, flags=re.M)
    functions = {blocks[i + 1]: blocks[i + 2] for i in range(1, len(blocks), 3)}
    for name in ("ai_ppu_publication_begin", "ai_ppu_publication_publish", "ai_ppu_queue_submit"):
        check_ppu_ordering(functions, name)
    switch = functions["yolo32_task_switch"]
    require("frcsr" in switch and "fscsr" in switch and "vcsr" in switch,
            "task switch does not preserve FP/VCSR environment")
    require("vs8r.v" not in switch and "vl8re8.v" not in switch,
            "V17 A requires the light task context")
    manifest = json.loads(elf.with_suffix(".json").read_text())
    require(manifest["soc_variant"] == "triple32_v3_tensor" and manifest["firmware"] == "v17 A",
            "firmware identity mismatch")
    require(manifest["elf_sha256"] == hashlib.sha256(elf.read_bytes()).hexdigest(), "ELF hash mismatch")
    require(manifest["source_lock_sha256"] == hashlib.sha256(
        (ROOT / "sw/models/yolov5nu/triple32/sources.lock.json").read_bytes()).hexdigest(),
        "source snapshot changed since firmware build")
    config = manifest["soc_config"]
    params = ROOT / "hw/soc" / config / "gen-collateral/include/gemmini_params_32x32_ws_dual_int8_dsp_inference_ram_custom3_xcvu13p.h"
    require(manifest["params_sha256"] == hashlib.sha256(params.read_bytes()).hexdigest(), "hardware parameter hash mismatch")
    print("V17A_ELF_AUDIT=PASS PPU_read_barriers=3 light_FP_VCSR_context=PASS manifest=PASS")


if __name__ == "__main__":
    main()
