# Synthesis-level timing gate for the 150.06 MHz Display AXIS domain.
source [file join [file dirname [file normalize [info script]]] \
    check_display_reader_integration_synthesis.tcl]
create_clock -name video_clk -period 6.664 [get_ports clk]
set timing_path [get_timing_paths -setup -max_paths 1]
if {[llength $timing_path] != 1} {
    error "Display reader timing path was not found"
}
set slack [get_property SLACK $timing_path]
report_timing_summary -file /tmp/display_reader_150mhz_timing.rpt
puts "DISPLAY_READER_150MHZ_WORST_SLACK=$slack"
if {$slack < 0} {
    error "Display reader fails 150.06 MHz synthesis timing"
}
puts "DISPLAY_READER_150MHZ_SYNTHESIS=PASS"
