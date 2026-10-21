# This hook follows the standard post-route physical optimization step.
set s5_report_root [get_property DIRECTORY [current_project]]
set s5_reports [file join $s5_report_root timing_s5_reports]
file mkdir $s5_reports
write_checkpoint -force [file join $s5_reports postroute_saved.dcp]
report_timing_summary -delay_type min_max -report_unconstrained -file [file join $s5_reports postroute_summary.rpt]
report_timing -delay_type max -max_paths 500 -nworst 1 -file [file join $s5_reports setup_worst500.rpt]
report_route_status -file [file join $s5_reports route_status.rpt]
report_utilization -file [file join $s5_reports utilization_slr.rpt]
set s5_wns [get_property SLACK [get_timing_paths -delay_type max -max_paths 1]]
puts "TIMING_S5_FINAL_WNS_NS=$s5_wns"
puts "TIMING_S5_SETUP_GOAL_MET=[expr {$s5_wns >= 0.0}]"
