# Generic video build: use Vivado defaults for the selected SoC.
set repo_dir [file dirname [file dirname [file dirname [file normalize [info script]]]]]
open_project [file join $repo_dir prj sixteen_camera.xpr]
source [file join $repo_dir setup_vivado.tcl]
if {$sc_total_failed != 0 ||
    $::sixteen_camera_setup::bd_status ne "OK" ||
    $::sixteen_camera_setup::wrapper_status ne "OK" ||
    $sc_top_status ne "OK"} {
    error "Project setup did not pass"
}
source [file join $repo_dir scripts build default_video_run_settings.tcl]
apply_default_video_run_settings
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
set bitstream [file join $repo_dir prj sixteen_camera.runs impl_1 top_wrapper.bit]
if {![file exists $bitstream]} { error "Bitstream missing: $bitstream" }
open_run impl_1
report_timing_summary -file [file join [pwd] timing.rpt]
report_utilization -file [file join [pwd] utilization.rpt]
report_drc -file [file join [pwd] drc.rpt]
puts "DEFAULT_VIDEO_BITSTREAM=PASS"
puts "BITSTREAM=$bitstream"
close_project
