#!/usr/bin/env python3
"""Rebuild the V3 + Tensor SoC from frozen sources in a private Chipyard copy."""
import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[2]
SHELL = ROOT / "hw/soc/source/shell"
BASE = SHELL / "npu100_video"
V3 = SHELL / "memory_parallel_v3"
FRONTEND = ROOT / "hw/soc/source/command_frontend"
CONFIG = "TaihangSoC1Rocket1RVV3Gemmini32x32MemoryParallelV3TensorIngressConfig"
NAME = "tsmcchip.fpga.taihangsoc.TaihangSoCFPGATestHarness." + CONFIG


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def validate_workspace_sources(workspace):
    """Resume only a workspace carrying the current effective source overlays."""
    expected = {relative: SHELL / "reference" / relative for relative in
                json.loads((SHELL / "REFERENCE_MANIFEST.json").read_text()) if relative != "build.sbt"}
    for source, destination in [
        (BASE / "src/main/scala/gemmini", Path("generators/gemmini/src/main/scala/gemmini")),
        (BASE / "src/main/resources", Path("generators/gemmini/src/main/resources")),
        (BASE / "saturn/src/main/scala", Path("generators/saturn/src/main/scala")),
        (BASE / "fpga/src/main/scala/xcvu13p_gemmini_32x32_packed_inference_ram",
         Path("fpga/src/main/scala/xcvu13p_gemmini_32x32_packed_inference_ram")),
        (V3 / "chipyard", Path(".")),
        (V3 / "scala", Path("fpga/src/main/scala/xcvu13p_gemmini_32x32_packed_inference_ram")),
        (FRONTEND / "integration", Path(".")),
        (FRONTEND / "scala", Path("generators/rocket-chip/src/main/scala/tile/commandfrontend")),
    ]:
        for path in source.rglob("*"):
            if path.is_file():
                expected[str(destination / path.relative_to(source))] = path
    expected.pop("generators/rocket-chip/src/main/scala/tile/commandfrontend/CommandFrontendConfig.scala")
    expected["fpga/src/main/scala/taihang_soc/CommandFrontendConfig.scala"] = FRONTEND / "scala/CommandFrontendConfig.scala"
    expected["fpga/src/main/scala/taihang_soc/TensorIngress.scala"] = (
        ROOT / "hw/soc/source/tensor_ingress/TensorIngress.scala")
    expected["fpga/src/main/scala/taihang_soc/Npu100Video.scala"] = (
        BASE / "fpga/src/main/scala/taihang_soc/Npu100Video.scala")
    for relative, source in expected.items():
        target = workspace / relative
        if not target.is_file() or digest(target) != digest(source):
            raise SystemExit("Stale generation workspace source: " + relative +
                             "; prepare a new workspace from the current shell")


def prepare(reference, workspace):
    # All writes belong to the private copy, including SBT and generator output.
    if workspace == reference or reference in workspace.parents:
        raise SystemExit("Use a new workspace outside the reference Chipyard")
    subprocess.run(["python3", str(BASE / "prepare_workspace.py"), "--reference",
                    str(reference), "--destination", str(workspace), "--copy-only"], check=True)
    manifest = json.loads((SHELL / "REFERENCE_MANIFEST.json").read_text())
    for relative, expected in manifest.items():
        source = SHELL / "reference" / relative
        if digest(source) != expected:
            raise SystemExit("Frozen reference changed: " + relative)
        target = workspace / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
    # The frozen build.sbt is subsequently narrowed to this shell's packages.
    build = workspace / "build.sbt"
    text = build.read_text()
    anchor = 'lazy val chipyard_fpga = (project in file("./fpga"))\n  .dependsOn(chipyard, fpga_shells)\n  .settings(commonSettings)'
    if text.count(anchor) != 1:
        raise SystemExit("Unsupported FPGA SBT project definition")
    text = text.replace(anchor, anchor + '''
  .settings(chiselSettings)
  .settings(Compile / unmanagedSources ~= (_.filter { f =>
    f.getPath.contains("/xcvu13p_gemmini_32x32_packed_inference_ram/") ||
    f.getPath.endsWith("/taihang_soc/Npu100Video.scala") ||
    f.getPath.endsWith("/taihang_soc/TensorIngress.scala") ||
    f.getPath.endsWith("/taihang_soc/CommandFrontendConfig.scala")
  }))''')
    needle = '      }.filter(_.exists)\n  )'
    if text.count(needle) != 1:
        raise SystemExit("Unsupported optional-generator source discovery")
    text = text.replace(needle, '      }.filter(_.exists).filterNot(_.getPath.endsWith("generators/gemmini/chipyard"))\n  )')
    build.write_text(text)
    gemmini = workspace / "generators/gemmini/src/main/scala/gemmini"
    shutil.rmtree(gemmini)
    shutil.copytree(BASE / "src/main/scala/gemmini", gemmini)
    shutil.copytree(BASE / "src/main/resources", workspace / "generators/gemmini/src/main/resources", dirs_exist_ok=True)
    shutil.copytree(BASE / "saturn/src/main/scala", workspace / "generators/saturn/src/main/scala", dirs_exist_ok=True)
    package = workspace / "fpga/src/main/scala/xcvu13p_gemmini_32x32_packed_inference_ram"
    shutil.copytree(BASE / "fpga/src/main/scala/xcvu13p_gemmini_32x32_packed_inference_ram", package, dirs_exist_ok=True)
    taihang = workspace / "fpga/src/main/scala/taihang_soc"
    taihang.mkdir(parents=True, exist_ok=True)
    shutil.copy2(BASE / "fpga/src/main/scala/taihang_soc/Npu100Video.scala", taihang)
    for path in (V3 / "chipyard").rglob("*"):
        if path.is_file():
            target = workspace / path.relative_to(V3 / "chipyard")
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(path, target)
    for path in (V3 / "scala").glob("*.scala"):
        shutil.copy2(path, package)
    shutil.copy2(ROOT / "hw/soc/source/tensor_ingress/TensorIngress.scala", taihang)
    shutil.copytree(FRONTEND / "integration", workspace, dirs_exist_ok=True)
    frontend_package = workspace / "generators/rocket-chip/src/main/scala/tile/commandfrontend"
    frontend_package.mkdir(parents=True, exist_ok=True)
    for path in (FRONTEND / "scala").glob("*.scala"):
        shutil.copy2(path, taihang if path.name == "CommandFrontendConfig.scala" else frontend_package)
    (workspace / ".triple32-v3-tensor.json").write_text(json.dumps({
        "config": NAME, "reference": str(reference),
        "created": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    }, indent=2) + "\n")


