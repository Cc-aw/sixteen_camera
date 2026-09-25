# PPU phase 2: synthesize the current single4 SoC, then continue through bitstream.
set repo_dir [file dirname [file dirname [file normalize [info script]]]]
set report_dir [file join $repo_dir build ppu_phase2 final]
file mkdir $report_dir
open_project [file join $repo_dir prj sixteen_camera.xpr]
source [file join $repo_dir setup_vivado.tcl]
if {$sc_total_failed != 0 || $::sixteen_camera_setup::bd_status ne "OK" ||
    $::sixteen_camera_setup::wrapper_status ne "OK" || $sc_top_status ne "OK"} {
    error "Project setup did not pass"
}
set bit_file [file join $repo_dir prj sixteen_camera.runs impl_1 top_wrapper.bit]
if {[file exists $bit_file]} {
    file copy -force $bit_file [file join $report_dir pre_phase2_top_wrapper.bit]
}
reset_run synth_1
launch_runs synth_1 -jobs 8
wait_on_run synth_1
if {[get_property PROGRESS [get_runs synth_1]] ne "100%" ||
    ![string match {*Complete*} [get_property STATUS [get_runs synth_1]]]} {
    error "Synthesis failed: [get_property STATUS [get_runs synth_1]]"
}
puts "PPU_PHASE2_SYNTHESIS=PASS"
flush stdout
set_property strategy {Vivado Implementation Defaults} [get_runs impl_1]
launch_runs impl_1 -to_step write_bitstream -jobs 8
puts "PPU_PHASE2_IMPLEMENTATION=STARTED"
flush stdout
wait_on_run impl_1
if {[get_property PROGRESS [get_runs impl_1]] ne "100%" || ![file exists $bit_file]} {
    error "Bitstream generation failed: [get_property STATUS [get_runs impl_1]]"
}
open_run impl_1
report_timing_summary -file [file join $report_dir timing_summary.rpt]
report_utilization -file [file join $report_dir utilization.rpt]
puts "PPU_PHASE2_BITSTREAM=PASS"
puts "BITSTREAM=$bit_file"
close_project
