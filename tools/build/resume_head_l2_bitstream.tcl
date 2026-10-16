# Replay the saved routed design without resynthesis, placement, routing or
# another physical optimization pass. Preserve all timing/DRC constraints.
if {[llength $argv] != 2} { error "Usage: routed.dcp output.bit" }
set checkpoint [file normalize [lindex $argv 0]]
set bitstream [file normalize [lindex $argv 1]]
set_param general.maxThreads 8
open_checkpoint $checkpoint
report_timing_summary -delay_type min_max -report_unconstrained -file timing.rpt
report_route_status -file route.rpt
report_bus_skew -file bus_skew.rpt
report_drc -file drc.rpt
report_utilization -file utilization.rpt
check_timing -verbose -file check_timing.rpt
set setup_path [get_timing_paths -delay_type max -max_paths 1 -nworst 1]
set hold_path [get_timing_paths -delay_type min -max_paths 1 -nworst 1]
if {[llength $setup_path] != 1 || [llength $hold_path] != 1} {
    error "Missing setup/hold paths in routed design"
}
set wns [get_property SLACK [lindex $setup_path 0]]
set whs [get_property SLACK [lindex $hold_path 0]]
set timing_met [expr {$wns >= 0 && $whs >= 0}]
puts "RESUME_WNS_NS=$wns"
puts "RESUME_WHS_NS=$whs"
puts "RESUME_TIMING_MET=$timing_met"
# No DRC severity overrides and no write_bitstream -force. A new output
# directory preserves previous artifacts; real bitstream DRC errors still fail.
write_bitstream $bitstream
set fd [open final_status.txt w]
puts $fd "SOURCE_CHECKPOINT=$checkpoint"
puts $fd "WNS_NS=$wns"
puts $fd "WHS_NS=$whs"
puts $fd "TIMING_MET=$timing_met"
puts $fd "BITSTREAM=$bitstream"
puts $fd "BOARD_RUN=NOT_RUN"
if {$timing_met} {
    puts $fd "BUILD=PASS"
} else {
    puts $fd "BUILD=BITSTREAM_TIMING_UNMET"
}
close $fd
puts "RESUME_BITSTREAM_WRITTEN=$bitstream"
close_design
