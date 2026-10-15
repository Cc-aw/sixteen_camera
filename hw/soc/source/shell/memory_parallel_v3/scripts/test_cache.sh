#!/usr/bin/env bash
set -euo pipefail
v3=$(cd "$(dirname "$0")/.." && pwd)
cy=${CHIPYARD_ROOT:?}
out=$(realpath -m "${1:?new test output}")
mkdir -p "$out/classes"
cp --reflink=auto "$cy/.classpath_cache/chipyard_fpga.jar" "$out/dependencies.jar"
jar="$out/dependencies.jar"
test_name=${2:-MemoryV3Test}
cache="$cy/.coursier/v1/https/repo1.maven.org/maven2"
compiler="$cache/org/scala-lang/scala-compiler/2.13.16/scala-compiler-2.13.16.jar"
plugin="$cache/org/chipsalliance/chisel-plugin_2.13.16/6.7.0/chisel-plugin_2.13.16-6.7.0.jar"
java="$cy/.conda-env/lib/jvm/bin/java"
# Keep the Verilator driver and compiled binary from the same installed kit.
vbin=$(command -v verilator)
export PATH="$(dirname "$vbin"):$cy/.conda-env/bin:$cy/.local/bin:$PATH"
export CHISEL_FIRTOOL_PATH="$cy/.conda-env/riscv-tools/bin"
"$java" -Xmx12G -cp "$compiler:$jar" scala.tools.nsc.Main -classpath "$jar" \
  -Xplugin:"$plugin" -language:reflectiveCalls -d "$out/classes" "$v3/tests/$test_name.scala"
# chiseltest force-includes the DUT header before each translation unit.
# GCC cannot use a PCH after those declarations; disable only the PCH include.
export MAKEFLAGS="${MAKEFLAGS:-} VK_PCH_I_FAST= VK_PCH_I_SLOW="
cd "$out"
"$java" -Xmx16G -XX:ActiveProcessorCount=8 -cp "$out/classes:$jar" "memoryv3test.$test_name" sim
