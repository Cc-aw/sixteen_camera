#!/usr/bin/env python3
"""Prepare or run a wholly isolated V3 build using the passing V1 strategy."""
import argparse
import datetime
import importlib.util
import json
import os
from pathlib import Path
import resource
import shutil
import subprocess
import sys

V3 = Path(__file__).resolve().parents[1]
ROOT = V3.parents[1]
spec = importlib.util.spec_from_file_location("isolated", ROOT / "scripts/build_triple32_timing_v3_isolated.py")
isolated = importlib.util.module_from_spec(spec)
spec.loader.exec_module(isolated)

def replace_once(text, old, new):
    if text.count(old) != 1:
        raise RuntimeError("Baseline build script changed: " + old[:100])
    return text.replace(old, new, 1)

def prepare(export, results_root):
    results_root.resolve().relative_to(ROOT / "build")
    if "MemoryParallelV3Config" not in export.name:
        raise RuntimeError("Select the frozen MemoryParallelV3 SoC export")
    stamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S_%f")
    results = results_root.resolve() / stamp
    results.mkdir(parents=True, exist_ok=False)
    isolated.prepare_snapshot(ROOT, results, export)
    ws = results / "workspace"
    shutil.copytree(V3 / "overlay", ws, dirs_exist_ok=True)
    manifest = ws / "build/rtl_manifest.tcl"
    with manifest.open("a") as f:
        f.write("\nlappend RTL_SOURCES rtl/memory/memory_perf_counters.sv rtl/memory/memory_perf_external.sv rtl/memory/memory_perf_mig_tap.v\n")
    # The CDC Tcl uses ordinary Tcl control flow and synthesized hierarchy.
    # Apply it in the implementation pre-opt hook, not as an early XDC file.
    hook = ws / "scripts/npu3x32_100mhz/memory_v3_pre_opt.tcl"
    hook.write_text('source [file normalize [file join [file dirname [info script]] ../../xdc/memory_parallel_v3_cdc.tcl]]\n')
    script = ws / "scripts/npu3x32_100mhz/rebuild_timing_v3_isolated.tcl"
    flow = script.read_text()
    flow = replace_once(flow, "open_project [file join $repo prj sixteen_camera.xpr]", "open_project [file join $repo prj sixteen_camera.xpr]\n# The V3 passive MIG tap is a BD module reference.\nset_property SOURCE_MGMT_MODE All [current_project]")
    flow = replace_once(flow, "source [file join $repo setup_vivado.tcl]", '''# Delete only the copied baseline BD and generated wrapper, then rebuild
# from V3 Tcl. Reusing a 256-bit BD with the new SoC is forbidden.
set stale_bd [get_files -all -quiet */design_1.bd]
set stale_wrappers [get_files -all -quiet */design_1_wrapper.v]
if {[llength $stale_wrappers]} {remove_files $stale_wrappers}
if {[llength $stale_bd]} {remove_files $stale_bd}
foreach relative {prj/sixteen_camera.srcs/sources_1/bd/design_1 prj/sixteen_camera.gen/sources_1/bd/design_1} {
    set stale [file normalize [file join $repo $relative]]
    if {![string match "${repo}/*" $stale]} {error "Unsafe copied BD path"}
    file delete -force $stale
}
source [file join $repo setup_vivado.tcl]
open_bd_design [get_files */design_1.bd]
foreach {key expected} {DATA_WIDTH 512 ID_WIDTH 2 NUM_READ_OUTSTANDING 32 NUM_WRITE_OUTSTANDING 32} {
    if {[get_property CONFIG.$key [get_bd_intf_ports S00_AXI]] != $expected} {error "Wrong V3 DDR S00 $key"}
}
if {[get_property MODE [get_bd_intf_pins u_mig_perf/S_AXI]] ne "Monitor"} {error "MIG tap is not passive"}
''')
    flow = replace_once(flow, "update_compile_order -fileset sources_1", '''set_property STEPS.OPT_DESIGN.TCL.PRE [file join $repo scripts npu3x32_100mhz memory_v3_pre_opt.tcl] $impl
update_compile_order -fileset sources_1''')
    flow = replace_once(flow, "source [file join $repo scripts npu3x32_100mhz continue_timing_v3_isolated.tcl]", '''open_run $synth
source [file join $repo xdc memory_parallel_v3_cdc.tcl]
report_utilization -file [file join $results synthesis_utilization.rpt]
report_timing_summary -file [file join $results synthesis_timing.rpt]
close_design
set fd [open [file join $results SYNTHESIS_DONE] w]
puts $fd "synth_design Complete!; V3 CDC constraints checked"
close $fd
puts "MEMORY_PARALLEL_V3_SYNTHESIS_COMPLETE"
source [file join $repo scripts npu3x32_100mhz continue_timing_v3_isolated.tcl]''')
    script.write_text(flow)
    cont = ws / "scripts/npu3x32_100mhz/continue_timing_v3_isolated.tcl"
    flow = cont.read_text()
    # The user explicitly accepted negative timing in the prior session.
    # Preserve real constraints/reports and DRC; do not label it timing PASS.
    flow = replace_once(flow, 'if {$wns < 0 || $whs < 0 || !$route_clean} {', 'if {!$route_clean} {')
    flow = flow.replace("top_wrapper_memory32_timing_v3.bit", "top_wrapper_memory_parallel_v3.bit")
    flow = replace_once(flow, 'puts $fd "BUILD=PASS"', 'if {$wns >= 0 && $whs >= 0} {puts $fd "BUILD=PASS"} else {puts $fd "BUILD=BITSTREAM_TIMING_UNMET"}')
    flow = replace_once(flow, 'puts "ISOLATED_TIMING_V3_BUILD=PASS BITSTREAM=$final_bit"', 'puts "MEMORY_PARALLEL_V3_BITSTREAM_WRITTEN=$final_bit TARGET_MET=[expr {$wns >= 0 && $whs >= 0}]"')
    cont.write_text(flow)
    subprocess.run(["tclsh", str(ws / "scripts/check_production_manifest.tcl")], check=True, cwd=results)
    inputs = isolated.inventory(ws, ("rtl", "xdc", "generated/soc", "build", "scripts", "soc_shell/memory_parallel_v3"))
    for rel in ("prj/create_design_1.tcl", "prj/sixteen_camera.xpr"):
        path = ws / rel
        stat = path.stat()
        inputs[rel] = {"sha256":isolated.digest(path), "size":stat.st_size, "mtime_ns":stat.st_mtime_ns}
    (results / "hardware_inputs_v3.json").write_text(json.dumps(inputs, indent=2) + "\n")
    (results / "PREPARED.json").write_text(json.dumps({"soc_export":str(export.resolve()), "overlay":str(V3), "strategy":"V1 passing 100MHz", "negative_timing":"generate bitstream, report TARGET_MET=0", "synthesis_only_monitor":True}, indent=2) + "\n")
    print("RESULTS_DIR=" + str(results), flush=True)
    return results

