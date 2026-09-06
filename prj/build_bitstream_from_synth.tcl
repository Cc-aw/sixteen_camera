set script_dir [file dirname [file normalize [info script]]]
open_project [file join $script_dir sixteen_camera.xpr]

# Deliberately do not reset or launch synth_1 here.  Refuse to continue unless
# a completed synthesis run is already present, so this command cannot silently
# turn into a full rebuild.
set synth_run [get_runs synth_1]
set synth_status [get_property STATUS $synth_run]
set synth_progress [get_property PROGRESS $synth_run]
puts "REUSED_SYNTH_STATUS=$synth_status"
puts "REUSED_SYNTH_PROGRESS=$synth_progress"
if {$synth_status ne "synth_design Complete!" || $synth_progress ne "100%"} {
    error "No completed synth_1 run is available; run build_synthesis.tcl first"
}

set impl_run [get_runs impl_1]
reset_run $impl_run
launch_runs $impl_run -to_step write_bitstream -jobs 8
wait_on_run $impl_run

set impl_status [get_property STATUS $impl_run]
set impl_progress [get_property PROGRESS $impl_run]
puts "IMPL_STATUS=$impl_status"
puts "IMPL_PROGRESS=$impl_progress"
if {$impl_progress ne "100%" || $impl_status ne "write_bitstream Complete!"} {
    error "Bitstream build did not complete"
}

open_run $impl_run
report_timing_summary -file [file join $script_dir timing_summary.rpt]
report_utilization -file [file join $script_dir utilization_impl.rpt]
report_drc -file [file join $script_dir drc_impl.rpt]
puts "BITSTREAM_BUILD_FROM_SYNTH=PASS"
close_project
