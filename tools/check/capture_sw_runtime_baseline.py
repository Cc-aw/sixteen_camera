#!/usr/bin/env python3
"""Capture the R0 software baseline without touching FPGA or production code.

Run from the repository with local tool overrides in tools/config/tools.local.mk.
Logs, artifacts, flags and machine details remain under ignored build/.
A passing characterization may expose a failed safety invariant; both are recorded.
"""
from datetime import datetime, timezone
from pathlib import Path
import argparse
import hashlib
import json
import platform
import re
import shutil
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[2]
VARIANTS = ("dual16", "single4", "triple32_v3_tensor")
CONFIG_VARIABLES = (
    "TOOLCHAIN", "CC", "ARCH_FLAGS", "CFLAGS", "VENDOR_CFLAGS", "LDFLAGS", "LDLIBS",
    "AI_MODEL", "MODEL_WORKERS", "MODEL_DIM", "GEMMINI_PARAMS", "V17A_PARAMS",
    "V17A_FLAGS", "V17A_CFLAGS", "TENSOR_INGRESS_STATS", "BANDWIDTH_DIAGNOSTIC",
    "LOCAL_SOURCES", "BOARD_SOURCES", "VENDOR_SOURCES", "MODEL_OBJECT", "OBJECTS",
)


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def save_json(path, value):
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + "\n")


def query_make(directory, variables, assignments=()):
    recipe = "r0-capture-config: ; @" + "".join(
        f"$(info R0_{name}=$({name}))" for name in variables) + "true"
    completed = subprocess.run(["make", "-s", "-C", str(directory), *assignments,
                                "--eval", recipe, "r0-capture-config"],
                               capture_output=True, text=True, check=True)
    return dict(line[3:].split("=", 1) for line in completed.stdout.splitlines()
                if line.startswith("R0_") and "=" in line)


def source_inventory():
    paths = [ROOT / "sw/src/main.c", ROOT / "sw/Makefile",
             ROOT / "sw/src/platform/platform.h", ROOT / "sw/src/platform/cache_ops.c",
             ROOT / "sw/src/platform/tensor_ingress.h"]
    for directory in ("sw/src/ai", "sw/models/yolov5nu/triple32", "sw/models/yolov5nu/runtime"):
        paths.extend(p for p in (ROOT / directory).rglob("*")
                     if p.is_file() and p.suffix in (".c", ".h", ".S", ".inc", ".mk", ".py")
                     and "__pycache__" not in p.parts and "tests" not in p.parts)
    inventory = []
    for path in sorted(set(paths)):
        text = path.read_text()
        inventory.append({
            "path": str(path.relative_to(ROOT)), "sha256": digest(path),
            "lines": len(text.splitlines()), "bytes": path.stat().st_size,
            "quoted_includes": re.findall(r'^\s*#include\s+"([^"]+)"', text, re.M),
        })
    return inventory


