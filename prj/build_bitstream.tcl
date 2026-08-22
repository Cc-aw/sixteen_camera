set script_dir [file dirname [file normalize [info script]]]
open_project [file join $script_dir sixteen_camera.xpr]

set synth_run [get_runs synth_1]
# Force a clean top-level synthesis.  Vivado 2023.2 can crash while applying a
# stale auto-incremental DCP after RTL changes (observed after the CDC fix).
set_property AUTO_INCREMENTAL_CHECKPOINT 0 $synth_run
set_property INCREMENTAL_CHECKPOINT {} $synth_run
reset_run $synth_run
launch_runs $synth_run -jobs 8
wait_on_run $synth_run
set synth_status [get_property STATUS $synth_run]
puts "SYNTH_STATUS=$synth_status"
if {$synth_status ne "synth_design Complete!"} {
    error "Synthesis did not complete"
}

set impl_run [get_runs impl_1]
reset_run $impl_run
launch_runs $impl_run -to_step write_bitstream -jobs 8
wait_on_run $impl_run

set status [get_property STATUS $impl_run]
set progress [get_property PROGRESS $impl_run]
puts "IMPL_STATUS=$status"
puts "IMPL_PROGRESS=$progress"
if {$progress ne "100%" || $status ne "write_bitstream Complete!"} {
    error "Bitstream build did not complete"
}

open_run $impl_run
report_timing_summary -file [file join $script_dir timing_summary.rpt]
report_utilization -file [file join $script_dir utilization_impl.rpt]
report_drc -file [file join $script_dir drc_impl.rpt]
puts "BITSTREAM_BUILD=PASS"
close_project
