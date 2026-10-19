#!/usr/bin/env python3
"""Generate the four-mode DMA load SoC from feature-local sources; private output only."""
import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess

FEATURE = Path(__file__).resolve().parents[1]
ROOT = FEATURE.parents[2]
SHELL = FEATURE / "soc_shell"
BASE = SHELL / "npu100_video"
V3 = SHELL / "memory_parallel_v3"
FRONTEND = FEATURE / "command_frontend"
TENSOR = FEATURE / "tensor_ingress/TensorIngress.scala"
VARIANT = "dma_load_streaming_512kib_2bank"
CONFIG = "TaihangSoC1Rocket1RVV3Gemmini32x32MemoryParallelV3TensorIngress2BankDmaLoadConfig"
NAME = "tsmcchip.fpga.taihangsoc.TaihangSoCFPGATestHarness." + CONFIG


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def validate_workspace_sources(workspace):
    """Resume only a workspace carrying the current effective source overlays."""
    marker = workspace / ".triple32-v3-tensor.json"
    if not marker.is_file():
        raise SystemExit("Workspace was not prepared by this feature entry point")
    prepared = json.loads(marker.read_text())
    if prepared.get("hardware_variant") != VARIANT or prepared.get("config") != NAME:
        raise SystemExit("Workspace belongs to a different hardware variant")
    if digest(workspace / "build.sbt") != prepared.get("build_sbt_sha256"):
        raise SystemExit("Prepared workspace build.sbt changed")
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
    expected["fpga/src/main/scala/taihang_soc/TensorIngress.scala"] = TENSOR
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
    shutil.copy2(TENSOR, taihang)
    shutil.copytree(FRONTEND / "integration", workspace, dirs_exist_ok=True)
    frontend_package = workspace / "generators/rocket-chip/src/main/scala/tile/commandfrontend"
    frontend_package.mkdir(parents=True, exist_ok=True)
    for path in (FRONTEND / "scala").glob("*.scala"):
        shutil.copy2(path, taihang if path.name == "CommandFrontendConfig.scala" else frontend_package)
    (workspace / ".triple32-v3-tensor.json").write_text(json.dumps({
        "config": NAME, "hardware_variant": VARIANT,
        "build_sbt_sha256": digest(build), "reference": str(reference),
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


def generate(workspace, output=None, streaming=True):
    if not (workspace / ".triple32-v3-tensor.json").is_file():
        raise SystemExit("Workspace was not prepared by this entry point")
    validate_workspace_sources(workspace)
    config, name = CONFIG, NAME
    l2_banks, dma_load_runtime = 2, True
    generated = Path(output).resolve() if output else workspace / "fpga/generated-src" / name
    if output and generated.exists():
        raise SystemExit("Use a new directory for explicit candidate output")
    origin_snapshot = (FEATURE / "manifests/SOURCE_ORIGINS.json").read_bytes()
    generator_snapshot = Path(__file__).read_bytes()
    env = environment(workspace)
    before_sources = {str(p.relative_to(workspace)): digest(p) for p in workspace.rglob("*.scala")
                      if p.is_file() and "target" not in p.parts}
    identity = hashlib.sha256(json.dumps(dict(config=name, sources=before_sources,
        build_sbt_sha256=digest(workspace / "build.sbt"), dma_load_streaming_enable=streaming), sort_keys=True).encode()).hexdigest()
    if dma_load_runtime:
        env['DMA_LOAD_BUILD_ID'] = identity[:16]
        env['DMA_LOAD_STREAMING'] = '1' if streaming else '0'
    subprocess.run(["make", "-C", str(workspace / "fpga"), "-W", str(workspace / "build.sbt"),
                    "verilog", "SUB_PROJECT=taihang_soc", "SBT_PROJECT=chipyard_fpga",
                    "MODEL=TaihangSoCFPGATestHarness", "VLOG_MODEL=TaihangSoCFPGATestHarness",
                    "MODEL_PACKAGE=tsmcchip.fpga.taihangsoc", "CONFIG_PACKAGE=tsmcchip.fpga.taihangsoc",
                    f"CONFIG={config}", "GENERATOR_PACKAGE=chipyard", "TOP=ChipTop", "TB=none"] +
                   ([f"build_dir={generated}"] if output else []),
                   env=env, check=True)
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
    subprocess.run(["python3", str(FEATURE / "scripts/check_rtl.py"), str(rtl),
                    "--l2-banks", str(l2_banks)] + (["--dma-load-runtime"] if dma_load_runtime else []), check=True)
    sources = {str(p.relative_to(workspace)): digest(p) for p in workspace.rglob("*.scala") if p.is_file() and "target" not in p.parts}
    if sources != before_sources:
        raise SystemExit("Generation sources changed during elaboration")
    context = {
        "hardware_variant": VARIANT,
        "feature_source_origins_sha256": hashlib.sha256(origin_snapshot).hexdigest(),
        "feature_source_origins_snapshot": "FEATURE_SOURCE_ORIGINS.json",
        "feature_generator_sha256": hashlib.sha256(generator_snapshot).hexdigest(),
        "feature_generator_snapshot": "FEATURE_GENERATOR.py",
        "config": name, "generated_at_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "source_workspace": str(workspace), "build_sbt_sha256": digest(workspace / "build.sbt"),
        "effective_scala": sources, "l2_banks": l2_banks,
        "l2_capacity_kib": l2_banks * 256,
        "dma_load_runtime_enable": dma_load_runtime,
        "dma_load_streaming_enable": streaming,
        "dma_load_pipeline_version": "row_ready_v1" if streaming else "buffered_control",
        "dma_load_cross_command_write_combining_enable": False,
        "dma_load_supported_modes": ["legacy", "read_coalesced", "read_assembled", "spad_assembled"] if dma_load_runtime else ["legacy"],
        "dma_load_reset_mode": "legacy", "dma_load_control_version": 1 if dma_load_runtime else 0,
        "dma_load_build_id": identity[:16] if dma_load_runtime else None,
        "source_identity_sha256": identity,
        "scala_snapshot_scope": "Prepared-workspace Scala files excluding target; build.sbt source filters govern compilation",
        "raw_rtl_sha256": raw_hashes,
        "final_rtl_sha256": {str(p.relative_to(rtl)): digest(p) for p in rtl.rglob("*") if p.is_file()},
    }
    if (origin_snapshot != (FEATURE / "manifests/SOURCE_ORIGINS.json").read_bytes() or
            generator_snapshot != Path(__file__).read_bytes()):
        raise SystemExit("Feature generation provenance changed during elaboration")
    (generated / "FEATURE_SOURCE_ORIGINS.json").write_bytes(origin_snapshot)
    (generated / "FEATURE_GENERATOR.py").write_bytes(generator_snapshot)
    (generated / "GENERATION_CONTEXT.json").write_text(json.dumps(context, indent=2) + "\n")
    print("SOC_CANDIDATE_RTL=" + str(rtl))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--reference", type=Path,
                        default=Path(os.environ["SOC_REFERENCE"]) if os.environ.get("SOC_REFERENCE") else None)
    parser.add_argument("--workspace", type=Path, required=True)
    actions = parser.add_mutually_exclusive_group()
    actions.add_argument("--prepare-only", action="store_true")
    actions.add_argument("--resume", action="store_true")
    actions.add_argument("--validate-workspace-only", action="store_true")
    parser.add_argument("--output", type=Path, help="New private candidate output directory")
    parser.add_argument("--buffered", action="store_true", help="Disable A1 for an otherwise identical elaboration control")
    args = parser.parse_args()
    workspace = args.workspace.resolve()
    protected = (ROOT / "hw/soc", ROOT / "hw/versions")
    for path in (workspace, args.output.resolve() if args.output else workspace):
        if any(path == base or base in path.parents for base in protected):
            parser.error("Workspace and output must be outside hw/soc and hw/versions")
    subprocess.run(["python3", "-B", str(FEATURE / "scripts/audit.py")], check=True)
    if args.validate_workspace_only:
        validate_workspace_sources(workspace)
        print("DMA_LOAD_VARIANT_WORKSPACE=PASS workspace=" + str(workspace))
        return
    if not args.resume:
        if args.reference is None:
            parser.error("Set --reference or SOC_REFERENCE to the reference Chipyard")
        prepare(args.reference.resolve(), workspace)
        validate_workspace_sources(workspace)
    if not args.prepare_only:
        generate(workspace, output=args.output, streaming=not args.buffered)


if __name__ == "__main__":
    main()
