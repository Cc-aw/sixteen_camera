#!/usr/bin/env python3
"""Validate the sole production identity against generated and evaluated inputs."""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "hw/manifests/current.json"


def require(condition, message):
    if not condition:
        raise ValueError(message)


def macro(text, name):
    match = re.search(r"^#define\s+" + re.escape(name) + r"\s+(0[xX][0-9a-fA-F]+|[0-9]+)[uUlL]*\b", text, re.M)
    require(match is not None, "Missing macro: " + name)
    return int(match[1], 16 if match[1].lower().startswith("0x") else 10)


def validate(product, root=ROOT, evaluate=True):
    expected = {"schema": 1, "hardware_alias": "triple32_v3_tensor", "worker_count": 3,
                "gemmini_dim": 32, "clock_hz": 100000000, "model": "yolov5nu",
                "runtime_profile": "v26", "credit_limit": 4,
                "opcodes": ["custom2", "custom1", "custom0"]}
    expected.update(video_build="build/firmware/video", video_elf="build/firmware/video/video.elf",
                    benchmark_build="build/firmware/frontend",
                    benchmark_elf="build/firmware/frontend/yolov5_three_way_12.elf")
    for key, value in expected.items():
        require(product.get(key) == value, f"Production identity mismatch: {key}")
    config = "TaihangSoC1Rocket1RVV3Gemmini32x32MemoryParallelV3TensorIngressConfig"
    require(product["scala_config"] == config, "Scala Config mismatch")
    require(product["soc_config"] == "tsmcchip.fpga.taihangsoc.TaihangSoCFPGATestHarness." + config,
            "SoC Config mismatch")
    for name in ("SOC_VARIANT", "SOC_CONFIG"):
        wanted = product["hardware_alias" if name == "SOC_VARIANT" else "soc_config"]
        require(os.environ.get(name, "") in ("", wanted), f"Unsupported {name}")
    for key in ("soc_directory", "collateral_directory", "model_rules", "model_source",
                "generator", "frozen_input", "generation_context", "soc_sources", "tensor_ingress_source",
                "soc_generator", "reference_manifest"):
        path = root / product[key]
        # Vivado's Tcl exec may select its bundled Python, older than the
        # project's code-generation interpreter. Keep this bridge compatible.
        require(not Path(product[key]).is_absolute() and root.resolve() in path.resolve().parents,
                "Nonlocal product path: " + key)
        require(path.exists(), "Missing product input: " + str(path))
    require(product["collateral_directory"] == product["soc_directory"] + "/gen-collateral",
            "Collateral mapping mismatch")
    require(product["generation_context"] == product["soc_directory"] + "/GENERATION_CONTEXT.json",
            "Generation context mapping mismatch")
    context = json.loads((root / product["generation_context"]).read_text())
    require(context["config"] == product["soc_config"], "Generation identity mismatch")
    for lock in product["source_locks"]:
        require((root / lock).is_file(), "Missing source lock: " + lock)
    require(len(product["parameter_headers"]) == 3, "Expected three parameter headers")
    for opcode, path in zip(product["opcodes"], product["parameter_headers"]):
        wanted = (product["collateral_directory"] + "/include/"
                  "gemmini_params_32x32_ws_dual_int8_dsp_inference_ram_" + opcode + "_xcvu13p.h")
        require(path == wanted, "Worker parameter mapping mismatch: " + opcode)
        text = (root / path).read_text()
        require(macro(text, "DIM") == product["gemmini_dim"], "DIM mismatch: " + path)
        require(macro(text, "GEMMINI_LOOPCONV_SAFE_MAX") == product["credit_limit"],
                "SAFE_MAX mismatch: " + path)
        require(macro(text, "XCUSTOM_ACC") == int(opcode[-1]), "RoCC opcode mismatch: " + path)
    csr_sets = [(0x7c2, 0x7c4, 0x7c6, 0x7c7), (0x7c3, 0x7c5, 0x7c8, 0x7c9),
                (0x7ca, 0x7cb, 0x7cc, 0x7cd)]
    for path, values in zip(product["parameter_headers"], csr_sets):
        text = (root / path).read_text()
        for name, value in zip(("GEMMINI_BUSY_CSR", "GEMMINI_LOOPCONV_STATUS_CSR",
                                "GEMMINI_LOOPCONV_ACCEPTED_CSR", "GEMMINI_LOOPCONV_RETIRED_CSR"), values):
            require(macro(text, name) == value, "Worker CSR mismatch: " + path + " " + name)
    platform = (root / "sw/src/platform/platform.h").read_text()
    clock_match = re.search(r"#define SOC_CLOCK_HZ UINT64_C\((\d+)\)", platform)
    require(clock_match is not None and int(clock_match[1]) == product["clock_hz"], "Platform clock mismatch")
    for module in ("Gemmini", "Gemmini_1", "Gemmini_2"):
        rtl = (root / product["collateral_directory"] / (module + ".sv")).read_text()
        require("loopConvOutstandingCount < 4'h4" in rtl and
                "io_loopconv_request_queue_count" not in rtl and
                "io_loopconv_assembler_partial" not in rtl,
                "Hardware credit/admission mismatch: " + module)
    clock = (root / "sw/src/board/xparameters.h").read_text()
    require(macro(clock, "XPAR_CPU_CORE_CLOCK_FREQ_HZ") == product["clock_hz"], "CPU clock mismatch")
    frontend = product["command_frontend"]
    require(frontend["enabled"] and frontend["control_opcode"] == "custom3" and
            frontend["worker_lanes"] == [2, 1, 0], "Frontend ABI mapping mismatch")
    benchmark = product["frontend_benchmark"]
    require(benchmark["version"] == 33 and benchmark["status"] == "ready" and
            benchmark["frames_per_mode"] == 12 and benchmark["runtime_adapted"] is False,
            "Standalone V33 benchmark identity mismatch")
    for key in ("source", "rules", "generator", "source_lock", "import_manifest"):
        path = root / benchmark[key]
        require(not Path(benchmark[key]).is_absolute() and root.resolve() in path.resolve().parents
                and path.exists(), "Invalid V33 source: " + key)
    tile = (root / product["collateral_directory"] / "RocketTile.sv").read_text()
    require("CommandFrontendCluster" in tile and "CommandFrontendTL" in tile,
            "Frontend missing from generated SoC")
    if evaluate and product["firmware_compatibility"]["status"] == "ready":
        for entry in (root / "sw", root / "sw/benchmarks/triple_infer"):
            output = subprocess.check_output(
                ["make", "--no-print-directory", "-s", "-C", str(entry), "print-current-config"],
                text=True)
            actual = dict(line.split("=", 1) for line in output.splitlines() if "=" in line)
            for key, value in {"WORKERS": "3", "DIM": "32", "CREDIT": "4", "DIAGNOSTIC": "0",
                               "PARAMS": str(root / product["parameter_headers"][0]),
                               "MODEL": str(root / product["model_source"]),
                               "GENERATOR": str(root / product["generator"]),
                               "FROZEN": str(root / product["frozen_input"])}.items():
                require(actual.get(key) == value, f"{entry}: evaluated {key} mismatch")
            flags = actual["FLAGS"].split()
            definitions = dict(flag[2:].split("=", 1) for flag in flags if flag.startswith("-D") and "=" in flag)
            for flag in ("-DYOLO32_CONTEXT_FULL=0", "-DYOLO32_FIXED_PLANS=1", "-DYOLO32_FIXED_PACKETS=1",
                         "-DYOLO32_PREPARED_PACKETS=1", "-DYOLO32_WAIT_REUSE=1", "-DYOLO32_MEMORY_OPS=1",
                         "-DYOLO32_SOFTWARE_BATCH=0", "-DYOLO32_CREDIT_LIMIT=4",
                         "-DYOLO32_SUBMIT_BURST=1", "-DYOLO32_QUANTUM_US=200", "-DYOLO32_SCHED_ADAPTIVE=0",
                         "-DYOLO32_RESIZE_BATCH=1", "-DYOLO32_RESIZE_ROWS=0", "-DYOLO32_CREDIT_QUERY=1",
                         "-DYOLO32_PACKET_DISPATCH=1", "-DYOLO32_DIAGNOSTIC_BUILD=0",
                         "-DYOLOV5NU_GEMMINI_DIM=32", "-DYOLOV5NU_DIM16_WORKER_COUNT=3U"):
                name, value = flag[2:].split("=", 1)
                require(definitions.get(name) == value, f"{entry}: production flag mismatch: {name}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--tcl", action="store_true", help="Emit validated identity fields as a Tcl list")
    parser.add_argument("--firmware", action="store_true", help="Require software adapted to the current hardware ABI")
    parser.add_argument("--benchmark", action="store_true", help="Require the standalone V33 benchmark")
    args = parser.parse_args()
    try:
        product = json.loads(MANIFEST.read_text())
        if args.firmware:
            require(product["firmware_compatibility"]["status"] == "ready",
                    "Hardware frontend uses custom0/1/2; custom3 is control. "
                    "Realtime v26 Runtime adaptation is deferred; use make benchmark for standalone V33.")
        if args.benchmark:
            require(product["frontend_benchmark"]["status"] == "ready", "V33 benchmark is not ready")
        if args.tcl:
            validate(product, evaluate=False)
            # These values are list elements, never executable Tcl text.
            for key in ("hardware_alias", "soc_config", "collateral_directory"):
                require(re.fullmatch(r"[A-Za-z0-9_./-]+", product[key]), "Invalid Tcl field: " + key)
            print(" ".join(f"{key} {product[key]}" for key in
                           ("hardware_alias", "soc_config", "collateral_directory")))
        else:
            validate(product)
            print("CURRENT_PRODUCT=PASS triple32_v3_tensor frontend=3 workers=3 dim=32 credit=4")
            print("FIRMWARE_COMPATIBILITY=" + product["firmware_compatibility"]["status"])
    except (ValueError, KeyError, OSError, subprocess.CalledProcessError) as error:
        print(f"CURRENT_PRODUCT=FAIL {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