def environment(workspace):
    env = os.environ.copy()
    env.pop("JAVA_OPTS", None)
    env.pop("SBT_OPTS", None)
    env.pop("USE_CHISEL7", None)
    java_home = workspace / ".conda-env/lib/jvm"
    riscv = workspace / ".conda-env/riscv-tools"
    env.update(JAVA_HOME=str(java_home), RISCV=str(riscv),
               COURSIER_CACHE=str(workspace / ".coursier/v1"),
               XDG_RUNTIME_DIR=str(workspace / ".runtime"),
               JAVA_TOOL_OPTIONS=f"-Xmx{env.get('NPU_JAVA_HEAP', '16G')} -Xss8M -XX:ActiveProcessorCount={env.get('NPU_BUILD_CPUS', '8')} -Djava.io.tmpdir={workspace / '.java_tmp'}")
    env["PATH"] = ":".join(map(str, [java_home / "bin", workspace / ".conda-env/bin",
                            workspace / ".local/bin", workspace / ".local-espresso/bin",
                            riscv / "bin"])) + ":" + env["PATH"]
    (workspace / ".runtime").mkdir(exist_ok=True, mode=0o700)
    return env


def generate(workspace, export=True, l2_banks=4):
    if not (workspace / ".triple32-v3-tensor.json").is_file():
        raise SystemExit("Workspace was not prepared by this entry point")
    validate_workspace_sources(workspace)
    if export and l2_banks != 4:
        raise SystemExit("The two-bank fallback is a private --no-export candidate")
    config = CONFIG if l2_banks == 4 else CONFIG.replace("TensorIngressConfig", "TensorIngress2BankConfig")
    name = "tsmcchip.fpga.taihangsoc.TaihangSoCFPGATestHarness." + config
    env = environment(workspace)
    subprocess.run(["make", "-C", str(workspace / "fpga"), "-W", str(workspace / "build.sbt"),
                    "verilog", "SUB_PROJECT=taihang_soc", "SBT_PROJECT=chipyard_fpga",
                    "MODEL=TaihangSoCFPGATestHarness", "VLOG_MODEL=TaihangSoCFPGATestHarness",
                    "MODEL_PACKAGE=tsmcchip.fpga.taihangsoc", "CONFIG_PACKAGE=tsmcchip.fpga.taihangsoc",
                    f"CONFIG={config}", "GENERATOR_PACKAGE=chipyard", "TOP=ChipTop", "TB=none"],
                   env=env, check=True)
    generated = workspace / "fpga/generated-src" / name
    rtl = generated / "gen-collateral"
    raw_hashes = {str(p.relative_to(rtl)): digest(p) for p in rtl.rglob("*") if p.is_file()}
    for script in ["apply_xcvu13p_gemmini_32x32_acc256_wide_uram.sh", "apply_xcvu13p_soc_cache_bram.sh", "apply_result_bram.sh"]:
        subprocess.run(["bash", str(BASE / "fpga/scripts" / script), str(rtl)], env=env, check=True)
    headers = workspace / "generators/gemmini/software/gemmini-rocc-tests/include"
    (rtl / "include").mkdir(exist_ok=True)
    # Gemmini writes at Chipyard's root when its optional software tree is absent.
    generated_headers = [path for directory in (headers, workspace) for opcode in (0, 1, 2)
                         for path in directory.glob(f"gemmini_params_32x32*custom{opcode}_xcvu13p.h")]
    for header in generated_headers:
        shutil.copy2(header, rtl / "include" / header.name)
    subprocess.run(["python3", str(ROOT / "tools/check/check_triple32_v3_tensor.py"), str(rtl),
                    "--l2-banks", str(l2_banks)], check=True)
    sources = {str(p.relative_to(workspace)): digest(p) for p in workspace.rglob("*.scala") if p.is_file() and "target" not in p.parts}
    context = {
        "config": name, "generated_at_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "source_workspace": str(workspace), "build_sbt_sha256": digest(workspace / "build.sbt"),
        "effective_scala": sources, "l2_banks": l2_banks,
        "scala_snapshot_scope": "Prepared-workspace Scala files excluding target; build.sbt source filters govern compilation",
        "raw_rtl_sha256": raw_hashes,
        "final_rtl_sha256": {str(p.relative_to(rtl)): digest(p) for p in rtl.rglob("*") if p.is_file()},
    }
    if not export:
        (generated / "GENERATION_CONTEXT.json").write_text(json.dumps(context, indent=2) + "\n")
        print("SOC_CANDIDATE_RTL=" + str(rtl))
        return
    # Prepare a complete export before replacing the sole production tree.
    # Generated collateral is data; copying timestamps/xattrs for every file
    # is unnecessary and expensive on mediated/network filesystems.
    target = ROOT / "hw/soc" / NAME
    staged = ROOT / "build/soc_staging" / datetime.datetime.now().strftime("%Y%m%d_%H%M%S_%f") / NAME
    staged.mkdir(parents=True)
    shutil.copytree(rtl, staged / "gen-collateral", copy_function=shutil.copyfile)
    for path in generated.iterdir():
        if path.is_file() and path.suffix in {".json", ".dts", ".h", ".conf"}:
            shutil.copyfile(path, staged / path.name)
    (staged / "GENERATION_CONTEXT.json").write_text(json.dumps(context, indent=2) + "\n")
    if target.exists():
        backup = ROOT / "build/soc_backups" / datetime.datetime.now().strftime("%Y%m%d_%H%M%S_%f")
        backup.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(target), str(backup))
    shutil.move(str(staged), str(target))
    (SHELL / "V3_GENERATION_CONTEXT.json").write_text(json.dumps({
        key: context[key] for key in ("config", "generated_at_utc", "source_workspace", "build_sbt_sha256")
    }, indent=2) + "\n")
    (SHELL / "V3_EFFECTIVE_SCALA.sha256").write_text("".join(
        f"{value}  {key}\n" for key, value in sorted(sources.items())))
    print("SOC_CONFIG=" + NAME)


