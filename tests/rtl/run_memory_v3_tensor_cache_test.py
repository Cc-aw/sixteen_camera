#!/usr/bin/env python3
"""Test the rebuilt writer with the real V3 two-bank L2 and 512-bit outer bus."""
import argparse
import importlib.util
import os
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("v3_generator", ROOT / "tools/soc/build_triple32_v3_tensor.py")
generator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(generator)
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--workspace", type=Path, required=True)
args = parser.parse_args()
cy = args.workspace.resolve()
generator.validate_workspace_sources(cy)
out = ROOT / "build/sim/memory_v3_tensor_cache"
(out / "classes").mkdir(parents=True, exist_ok=True)
shutil.copy2(cy / ".classpath_cache/chipyard_fpga.jar", out / "dependencies.jar")
jar = out / "dependencies.jar"
cache = cy / ".coursier/v1/https/repo1.maven.org/maven2"
compiler = cache / "org/scala-lang/scala-compiler/2.13.16/scala-compiler-2.13.16.jar"
plugin = cache / "org/chipsalliance/chisel-plugin_2.13.16/6.7.0/chisel-plugin_2.13.16-6.7.0.jar"
java = cy / ".conda-env/lib/jvm/bin/java"
env = generator.environment(cy)
env.pop("JAVA_TOOL_OPTIONS", None)
vbin = shutil.which("verilator")
env["PATH"] = str(Path(vbin).parent) + ":" + env["PATH"]
env["CHISEL_FIRTOOL_PATH"] = str(cy / ".conda-env/riscv-tools/bin")
env["MAKEFLAGS"] = os.environ.get("MAKEFLAGS", "") + " VK_PCH_I_FAST= VK_PCH_I_SLOW="
subprocess.run([str(java), "-Xmx4G", "-cp", f"{compiler}:{jar}", "scala.tools.nsc.Main",
                "-classpath", str(jar), f"-Xplugin:{plugin}", "-language:reflectiveCalls",
                "-d", str(out / "classes"), str(ROOT / "tests/rtl/scala/MemoryV3TensorTest.scala")],
               env=env, check=True)
subprocess.run([str(java), "-Xmx6G", "-XX:ActiveProcessorCount=4", "-cp", f"{out / 'classes'}:{jar}",
                "memoryv3test.MemoryV3TensorTest", "sim"], cwd=out, env=env, check=True)
