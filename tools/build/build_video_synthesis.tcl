# Full-system synthesis only, with the same IP and run settings as bitstream builds.
set repo_dir [file dirname [file dirname [file dirname [file normalize [info script]]]]]
set report_dir [file normalize $::env(SYNTHESIS_REPORT_DIR)]
file mkdir $report_dir
proc synthesis_phase {phase} {
    global report_dir
    set fd [open [file join $report_dir phase.txt] w]
    puts $fd $phase
    close $fd
    puts "FULL_SYSTEM_SYNTHESIS_PHASE=$phase"
}
synthesis_phase PROJECT_SETUP
set sc_bd_checkpoint_mode Hierarchical
set sc_generate_synth_checkpoint true
source [file join $repo_dir tools build open_build_project.tcl]
source [file join $repo_dir tools build default_video_run_settings.tcl]
apply_default_video_run_settings
if {$SOC_BITSTREAM_FLOW eq "triple32_v3"} {
    source [file join $repo_dir tools build triple32_v3 run_settings.tcl]
    apply_triple32_v3_run_settings
}
set fd [open [file join $report_dir project_sources.txt] w]
foreach source_file [get_files -all] { puts $fd $source_file }
close $fd
source [file join $repo_dir tools build prepare_ip_runs.tcl]
if {[llength $sc_ip_runs] != 0} {
    synthesis_phase IP_SYNTHESIS
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
synthesis_phase SYNTH_1
launch_runs synth_1 -jobs 8
wait_on_run synth_1
set run [get_runs synth_1]
set status [get_property STATUS $run]
if {[get_property PROGRESS $run] ne "100%" ||
    [regexp -nocase {error|fail|cancel} $status]} {
    error "synth_1 failed: $status"
}
synthesis_phase REPORTS
open_run synth_1
report_utilization -hierarchical -file [file join $report_dir utilization.rpt]
report_timing_summary -file [file join $report_dir timing_estimate.rpt]
check_timing -verbose -file [file join $report_dir check_timing.rpt]
set checkpoint [file join [get_property DIRECTORY $run] top_wrapper.dcp]
if {![file exists $checkpoint]} { error "Synthesis checkpoint missing: $checkpoint" }
set fd [open [file join $report_dir result.txt] w]
puts $fd "SYNTHESIS=PASS"
puts $fd "STATUS=$status"
puts $fd "PROGRESS=[get_property PROGRESS $run]"
puts $fd "CHECKPOINT=$checkpoint"
puts $fd "IMPL_STATUS=[get_property STATUS [get_runs impl_1]]"
puts $fd "TIMING_SCOPE=UNPLACED_SYNTHESIS_ESTIMATE"
puts $fd "BITSTREAM=NOT_GENERATED"
close $fd
synthesis_phase COMPLETE
puts "FULL_SYSTEM_SYNTHESIS=PASS"
close_project