def snapshot_artifacts(output, config, compiler_prefix):
    source_dir = ROOT / "build/firmware" / (config + "_video" if config != "triple32_v3_tensor" else config)
    stem = "firmware" if config != "triple32_v3_tensor" else "hdmi_tx_test"
    if config == "benchmark":
        source_dir = ROOT / "build/firmware/triple32_v17a_benchmark"
        stem = "yolo32"
    target = output / "artifacts" / config
    target.mkdir(parents=True)
    records = []
    for extension in (".elf", ".map"):
        source = source_dir / (stem + extension)
        if not source.is_file():
            raise FileNotFoundError(source)
        dest = target / source.name
        shutil.copy2(source, dest)
        records.append({"path": str(dest.relative_to(output)), "source": str(source.relative_to(ROOT)),
                        "bytes": dest.stat().st_size, "sha256": digest(dest)})
    elf = target / (stem + ".elf")
    disassembly = target / (stem + ".dis")
    with disassembly.open("w") as handle:
        subprocess.run([compiler_prefix + "objdump", "-d", "-S", str(elf)], stdout=handle, check=True)
    records.append({"path": str(disassembly.relative_to(output)), "bytes": disassembly.stat().st_size,
                    "sha256": digest(disassembly)})
    for pattern in ("v17a/*.stamp", "v17a/*.json", "*.json"):
        for source in source_dir.glob(pattern):
            dest = target / source.relative_to(source_dir)
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, dest)
            records.append({"path": str(dest.relative_to(output)), "source": str(source.relative_to(ROOT)),
                            "bytes": dest.stat().st_size, "sha256": digest(dest)})
    dependency_paths = set()
    for dep in source_dir.rglob("*.d"):
        words = dep.read_text().replace("\\\n", " ").split()
        for word in words:
            if word.endswith(":"):
                continue
            path = Path(word)
            if not path.is_absolute():
                path = ROOT / "sw" / path
            path = path.resolve()
            if path.is_relative_to(ROOT) and path.is_file():
                dependency_paths.add(path)
    save_json(target / "source-dependencies.json", [
        {"path": str(path.relative_to(ROOT)), "sha256": digest(path)} for path in sorted(dependency_paths)])
    return records


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
    output = (args.output or ROOT / "build/runtime-refactor/r0" / stamp).resolve()
    if not output.is_relative_to(ROOT / "build"):
        parser.error("--output must be under the ignored repository build directory")
    output.mkdir(parents=True, exist_ok=False)
    (output / "logs").mkdir()
    root_vars = query_make(ROOT, ("TOOLCHAIN", "VIVADO_BIN"))
    prefix = root_vars.get("TOOLCHAIN") or "riscv64-unknown-elf-"
    commit = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    report = {
        "created_utc": datetime.now(timezone.utc).isoformat(), "baseline_commit": commit,
        "branch": subprocess.check_output(["git", "branch", "--show-current"], cwd=ROOT, text=True).strip(),
        "initial_status": subprocess.check_output(["git", "status", "--short"], cwd=ROOT, text=True),
        "environment": {"platform": platform.platform(), "python": sys.version,
                        "toolchain_prefix": prefix, "tools": {}},
        "checks": [], "artifacts": {}, "safety_invariants": [],
        "board_validation": "NOT_RUN", "full_synthesis_implementation": "NOT_RUN",
    }
    for name, command in {
        "make": ["make", "--version"], "host_cc": ["cc", "--version"],
        "riscv_elf_gcc": [prefix + "gcc", "--version"],
        "riscv_linux_gcc": [prefix.removesuffix("riscv64-unknown-elf-") + "riscv64-unknown-linux-gnu-gcc", "--version"],
        "qemu": ["qemu-riscv64", "--version"],
    }.items():
        try:
            value = subprocess.run(command, capture_output=True, text=True, timeout=30)
            report["environment"]["tools"][name] = {
                "command": command, "returncode": value.returncode,
                "version": (value.stdout or value.stderr).splitlines()[:2]}
        except (FileNotFoundError, subprocess.TimeoutExpired) as error:
            report["environment"]["tools"][name] = {"status": "UNAVAILABLE", "reason": str(error)}
    configs = {}
    for variant in VARIANTS:
        suffix = variant + "_video" if variant != "triple32_v3_tensor" else variant
        build = ROOT / "build/firmware" / suffix
        stem = "firmware" if variant != "triple32_v3_tensor" else "hdmi_tx_test"
        configs[variant] = query_make(ROOT / "sw", CONFIG_VARIABLES, (
            f"SOC_VARIANT={variant}", f"BUILD={build}", f"TARGET={build / stem}",
            f"TOOLCHAIN={prefix}", f"TENSOR_INGRESS_STATS={int(variant == 'triple32_v3_tensor')}",
        ))
    configs["benchmark"] = query_make(ROOT / "sw/models/yolov5nu/triple32", CONFIG_VARIABLES, (f"TOOLCHAIN={prefix}",))
    save_json(output / "build-configurations.json", configs)
    save_json(output / "source-inventory.json", source_inventory())
    checks = [
        ("manifest_default", ["make", "check"], None),
        ("manifest_v3", ["make", "check", "SOC_VARIANT=triple32_v3_tensor"], None),
        ("dependencies", ["make", "check-deps", "SOC_VARIANT=triple32_v3_tensor"], None),
        ("runtime_host", ["make", "test-runtime"], None),
        ("abi_host_rv64", ["make", "test-runtime-abi"], None),
        ("software_host", ["make", "test-software"], None),
        ("v17a", ["make", "test-v17a"], None),
        ("benchmark", ["make", "firmware-benchmark"], "benchmark"),
        *[(f"firmware_{v}", ["make", "firmware", f"SOC_VARIANT={v}"], v) for v in VARIANTS],
        ("elf_audit", ["make", "check-v17a-firmware"], None),
        ("identity_trace", ["bash", "tests/host/run_runtime_baseline_trace_test.sh"], None),
        ("version_wrap", ["bash", "tests/host/run_runtime_version_baseline_test.sh"], None),
        ("dependencies_final", ["make", "check-deps", "SOC_VARIANT=triple32_v3_tensor"], None),
    ]
    for name, command, artifacts in checks:
        log = output / "logs" / (name + ".log")
        print(f"R0_CHECK_BEGIN={name}", flush=True)
        start = time.monotonic()
        try:
            with log.open("w") as handle:
                result = subprocess.run(command, cwd=ROOT, stdout=handle, stderr=subprocess.STDOUT, timeout=600)
            code = result.returncode
            status = "PASS" if code == 0 else "FAIL"
        except subprocess.TimeoutExpired:
            code, status = None, "FAIL_TIMEOUT"
        text = log.read_text(errors="replace")
        skips = [line.strip() for line in text.splitlines() if "SKIP" in line or "skipped" in line]
        record = {"name": name, "command": command, "status": status, "returncode": code,
                  "elapsed_seconds": round(time.monotonic() - start, 3),
                  "log": str(log.relative_to(output)), "log_sha256": digest(log), "skips": skips}
        report["checks"].append(record)
        if name == "v17a":
            match = re.search(r"Ran (\d+) tests", text)
            if match:
                record["unittest_count"] = int(match[1])
            record["riscv_live_context"] = "PASS" if "V17A_LIVE_RISCV_CONTEXT=PASS" in text else "NOT_CONFIRMED"
        if name == "identity_trace" and "R0_KNOWN_GAP=" in text:
            report["safety_invariants"].append({
                "name": "abort_success_requires_compute_stop_proof", "status": "FAIL",
                "evidence": str(log.relative_to(output)),
                "reason": "After rejected abort and ERROR polling, abort returns zero while the model/task double still owns execution."})
        if name == "version_wrap" and "R0_KNOWN_GAP=" in text:
            report["safety_invariants"].append({
                "name": "new_frame_version_wrap_is_not_stale", "status": "FAIL",
                "evidence": str(log.relative_to(output)),
                "reason": "Production runtime releases version 1/frame 101 as stale after version UINT32_MAX/frame 100."})
        if artifacts and status == "PASS":
            try:
                report["artifacts"][artifacts] = snapshot_artifacts(output, artifacts, prefix)
            except (FileNotFoundError, subprocess.CalledProcessError) as error:
                record["status"] = "FAIL_ARTIFACT_CAPTURE"
                record["error"] = str(error)
        save_json(output / "summary.json", report)
        print(f"R0_CHECK_END={name} status={record['status']}", flush=True)
    report["checks_passed"] = all(c["status"] == "PASS" for c in report["checks"])
    report["safety_passed"] = not any(c["status"] == "FAIL" for c in report["safety_invariants"])
    save_json(output / "summary.json", report)
    print(f"R0_REPORT={output / 'summary.json'}", flush=True)
    print(f"R0_CHECKS_PASSED={int(report['checks_passed'])} R0_SAFETY_PASSED={int(report['safety_passed'])}", flush=True)
    return 0 if report["checks_passed"] else 1


if __name__ == "__main__":
    sys.exit(main())
