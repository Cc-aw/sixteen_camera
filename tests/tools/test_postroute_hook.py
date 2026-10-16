#!/usr/bin/env python3
"""Reproduce a Vivado run hook with no project/run objects in its interpreter."""
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
HOOK = ROOT / 'tools/build/triple32_v3/postroute_timing_close.tcl'
for slack, expected_passes in ((0.125, 0), (-1.784, 1)):
    with tempfile.TemporaryDirectory() as work:
        script = '''
set passes 0
proc get_timing_paths {args} { return path0 }
proc get_property {property object} {
    if {$property ne "SLACK" || $object ne "path0"} { error "unexpected object lookup" }
    return SLACK_VALUE
}
proc phys_opt_design {args} { incr ::passes }
proc report_timing_summary {args} { lappend ::reports [lindex $args end] }
proc report_route_status {args} { lappend ::reports [lindex $args end] }
proc report_bus_skew {args} { lappend ::reports [lindex $args end] }
# get_runs intentionally does not exist, as in the failing implementation hook.
source HOOK_PATH
if {$passes != EXPECTED_PASSES} { error "physical optimization count changed" }
if {[llength $reports] != 3} { error "missing timing/route/bus-skew report" }
foreach report $reports {
    if {[file dirname $report] ne [pwd]} { error "report escaped current run directory" }
}
puts "POSTROUTE_NONPROJECT_HOOK_PASS"
'''.replace('SLACK_VALUE', str(slack)).replace('HOOK_PATH', '{' + str(HOOK) + '}').replace('EXPECTED_PASSES', str(expected_passes))
        result = subprocess.run(['tclsh'], input=script, text=True, cwd=work, capture_output=True)
        assert result.returncode == 0 and not result.stderr, result.stdout + result.stderr
        assert 'POSTROUTE_NONPROJECT_HOOK_PASS' in result.stdout
print('POSTROUTE_HOOK_TEST=PASS project_objects=absent report_paths=current_run optimization_policy=unchanged')
