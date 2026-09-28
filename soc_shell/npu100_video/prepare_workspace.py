#!/usr/bin/env python3
"""Copy build sources into a new workspace; never overlay the reference tree."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument("--reference", type=Path, default=Path("/home/wzr/chipyard"))
parser.add_argument("--destination", type=Path, required=True)
args = parser.parse_args()
reference = args.reference.resolve()
destination = args.destination.resolve()
if destination == reference or reference in destination.parents:
    raise SystemExit("Workspace must be outside the reference checkout")
if destination.exists():
    raise SystemExit("Use a new destination; refusing to overwrite an existing tree")
for name in ("build.sbt", "fpga/Makefile", "generators/rocket-chip/src/main/scala/tile/LazyRoCC.scala"):
    if not (reference / name).is_file():
        raise SystemExit("Missing reference input: " + name)
destination.mkdir(parents=True)
excludes = ["target", "generated-src", "output", "software", "obj_dir", ".Xil",
            ".git/", "*.log", "*.vcd", "*.vpd", "*.dcp", "*.bit", "*.zip",
            "*.tar", "*.tar.gz", "*.runs", "*.gen", "*.cache", "*.sim",
            ".classpath_cache", "build", "test_run_dir", ".*backup*",
            ".write_test", "ara/hardware/tb/dpi/elfloader.cc"]
for name in ("project", "scripts", "generators", "fpga", "tools",
             "sims/firesim/sim/firesim-lib", "sims/firesim/sim/midas/targetutils"):
    src = reference / name
    if not src.exists():
        continue
    dst = destination / name
    dst.mkdir(parents=True, exist_ok=True)
    subprocess.run(["rsync", "-rltL", *[f"--exclude={x}" for x in excludes],
                    str(src) + "/", str(dst) + "/"], check=True)
for src in reference.iterdir():
    if src.is_file() and (src.suffix in (".sbt", ".mk") or src.name == "Makefile"):
        shutil.copy2(src, destination / src.name)

# These immutable executables are shared; source files and all build output
# are private copies. Do not source the reference's absolute-path env.sh.
for name in (".conda-env", ".local", ".local-espresso"):
    if (reference / name).exists():
        (destination / name).symlink_to(reference / name, target_is_directory=True)
for name in (".ivy2", ".sbt"):
    if (reference / name).exists():
        subprocess.run(["cp", "-a", "--reflink=auto", str(reference / name),
                        str(destination / name)], check=True)
cache = Path.home() / ".cache/coursier"
if cache.exists():
    subprocess.run(["cp", "-a", "--reflink=auto", str(cache),
                    str(destination / ".coursier")], check=True)
(destination / ".java_tmp").mkdir()

# Limit board-specific sources at the actual project definitions. Settings in
# a separate .sbt file can be overridden by the reference's explicit Projects.
build_file = destination / "build.sbt"
build_text = build_file.read_text()
anchor = '''lazy val chipyard_fpga = (project in file("./fpga"))
  .dependsOn(chipyard, fpga_shells)
  .settings(commonSettings)'''
assert build_text.count(anchor) == 1
build_text = build_text.replace(anchor, anchor + '''
  .settings(Compile / unmanagedSources ~= (_.filter { f =>
    f.getPath.contains("/xcvu13p_gemmini_64x64_packed_inference_ram/") ||
    f.getPath.endsWith("/taihang_soc/Npu100Video.scala")
  }))''')
anchor = '''      }.filter(_.exists)
  )'''
assert build_text.count(anchor) == 1
build_text = build_text.replace(anchor, '''      }.filter(_.exists).filterNot(_.getPath.endsWith("generators/gemmini/chipyard"))
  )''')
build_file.write_text(build_text)

# Record the source snapshot independently of the reference's Git state.
# Copied .git files only preserve SBT's initialized-submodule discovery;
# this is a build snapshot and is not a Git worktree.
sources = sorted(p for p in destination.rglob("*.scala") if p.is_file())
manifest = "".join(hashlib.sha256(p.read_bytes()).hexdigest() + "  " +
                   str(p.relative_to(destination)) + "\n" for p in sources)
(destination / "REFERENCE_SCALA.sha256").write_text(manifest)
(destination / ".npu100-video-workspace.json").write_text(json.dumps({
    "reference": str(reference), "workspace": str(destination),
    "scala_manifest_sha256": hashlib.sha256(manifest.encode()).hexdigest(),
    "rocket_chip_policy": "preserve complete reference revision",
}, indent=2) + "\n")
print("NPU100_VIDEO_WORKSPACE=" + str(destination))
