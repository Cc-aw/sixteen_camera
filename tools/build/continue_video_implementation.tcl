# Continue a successfully synthesized project through write_bitstream.
set report_dir [file normalize $::env(IMPLEMENTATION_REPORT_DIR)]
file mkdir $report_dir
open_project $::env(VIVADO_PROJECT)
set synth [get_runs synth_1]
if {[get_property PROGRESS $synth] ne "100%" ||
    [regexp -nocase {error|fail|cancel} [get_property STATUS $synth]] ||
    [get_property NEEDS_REFRESH $synth]} {
    error "Continuation requires completed, current synth_1"
}
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1
set run [get_runs impl_1]
if {[get_property PROGRESS $run] ne "100%" ||
    [regexp -nocase {error|fail|cancel} [get_property STATUS $run]]} {
    error "impl_1 failed: [get_property STATUS $run]"
}
set bitstream [file join [get_property DIRECTORY $run] top_wrapper.bit]
if {![file exists $bitstream]} {error "Bitstream missing: $bitstream"}
open_run impl_1
report_timing_summary -delay_type min_max -report_unconstrained -file [file join $report_dir timing.rpt]
report_utilization -file [file join $report_dir utilization.rpt]
report_drc -file [file join $report_dir drc.rpt]
report_route_status -file [file join $report_dir route.rpt]
report_bus_skew -file [file join $report_dir bus_skew.rpt]
check_timing -verbose -file [file join $report_dir check_timing.rpt]
set setup_path [get_timing_paths -delay_type max -max_paths 1]
set hold_path [get_timing_paths -delay_type min -max_paths 1]
if {[llength $setup_path] != 1 || [llength $hold_path] != 1} {
    error "Setup/hold timing paths missing"
}
set wns [get_property SLACK $setup_path]
set whs [get_property SLACK $hold_path]
set fd [open [file join $report_dir result.txt] w]
puts $fd "BUILD=BITSTREAM_GENERATED"
puts $fd "WNS_NS=$wns"
puts $fd "WHS_NS=$whs"
puts $fd "TARGET_MET=[expr {$wns >= 0 && $whs >= 0}]"
puts $fd "BITSTREAM=$bitstream"
close $fd
puts "VIDEO_BITSTREAM_WRITTEN TARGET_MET=[expr {$wns >= 0 && $whs >= 0}]"
close_project
