source [file join [file dirname [info script]] postroute_timing_s1.tcl]
set s2_dir [file normalize [file join [pwd] timing_s2_reports]]
file mkdir $s2_dir
report_power -file [file join $s2_dir power.rpt]
report_clock_interaction -file [file join $s2_dir clock_interaction.rpt]
report_cdc -file [file join $s2_dir cdc.rpt]
report_control_sets -verbose -file [file join $s2_dir control_sets.rpt]
puts "TIMING_S2_EXTENDED_REPORTS=$s2_dir"
unset s2_dir
