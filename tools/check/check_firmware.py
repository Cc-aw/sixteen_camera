#!/usr/bin/env python3
"""Verify the native triple32 ELF's PPU ordering, context mode and identity."""
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
    parser.add_argument("--elf", type=Path, default=ROOT / "build/firmware/video/video.elf")
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
            "v26 requires the light task context")
    manifest = json.loads(elf.with_suffix(".json").read_text())
    require(manifest["soc_variant"] == "triple32_v3_tensor" and manifest["firmware"] == "v26",
            "firmware identity mismatch")
    require(manifest["elf_sha256"] == hashlib.sha256(elf.read_bytes()).hexdigest(), "ELF hash mismatch")
    require(manifest["source_lock_sha256"] == hashlib.sha256(
        (ROOT / "sw/models/yolov5nu/sources.lock.json").read_bytes()).hexdigest(),
        "source snapshot changed since firmware build")
    config = manifest["soc_config"]
    params = ROOT / "hw/soc" / config / "gen-collateral/include/gemmini_params_32x32_ws_dual_int8_dsp_inference_ram_custom3_xcvu13p.h"
    require(manifest["params_sha256"] == hashlib.sha256(params.read_bytes()).hexdigest(), "hardware parameter hash mismatch")
    if manifest["firmware"] == "v26":
        require(manifest["hardware_generation_sha256"] == hashlib.sha256(
            (ROOT / "hw/soc" / config / "GENERATION_CONTEXT.json").read_bytes()).hexdigest(),
            "hardware generation snapshot changed since firmware build")
        require(not re.search(r"\b(?:rdcycle|cycle)\b|0xc00", switch),
                "formal context switch contains diagnostic clock reads")
        for name in ("yolo32_independent_credit_pending", "yolo32_independent_credit_status",
                     "yolo32_independent_memory_submit", "yolo32_memory_pool5", "yolo32_memory_resize2"):
            require(name in functions, f"v26 execution path missing: {name}")
        require(not any(name.startswith("yolo32_capacity_") for name in functions),
                "capacity instrumentation linked into formal firmware")
        require(manifest["credit_limit"] == 4 and manifest["diagnostic_build"] == 0 and
                not manifest["software_batch"] and manifest["resize_rows"] == 0,
                "default v26 configuration mismatch")
        for feature in ("wait_reuse", "credit_query", "packet_dispatch", "memory_ops", "resize_batch"):
            require(manifest[feature] is True, f"missing v26 feature: {feature}")
        build = ROOT / "build/firmware/video/v26"
        for name in ("memory_kernels", "fixed_plans"):
            require(manifest[f"{name}_sha256"] == hashlib.sha256(
                (build / f"{name}.json").read_bytes()).hexdigest(), f"{name} changed since firmware build")
        signature = (build / "native-config.stamp").read_text()
        require(manifest["native_config_sha256"] == hashlib.sha256(signature.encode()).hexdigest(),
                "native build flags changed since firmware build")
        for define in ("YOLO32_CREDIT_LIMIT=4", "YOLO32_DIAGNOSTIC_BUILD=0", "YOLO32_LIVE=1",
                       "YOLO32_SOFTWARE_BATCH=0", "YOLO32_CAPACITY_EXPERIMENT=1", "YOLO32_RESIZE_ROWS=0"):
            require(f"-D{define}" in signature.split(), f"build flags mismatch: {define}")
        collateral = params.parent.parent
        for module in ("Gemmini", "Gemmini_1", "Gemmini_2"):
            rtl = (collateral / f"{module}.sv").read_text()
            require("loopConvOutstandingCount < 4'h4 & io_loopconv_request_queue_count < 8'h2 & ~io_loopconv_assembler_partial" in rtl,
                    f"{module}: four-slot hardware inlet gate mismatch")
    print(f"{manifest['firmware'].replace(' ', '').upper()}_ELF_AUDIT=PASS PPU_read_barriers=3 light_FP_VCSR_context=PASS manifest=PASS")


if __name__ == "__main__":
    main()
