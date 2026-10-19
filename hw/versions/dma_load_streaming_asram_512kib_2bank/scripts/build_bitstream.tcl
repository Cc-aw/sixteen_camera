# One private 512KiB/two-bank project, complete synthesis-to-bitstream flow.
set feature_dir [file normalize [file join [file dirname [info script]] ..]]
set repo_dir [file normalize [file join $feature_dir ../../..]]
set report_dir [file normalize $::env(ASRAM_REPORT_DIR)]
proc asram_phase {value} {
    global report_dir
    set file [open [file join $report_dir phase.txt] w]
    puts $file $value
    close $file
    puts "ASRAM_BUILD_PHASE=$value"
}
asram_phase PROJECT_SETUP
set sc_bd_checkpoint_mode Hierarchical
set sc_generate_synth_checkpoint true
source [file join $repo_dir tools build open_build_project.tcl]
# setup_vivado has already selected the private ASRAM run settings.
set asram_expected_hook [file join $feature_dir constraints placement.tcl]
if {[get_property STEPS.PLACE_DESIGN.TCL.PRE [get_runs impl_1]] ne $asram_expected_hook} {
    error "ASRAM placement hook was not selected"
}
if {[get_property STEPS.WRITE_BITSTREAM.TCL.PRE [get_runs impl_1]] ne ""} {
    error "Unexpected bitstream timing gate"
}
report_property -all [get_runs impl_1] -file [file join $report_dir impl_properties.rpt]
set source_file [open [file join $report_dir project_sources.txt] w]
foreach f [get_files -all] { puts $source_file $f }
close $source_file
source [file join $repo_dir tools build prepare_ip_runs.tcl]
if {[llength $sc_ip_runs] != 0} {
    asram_phase IP_SYNTHESIS
    foreach run $sc_ip_runs { reset_run $run }
    launch_runs $sc_ip_runs -jobs 8
    foreach run $sc_ip_runs {
        wait_on_run $run
        if {[get_property PROGRESS $run] ne "100%" || \
            [regexp -nocase {error|fail|cancel} [get_property STATUS $run]]} {
            error "$run failed: [get_property STATUS $run]"
        }
    }
}
reset_run synth_1
asram_phase SYNTH_1
launch_runs synth_1 -jobs 8
wait_on_run synth_1
set run [get_runs synth_1]
if {[get_property PROGRESS $run] ne "100%" || \
    [regexp -nocase {error|fail|cancel} [get_property STATUS $run]]} {
    error "synth_1 failed: [get_property STATUS $run]"
}
open_run synth_1
report_utilization -hierarchical -file [file join $report_dir synthesis_utilization.rpt]
report_timing_summary -file [file join $report_dir synthesis_timing_estimate.rpt]
set checkpoint [file join [get_property DIRECTORY $run] top_wrapper.dcp]
if {![file isfile $checkpoint]} {error "Synthesis checkpoint missing"}
set fd [open [file join $report_dir synthesis_result.txt] w]
puts $fd "SYNTHESIS=PASS"
puts $fd "STATUS=[get_property STATUS $run]"
puts $fd "PROGRESS=[get_property PROGRESS $run]"
puts $fd "CHECKPOINT=$checkpoint"
puts $fd "TIMING_SCOPE=UNPLACED_SYNTHESIS_ESTIMATE"
close $fd
close_design
asram_phase WAITING_IMPLEMENTATION_LOCK
while {![file isfile [file join $report_dir implementation.ready]]} {after 5000}
asram_phase IMPLEMENTATION_PREPARE
reset_run impl_1
launch_runs impl_1 -to_step write_bitstream -jobs 8
asram_phase IMPLEMENTATION
wait_on_run impl_1
set run [get_runs impl_1]
if {[get_property PROGRESS $run] ne "100%" || \
    [regexp -nocase {error|fail|cancel} [get_property STATUS $run]]} {
    error "impl_1 failed: [get_property STATUS $run]"
}
open_run impl_1
report_timing_summary -delay_type min_max -report_unconstrained -file [file join $report_dir routed_timing.rpt]
report_utilization -hierarchical -file [file join $report_dir routed_utilization.rpt]
report_drc -file [file join $report_dir drc.rpt]
report_route_status -file [file join $report_dir route.rpt]
check_timing -verbose -file [file join $report_dir check_timing.rpt]
set setup [get_timing_paths -delay_type max -max_paths 1]
set hold [get_timing_paths -delay_type min -max_paths 1]
if {[llength $setup] != 1 || [llength $hold] != 1} {error "Missing routed timing paths"}
set wns [get_property SLACK $setup]
set whs [get_property SLACK $hold]
set bit [file join $project_work_dir ${project_name}.runs impl_1 top_wrapper.bit]
if {![file isfile $bit]} {error "Missing generated bitstream"}
file copy $bit [file join $report_dir dma_load_streaming_asram_512kib_2bank.bit]
set fd [open [file join $report_dir result.txt] w]
puts $fd "BITSTREAM=[file join $report_dir dma_load_streaming_asram_512kib_2bank.bit]"
puts $fd "WNS_NS=$wns"
puts $fd "WHS_NS=$whs"
puts $fd "TARGET_MET=[expr {$wns >= 0 && $whs >= 0}]"
close $fd
asram_phase COMPLETE
close_project
