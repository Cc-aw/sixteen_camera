# The standard post-route phys_opt step has already completed here.
# Save its result before reporting; do not start a second memory-heavy pass.
set s3_root [get_property DIRECTORY [current_project]]
set s3_reports [file join $s3_root timing_s3_reports]
file mkdir $s3_reports
write_checkpoint -force [file join $s3_reports postroute_saved.dcp]
report_timing_summary -delay_type min_max -report_unconstrained -file [file join $s3_reports postroute_summary.rpt]
report_timing -delay_type max -max_paths 200 -nworst 1 -file [file join $s3_reports setup_worst200.rpt]
report_route_status -file [file join $s3_reports route_status.rpt]
report_utilization -file [file join $s3_reports utilization_slr.rpt]
set s3_wns [get_property SLACK [get_timing_paths -delay_type max -max_paths 1]]
puts "TIMING_S3_FINAL_WNS_NS=$s3_wns"
puts "TIMING_S3_SETUP_GOAL_MET=[expr {$s3_wns >= 0.0}]"
puts "TIMING_S3_EXTRA_POSTROUTE_PASS=DISABLED"