def emit_core(workspace):
    validate_workspace_sources(workspace)
    out = ROOT / "build/sim/triple32_v3_tensor/core"
    out.mkdir(parents=True, exist_ok=True)
    subprocess.run([str(workspace / ".conda-env/lib/jvm/bin/java"), "-cp",
                    str(workspace / ".classpath_cache/chipyard_fpga.jar"),
                    "tsmcchip.fpga.taihangsoc.EmitTaihangTensorIngressCore",
                    "--target-dir", str(out)], cwd=workspace, env=environment(workspace), check=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--reference", type=Path, default=Path(os.environ["SOC_REFERENCE"]) if os.environ.get("SOC_REFERENCE") else None)
    parser.add_argument("--workspace", type=Path, required=True)
    parser.add_argument("--prepare-only", action="store_true")
    parser.add_argument("--resume", action="store_true")
    parser.add_argument("--no-export", action="store_true",
                        help="Generate and check private candidate RTL without replacing the production export")
    parser.add_argument("--l2-banks", type=int, choices=(2, 4), default=4,
                        help="4: production 1 MiB; 2: saved 512 KiB fallback, requires --no-export")
    parser.add_argument("--emit-core-only", action="store_true", help="Emit a protocol-test core from this workspace's rebuilt assembly")
    args = parser.parse_args()
    workspace = args.workspace.resolve()
    if args.emit_core_only:
        if not (workspace / ".triple32-v3-tensor.json").is_file():
            raise SystemExit("Prepare and generate the merged workspace first")
        emit_core(workspace)
        return
    if not args.resume:
        if args.reference is None:
            raise SystemExit("Set --reference or SOC_REFERENCE to the reference Chipyard")
        prepare(args.reference.resolve(), workspace)
    if not args.prepare_only:
        generate(workspace, export=not args.no_export, l2_banks=args.l2_banks)


if __name__ == "__main__":
    main()
