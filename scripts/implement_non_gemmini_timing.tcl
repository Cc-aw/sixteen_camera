set repo_dir [file dirname [file dirname [file normalize [info script]]]]

open_project [file join $repo_dir prj sixteen_camera.xpr]
source [file join $repo_dir setup_vivado.tcl]
if {$sc_total_failed != 0 ||
    $::sixteen_camera_setup::bd_status ne "OK" ||
    $::sixteen_camera_setup::wrapper_status ne "OK" ||
    $sc_top_status ne "OK"} {
    error "Project setup did not pass"
}

set synth_run [get_runs synth_1]
if {[get_property PROGRESS $synth_run] ne "100%"} {
    error "A completed synthesized design is required"
}

set impl_run [get_runs impl_1]
reset_run $impl_run

# The previous routed checkpoint was removed when synthesis was reset, so the
# implementation itself cannot reuse placement.  Synthesis remains incremental
# and is not relaunched here. Use the default implementation strategy and
# stop after routing so the result can be inspected before bitstream write.
set_property strategy {Vivado Implementation Defaults} $impl_run
puts "IMPLEMENTATION_STRATEGY=[get_property strategy $impl_run]"
puts "SYNTHESIS_RELAUNCHED=NO"
launch_runs $impl_run -to_step route_design -jobs 8
wait_on_run $impl_run
set impl_status [get_property STATUS $impl_run]
if {[string first "route_design Complete" $impl_status] < 0 &&
    [string first "Route Design Complete" $impl_status] < 0 &&
    ![file exists [file join $repo_dir prj sixteen_camera.runs impl_1 \
        top_wrapper_routed.dcp]]} {
    error "Implementation failed: $impl_status"
}

open_run $impl_run
report_timing_summary -file \
    [file join $repo_dir prj non_gemmini_timing_routed.rpt]
report_drc -file [file join $repo_dir prj non_gemmini_drc_routed.rpt]
set routing_errors [get_drc_violations -quiet -filter \
    {SEVERITY == Error || SEVERITY == {Critical Warning}}]
if {[llength [get_drc_violations -quiet RTSTAT-*]] != 0} {
    error "Implementation produced an incomplete route; see non_gemmini_drc_routed.rpt"
}
report_utilization -file \
    [file join $repo_dir prj non_gemmini_utilization_routed.rpt]
puts "NON_GEMMINI_IMPLEMENTATION=PASS"
puts "ROUTED_CHECKPOINT=[file join $repo_dir prj sixteen_camera.runs impl_1 top_wrapper_routed.dcp]"
close_project
