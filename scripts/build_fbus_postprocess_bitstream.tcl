# Build the combined diagnostic snapshot + FBus ID/burst changes.
set repo_dir [file dirname [file dirname [file normalize [info script]]]]
open_project [file join $repo_dir prj sixteen_camera.xpr]
source [file join $repo_dir setup_vivado.tcl]
if {$sc_total_failed != 0 ||
    $::sixteen_camera_setup::bd_status ne "OK" ||
    $::sixteen_camera_setup::wrapper_status ne "OK" ||
    $sc_top_status ne "OK"} {
    error "Project setup did not pass"
}
set old_bit [file join $repo_dir prj sixteen_camera.runs impl_1 top_wrapper.bit]
if {[file exists $old_bit]} {
    file copy -force $old_bit /tmp/fbus_prechange_top_wrapper.bit
}
reset_run synth_1
launch_runs synth_1 -jobs 8
wait_on_run synth_1
if {[get_property PROGRESS [get_runs synth_1]] ne "100%"} {
    error "Synthesis failed: [get_property STATUS [get_runs synth_1]]"
}
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1
if {[get_property PROGRESS [get_runs impl_1]] ne "100%" || ![file exists $old_bit]} {
    error "Bitstream generation failed: [get_property STATUS [get_runs impl_1]]"
}
open_run impl_1
report_timing_summary -file /tmp/fbus_postprocess_timing_summary.rpt
report_utilization -file /tmp/fbus_postprocess_utilization.rpt
puts "FBUS_POSTPROCESS_BITSTREAM=PASS"
puts "BITSTREAM=$old_bit"
close_project
