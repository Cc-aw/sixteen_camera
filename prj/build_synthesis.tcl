set script_dir [file dirname [file normalize [info script]]]
open_project [file join $script_dir sixteen_camera.xpr]
update_compile_order -fileset sources_1

foreach run_name {design_1_ddr4_0_0_synth_1
                  video_ctrl_bd_smartconnect_0_0_synth_1
                  clk_wiz_ov7670_synth_1} {
    if {[llength [get_runs -quiet $run_name]] != 0} {
        puts "$run_name=[get_property STATUS [get_runs $run_name]]"
    }
}

set synth_run [get_runs synth_1]
set_property AUTO_INCREMENTAL_CHECKPOINT 0 $synth_run
set_property INCREMENTAL_CHECKPOINT {} $synth_run
reset_run $synth_run
launch_runs $synth_run -jobs 8
wait_on_run $synth_run
puts "SYNTH_STATUS=[get_property STATUS $synth_run]"
if {[get_property STATUS $synth_run] ne "synth_design Complete!"} {
    error "Phase-one synthesis did not complete"
}
open_run $synth_run
report_utilization -file [file join $script_dir utilization_phase1_synth.rpt]
report_timing_summary -file [file join $script_dir timing_phase1_synth.rpt]
puts "PHASE1_SYNTHESIS=PASS"
close_project
