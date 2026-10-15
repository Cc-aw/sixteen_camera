#!/usr/bin/env python3
"""Run synchronous secondary-pool, coherent L2 and vendor DDR slice tests."""
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


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--workspace", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--targets", nargs="+", choices=["pool", "cache", "ddr"],
                        default=["pool", "cache", "ddr"])
    parser.add_argument("--vivado", type=Path, default=Path(os.environ.get(
        "VIVADO_BIN", shutil.which("vivado") or "vivado")))
    args = parser.parse_args()
    cy = args.workspace.resolve()
    generator.validate_workspace_sources(cy)
    out = args.output.resolve()
    out.mkdir(parents=True, exist_ok=False)
    env = generator.environment(cy)
    env.pop("JAVA_TOOL_OPTIONS", None)
    env["CHISEL_FIRTOOL_PATH"] = str(cy / ".conda-env/riscv-tools/bin")
    env["MAKEFLAGS"] = env.get("MAKEFLAGS", "") + " VK_PCH_I_FAST= VK_PCH_I_SLOW="
    verilator = shutil.which("verilator")
    if not verilator:
        raise SystemExit("verilator is required")
    env["PATH"] = str(Path(verilator).parent) + ":" + env["PATH"]

    def run(cmd, directory, logname):
        with (directory / logname).open("w") as log:
            subprocess.run(list(map(str, cmd)), cwd=directory, env=env,
                           stdout=log, stderr=subprocess.STDOUT, check=True)

    classes = out / "classes"
    classes.mkdir()
    jar = cy / ".classpath_cache/chipyard_fpga.jar"
    cache = cy / ".coursier/v1/https/repo1.maven.org/maven2"
    java = cy / ".conda-env/lib/jvm/bin/java"
    compiler = cache / "org/scala-lang/scala-compiler/2.13.16/scala-compiler-2.13.16.jar"
    plugin = cache / "org/chipsalliance/chisel-plugin_2.13.16/6.7.0/chisel-plugin_2.13.16-6.7.0.jar"
    tests = {"pool": "RegisteredListBufferTest", "cache": "TimingCacheTest"}
    selected = [name for target, name in tests.items() if target in args.targets]
    if selected:
        run([java, "-Xmx4G", "-cp", f"{compiler}:{jar}", "scala.tools.nsc.Main",
             "-classpath", jar, f"-Xplugin:{plugin}", "-language:reflectiveCalls",
             "-d", classes, *[ROOT / f"tests/rtl/scala/{name}.scala" for name in selected]],
            out, "compile.log")
    for name in selected:
        dest = out / name
        dest.mkdir()
        run([java, "-Xmx6G", "-XX:ActiveProcessorCount=4", "-cp", f"{classes}:{jar}",
             "autonomoustest." + name, "sim"], dest, "console.log")
        print(name + "=PASS", flush=True)
    if "ddr" in args.targets:
        ip = args.vivado.resolve().parent.parent / "data/ip/xilinx"
        for mode in (7, 1):
            dest = out / f"ddr_mode{mode}"
            dest.mkdir()
            run([verilator, "--binary", "--timing", "--assert", "-Wno-fatal", "-j", "2",
                 "--top-module", "tb_ddr_register_slice", f"-GMODE={mode}", "--Mdir", dest / "obj",
                 "-I" + str(ip / "axi_infrastructure_v1_1/hdl"),
                 ip / "axi_register_slice_v2_1/hdl/axi_register_slice_v2_1_vl_rfs.v",
                 ROOT / "tests/rtl/benches/timing/tb_ddr_register_slice.sv"], dest, "compile.log")
            run([dest / "obj/Vtb_ddr_register_slice"], dest, "console.log")
            result = (dest / "console.log").read_text()
            if "DDR_REGISTER_SLICE_PASS" not in result:
                raise SystemExit("DDR register-slice test did not finish")
            print(result.strip(), flush=True)
    print("V3_TIMING_REPAIR_TESTS=PASS", flush=True)


if __name__ == "__main__":
    main()
