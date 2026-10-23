set timing_s1_reports [file normalize [file join [pwd] timing_s1_reports]]
file mkdir $timing_s1_reports
write_checkpoint -force [file join $timing_s1_reports postroute_saved.dcp]
report_timing_summary -delay_type min_max -report_unconstrained -file [file join $timing_s1_reports summary.rpt]
report_timing -delay_type max -max_paths 1000 -nworst 1 -file [file join $timing_s1_reports setup_worst1000.rpt]
report_route_status -file [file join $timing_s1_reports route_status.rpt]
report_utilization -slr -file [file join $timing_s1_reports utilization_slr.rpt]
report_drc -file [file join $timing_s1_reports drc.rpt]
foreach timing_s1_clock {clk_100m_p mmcm_clkout0 camera_video_clk} {
    set timing_s1_c [get_clocks -quiet $timing_s1_clock]
    if {[llength $timing_s1_c] != 1} {error "Missing required clock: $timing_s1_clock"}
    report_timing -from $timing_s1_c -to $timing_s1_c -delay_type max -max_paths 100 -nworst 1 \
        -file [file join $timing_s1_reports ${timing_s1_clock}_worst100.rpt]
}
# Always preserve diagnostic reports. Negative timing must not be labelled closed.
set timing_s1_setup [get_timing_paths -delay_type max -max_paths 1]
set timing_s1_hold [get_timing_paths -delay_type min -max_paths 1]
set timing_s1_fd [open [file join $timing_s1_reports status.txt] w]
puts $timing_s1_fd "WNS=[get_property SLACK $timing_s1_setup]"
puts $timing_s1_fd "WHS=[get_property SLACK $timing_s1_hold]"
puts $timing_s1_fd "SIGNOFF=CHECK_SUMMARY_ROUTE_DRC_AND_FUNCTIONAL_REPORTS"
close $timing_s1_fd
unset timing_s1_reports timing_s1_clock timing_s1_c timing_s1_setup timing_s1_hold timing_s1_fd
