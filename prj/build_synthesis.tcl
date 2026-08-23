set script_dir [file dirname [file normalize [info script]]]
open_project [file join $script_dir sixteen_camera.xpr]
update_compile_order -fileset sources_1

# These two XCI files are maintained in rtl/ip rather than a legacy Vivado
# project tree. Rebuild their output products deterministically so a stale OOC
# run cannot hide a missing generated wrapper after the project is relocated.
set required_ip_runs {}
foreach {ip_name run_name} {
    clk_wiz_ov7670 clk_wiz_ov7670_synth_1
} {
    set ip [get_ips -quiet $ip_name]
    if {[llength $ip] != 1} {
        error "Expected exactly one IP named $ip_name"
    }
    generate_target all $ip
    # A project rebuilt from source contains the XCI but no OOC run database.
    # Recreate the run explicitly instead of relying on a generated/cache tree.
    if {[llength [get_runs -quiet $run_name]] == 0} {
        create_ip_run $ip
    }
    set ip_run [get_runs -quiet $run_name]
    if {[llength $ip_run] != 1} {
        error "Missing synthesis run $run_name for $ip_name"
    }
    reset_run $ip_run
    lappend required_ip_runs $ip_run
}
launch_runs $required_ip_runs -jobs 8
foreach ip_run $required_ip_runs {
    wait_on_run $ip_run
    puts "[get_property NAME $ip_run]=[get_property STATUS $ip_run] progress=[get_property PROGRESS $ip_run]"
    if {[get_property PROGRESS $ip_run] ne "100%"} {
        error "Required IP synthesis did not complete: [get_property NAME $ip_run]"
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
