#!/usr/bin/env python3
"""Install, generate and import the Taihang Tensor ingress without replacing existing configs."""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
PACKAGE = "tsmcchip.fpga.taihangsoc"
CONFIGS = {
    "dual16": "TaihangSoC1Rocket1RVV2Gemmini16x16PackedFullOps256BitTensorIngressConfig",
    "single4": "TaihangSoC1Rocket1RVV1Gemmini4x4PackedFullOps256BitTensorIngressConfig",
}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--chipyard", type=Path, default=Path("/home/wzr/chipyard"))
    parser.add_argument("--variant", choices=CONFIGS, default="dual16")
    parser.add_argument("--install-only", action="store_true")
    parser.add_argument("--emit-core", action="store_true")
    args = parser.parse_args()
    chipyard = args.chipyard.resolve()
    # Check before changing any files. Never replace the user's FPGA build block.
    build = chipyard / "build.sbt"
    text = build.read_text()
    marker = 'lazy val chipyard_fpga = (project in file("./fpga"))'
    start = text.index(marker)
    end = text.find("\nlazy val ", start + len(marker))
    end = len(text) if end < 0 else end
    block = text[start:end]
    if ".settings(chiselSettings)" not in block:
        needle = ".settings(commonSettings)"
        if block.count(needle) != 1:
            raise SystemExit("Unexpected chipyard_fpga build settings; inspect build.sbt first")
        block = block.replace(needle, needle + "\n  .settings(chiselSettings)")
        build.write_text(text[:start] + block + text[end:])
    source = ROOT / "tools/soc/taihang_tensor_ingress/TensorIngress.scala"
    dest = chipyard / "fpga/src/main/scala/taihang_soc/TensorIngress.scala"
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, dest)
    if args.install_only:
        return
    config = CONFIGS[args.variant]
    env = os.environ.copy()
    env.pop("JAVA_OPTS", None)
    env.pop("SBT_OPTS", None)
    with tempfile.TemporaryDirectory(prefix="tensor-ingress-sbt-") as runtime:
        env["XDG_RUNTIME_DIR"] = runtime
        # env.sh belongs to Chipyard; positional arguments avoid shell interpolation.
        subprocess.run(["bash", "-c", 'source ../env.sh; exec make SUB_PROJECT=taihang_soc "CONFIG=$1" verilog',
                        "tensor-ingress", config], cwd=chipyard / "fpga", env=env, check=True)
        if args.emit_core:
            core_dir = ROOT / "build/sim/tensor_ingress/core"
            core_dir.mkdir(parents=True, exist_ok=True)
            subprocess.run(["bash", "-c", 'source ../env.sh; exec java -cp ../.classpath_cache/chipyard_fpga.jar '
                            'tsmcchip.fpga.taihangsoc.EmitTaihangTensorIngressCore --target-dir "$1"',
                            "tensor-ingress-core", str(core_dir)], cwd=chipyard / "fpga", env=env, check=True)
    name = f"{PACKAGE}.TaihangSoCFPGATestHarness.{config}"
    generated = chipyard / "fpga/generated-src" / name
    target = ROOT / "hw/soc" / name
    if not (generated / "gen-collateral/TaihangSoCFPGATestHarness.sv").exists():
        raise SystemExit("Generation did not produce the expected harness")
    # Freeze production collateral and useful metadata, not the 150MB FIRRTL
    # intermediate or file lists referring back to this machine's Chipyard.
    target.mkdir(parents=True, exist_ok=True)
    shutil.copytree(generated / "gen-collateral", target / "gen-collateral", dirs_exist_ok=True)
    for artifact in generated.iterdir():
        if artifact.is_file() and artifact.suffix in {".json", ".dts", ".h"}:
            shutil.copy2(artifact, target / artifact.name)
    subprocess.run(["make", "check", f"SOC_CONFIG={name}"], cwd=ROOT, check=True)
    print(f"SOC_CONFIG={name}")


if __name__ == "__main__":
    main()
