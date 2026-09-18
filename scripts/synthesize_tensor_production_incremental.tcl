set repo_dir [file dirname [file dirname [file normalize [info script]]]]
set reference_checkpoint /tmp/top_wrapper_pre_timing_fix.dcp
if {[llength $argv] > 0} {
    set reference_checkpoint [file normalize [lindex $argv 0]]
}
if {![file isfile $reference_checkpoint]} {
    error "Incremental synthesis checkpoint does not exist: $reference_checkpoint"
}

open_project [file join $repo_dir prj sixteen_camera.xpr]
source [file join $repo_dir setup_vivado.tcl]
if {$sc_total_failed != 0 ||
    $::sixteen_camera_setup::bd_status ne "OK" ||
    $::sixteen_camera_setup::wrapper_status ne "OK" ||
    $sc_top_status ne "OK"} {
    error "Project setup did not pass"
}

set synth_run [get_runs synth_1]
reset_run $synth_run
set_property INCREMENTAL_CHECKPOINT $reference_checkpoint $synth_run
puts "INCREMENTAL_SYNTH_CHECKPOINT=$reference_checkpoint"
launch_runs $synth_run -jobs 8
wait_on_run $synth_run
if {[get_property PROGRESS $synth_run] ne "100%"} {
    error "Incremental synthesis failed: [get_property STATUS $synth_run]"
}

open_run $synth_run
report_timing_summary -file \
    [file join $repo_dir prj tensor_production_timing_synthesized.rpt]
report_utilization -file \
    [file join $repo_dir prj tensor_production_utilization_synthesized.rpt]
puts "TENSOR_PRODUCTION_INCREMENTAL_SYNTHESIS=PASS"
puts "SYNTH_CHECKPOINT=[file join $repo_dir prj sixteen_camera.runs synth_1 top_wrapper.dcp]"
close_project
