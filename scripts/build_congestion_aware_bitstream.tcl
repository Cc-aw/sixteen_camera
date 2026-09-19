set repo_dir [file dirname [file dirname [file normalize [info script]]]]
set run_name impl_congestion
set run_dir [file join $repo_dir prj sixteen_camera.runs $run_name]
set run_bitstream [file join $run_dir top_wrapper.bit]
set canonical_bitstream [file join $repo_dir prj sixteen_camera.runs impl_1 \
    top_wrapper.bit]

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

# Use a new run instead of mutating impl_1, but deliberately keep Vivado's
# default implementation strategy. The former congestion/timing directives
# could make placement fail on this design.
if {[llength [get_runs -quiet $run_name]] != 0} {
    delete_runs [get_runs $run_name]
}
create_run $run_name -parent_run synth_1 -flow {Vivado Implementation 2023} \
    -strategy {Vivado Implementation Defaults} -constrset constrs_1
set impl_run [get_runs $run_name]

puts "IMPLEMENTATION_RUN=$run_name"
puts "IMPLEMENTATION_STRATEGY=[get_property STRATEGY $impl_run]"
puts "SYNTHESIS_RELAUNCHED=NO"
launch_runs $impl_run -to_step write_bitstream -jobs 8
wait_on_run $impl_run

set impl_status [get_property STATUS $impl_run]
if {![file isfile $run_bitstream] || [file size $run_bitstream] == 0} {
    error "Bitstream generation failed: $impl_status"
}

file copy -force $run_bitstream $canonical_bitstream
open_run $impl_run
report_route_status -file \
    [file join $repo_dir prj congestion_aware_route_status.rpt]
report_timing_summary -file \
    [file join $repo_dir prj congestion_aware_timing.rpt]
report_drc -file [file join $repo_dir prj congestion_aware_drc.rpt]
puts "CONGESTION_AWARE_BITSTREAM=PASS"
puts "BITSTREAM=$canonical_bitstream"
close_project
