source [file join [file dirname [info script]] postroute_timing_s2.tcl]
set s3_dir [file normalize [file join [pwd] timing_s3_reports]]
file mkdir $s3_dir
# Keep a correctly labelled final report set alongside the inherited reports.
report_timing_summary -delay_type min_max -max_paths 20 -file [file join $s3_dir summary.rpt]
report_timing -delay_type max -max_paths 1000 -nworst 1 -file [file join $s3_dir setup_worst1000.rpt]
report_route_status -file [file join $s3_dir route_status.rpt]
report_utilization -slr -file [file join $s3_dir utilization_slr.rpt]
puts "TIMING_S3_FINAL_REPORTS=$s3_dir"
unset s3_dir
