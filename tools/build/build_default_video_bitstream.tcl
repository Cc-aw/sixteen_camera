# Generic video build: use Vivado defaults for the selected SoC.
set repo_dir [file dirname [file dirname [file dirname [file normalize [info script]]]]]
set sc_bd_checkpoint_mode Hierarchical
set sc_generate_synth_checkpoint true
source [file join $repo_dir tools build open_build_project.tcl]
if {$sc_total_failed != 0 ||
    $::sixteen_camera_setup::bd_status ne "OK" ||
    $::sixteen_camera_setup::wrapper_status ne "OK" ||
    $sc_top_status ne "OK"} {
    error "Project setup did not pass"
}
source [file join $repo_dir tools build default_video_run_settings.tcl]
apply_default_video_run_settings
if {$SOC_BITSTREAM_FLOW eq "triple32_v3"} {
    source [file join $repo_dir tools build triple32_v3 run_settings.tcl]
    apply_triple32_v3_run_settings
}
source [file join $repo_dir tools build prepare_ip_runs.tcl]
if {[llength $sc_ip_runs] != 0} {
    foreach run $sc_ip_runs { reset_run $run }
    launch_runs $sc_ip_runs -jobs 8
    foreach run $sc_ip_runs {
        wait_on_run $run
        if {[get_property PROGRESS $run] ne "100%" ||
            [regexp -nocase {error|fail|cancel} [get_property STATUS $run]]} {
            error "$run failed: [get_property STATUS $run]"
        }
    }
}
reset_run synth_1
foreach run {synth_1 impl_1} {
    if {$run eq "synth_1"} {
        launch_runs $run -jobs 8
    } else {
        launch_runs $run -to_step write_bitstream -jobs 8
    }
    wait_on_run $run
    set status [get_property STATUS [get_runs $run]]
    if {[get_property PROGRESS [get_runs $run]] ne "100%" ||
        [regexp -nocase {error|fail|cancel} $status]} {
        error "$run failed: $status"
    }
}
set bitstream [file join $project_work_dir ${project_name}.runs impl_1 top_wrapper.bit]
if {![file exists $bitstream]} { error "Bitstream missing: $bitstream" }
open_run impl_1
report_timing_summary -file [file join [pwd] timing.rpt]
report_utilization -file [file join [pwd] utilization.rpt]
report_drc -file [file join [pwd] drc.rpt]
report_route_status -file [file join [pwd] route.rpt]
check_timing -verbose -file [file join [pwd] check_timing.rpt]
set setup_path [get_timing_paths -delay_type max -max_paths 1]
set hold_path [get_timing_paths -delay_type min -max_paths 1]
if {[llength $setup_path] != 1 || [llength $hold_path] != 1} {
    error "Setup/hold timing paths missing"
}
set wns [get_property SLACK $setup_path]
set whs [get_property SLACK $hold_path]
set fd [open [file join [pwd] final_status.txt] w]
puts $fd "SOC_CONFIG=$SOC_CONFIG"
puts $fd "FLOW=$SOC_BITSTREAM_FLOW"
puts $fd "WNS_NS=$wns"
puts $fd "WHS_NS=$whs"
puts $fd "TARGET_MET=[expr {$wns >= 0 && $whs >= 0}]"
puts $fd "BITSTREAM=$bitstream"
if {$wns >= 0 && $whs >= 0} {
    puts $fd "BUILD=PASS"
} else {
    puts $fd "BUILD=BITSTREAM_TIMING_UNMET"
}
close $fd
puts "VIDEO_BITSTREAM_WRITTEN flow=$SOC_BITSTREAM_FLOW TARGET_MET=[expr {$wns >= 0 && $whs >= 0}]"
puts "BITSTREAM=$bitstream"
close_project
