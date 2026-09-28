#!/usr/bin/env bash
# Compile the complete source overlay against a read-only dependency assembly.
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
checkout=${CHIPYARD_ROOT:-/home/wzr/chipyard}
cache=${SCALA_CACHE:-"$HOME/.cache/coursier/v1/https/repo1.maven.org/maven2"}
java_bin=${JAVA_BIN:-"$checkout/.conda-env/lib/jvm/bin/java"}
assembly=${DEPENDENCY_ASSEMBLY:-"$checkout/.classpath_cache/chipyard_fpga.jar"}
compiler="$cache/org/scala-lang/scala-compiler/2.13.16/scala-compiler-2.13.16.jar"
plugin="$cache/org/chipsalliance/chisel-plugin_2.13.16/6.7.0/chisel-plugin_2.13.16-6.7.0.jar"
build=$(mktemp -d /tmp/npu100-video-validation.XXXXXX)
printf 'VALIDATION_DIR=%s\n' "$build"
for file in "$java_bin" "$assembly" "$compiler" "$plugin"; do test -f "$file"; done
mkdir "$build/classes"
cp --reflink=auto "$assembly" "$build/dependencies.jar"
assembly="$build/dependencies.jar"
python3 - "$root" "$build/sources.txt" "$checkout" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
folders = ("src/main/scala", "saturn/src/main/scala",
           "fpga/src/main/scala", "tests/scala")
files = sorted(p for folder in folders for p in (root / folder).rglob("*.scala"))
files.append(Path(sys.argv[3]) / "generators/rocket-chip/src/main/scala/tile/LazyRoCC.scala")
Path(sys.argv[2]).write_text("\n".join(map(str, files)) + "\n")
PY
"$java_bin" -XX:-UsePerfData -Xmx12G -cp "$compiler:$assembly" scala.tools.nsc.Main \
  -classpath "$assembly" -Xplugin:"$plugin" -language:reflectiveCalls \
  -d "$build/classes" @"$build/sources.txt" > "$build/compile.log" 2>&1
cp -a "$root/src/main/resources/." "$build/classes/"
export CHISEL_FIRTOOL_PATH=${CHISEL_FIRTOOL_PATH:-"$checkout/.conda-env/riscv-tools/bin"}
cd "$build"
"$java_bin" -XX:-UsePerfData -Xmx4G -cp "$build/classes:$assembly" \
  chipyard.fpga.xcvu13p_gemmini_64x64_packed_inference_ram.VideoSoCConfigTest
"$java_bin" -XX:-UsePerfData -Xmx4G -cp "$build/classes:$assembly" \
  freechips.rocketchip.tile.ReplayTest
python3 "$root/tests/check_config_0918.py"
printf 'NPU100_VIDEO_SOURCE=PASS\n'
