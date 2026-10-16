# This hook runs after the strategy's normal post-route AggressiveExplore
# pass. A second pass is used only when setup timing remains negative. No
# timing constraint or functional path is changed.
set setup_path [get_timing_paths -delay_type max -max_paths 1 -nworst 1]
if {[llength $setup_path] == 0} {
    error "No max-delay timing path is available after route"
}

set before_wns [get_property SLACK [lindex $setup_path 0]]
puts [format "TIMING_CLOSE_BEFORE_WNS_NS=%.3f" $before_wns]

if {$before_wns < 0.0} {
    puts "TIMING_CLOSE_ACTION=SECOND_AGGRESSIVE_EXPLORE"
    phys_opt_design -directive AggressiveExplore
} else {
    puts "TIMING_CLOSE_ACTION=SKIP_ALREADY_MET"
}

set setup_path [get_timing_paths -delay_type max -max_paths 1 -nworst 1]
if {[llength $setup_path] == 0} {
    error "No max-delay timing path is available after physical optimization"
}
set after_wns [get_property SLACK [lindex $setup_path 0]]
puts [format "TIMING_CLOSE_AFTER_WNS_NS=%.3f" $after_wns]

# Implementation run hooks execute in a non-project child process: there
# need not be a get_runs impl_1 object. Its working directory is the run
# output directory, and is also valid when replaying a routed checkpoint.
set report_dir [file normalize [pwd]]
file mkdir $report_dir
report_timing_summary -delay_type min_max -report_unconstrained \
    -file [file join $report_dir postroute_timing_close_summary.rpt]
report_route_status -file [file join $report_dir postroute_route_status.rpt]
report_bus_skew -file [file join $report_dir postroute_bus_skew.rpt]