def launch(results):
    results = results.resolve(strict=True)
    results.relative_to(ROOT / "build")
    ws = results / "workspace"
    if not (results / "PREPARED.json").is_file() or (results / "BUILD_LAUNCHED").exists():
        raise RuntimeError("Requires a prepared, not previously launched V3 build")
    expected = json.loads((results / "hardware_inputs_v3.json").read_text())
    for rel, entry in expected.items():
        if isolated.digest(ws / rel) != entry["sha256"]:
            raise RuntimeError("Prepared input changed: " + rel)
    with (results / "BUILD_LAUNCHED").open("x") as f:
        f.write(datetime.datetime.now().astimezone().isoformat() + "\n")
    env = os.environ.copy()
    env.update(ISOLATED_RESULTS_DIR=str(results), ORIGINAL_REPO_DIR=str(ROOT))
    resource.setrlimit(resource.RLIMIT_STACK, (resource.RLIM_INFINITY, resource.RLIM_INFINITY))
    cmd = ["/mnt/data/Vivado/Vivado/2023.2/bin/vivado", "-mode", "batch", "-source",
           str(ws / "scripts/npu3x32_100mhz/rebuild_timing_v3_isolated.tcl"),
           "-log", str(results / "build.log"), "-journal", str(results / "build.jou")]
    status = 1
    try:
        with (results / "console.log").open("x") as log:
            status = subprocess.run(cmd, cwd=results, env=env, stdout=log, stderr=subprocess.STDOUT).returncode
    finally:
        before = json.loads((results / "original_files_before.json").read_text())
        after = isolated.inventory(ROOT, isolated.PROTECTED)
        changed = [name for name in sorted(before.keys() | after.keys()) if before.get(name) != after.get(name)]
        (results / "original_preservation_check.json").write_text(json.dumps({"original_files_unchanged":not changed, "changed_files":changed, "vivado_exit_code":status}, indent=2) + "\n")
        (results / "BUILD_EXIT_CODE").write_text(str(status) + "\n")
    bit = results / "top_wrapper_memory_parallel_v3.bit"
    if bit.exists():
        (results / "bitstream.sha256").write_text(isolated.digest(bit) + "  " + bit.name + "\n")
    return status or (1 if changed or not bit.exists() else 0)

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--soc-export", type=Path)
    p.add_argument("--results-root", type=Path, default=ROOT / "build/bitstream_memory_parallel_v3")
    p.add_argument("--launch-results", type=Path)
    a = p.parse_args()
    if a.launch_results:
        if a.soc_export: p.error("Cannot change SoC on launch")
        return launch(a.launch_results)
    if not a.soc_export: p.error("Preparation requires --soc-export")
    prepare(a.soc_export, a.results_root)
    return 0

if __name__ == "__main__":
    sys.exit(main())
