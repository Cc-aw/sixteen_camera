set root [file dirname [file dirname [file normalize [info script]]]]
read_verilog -sv [file join $root rtl interfaces axi4_if.sv]
read_verilog -sv [file join $root rtl ai postprocess fbus_read_engine.sv]
read_verilog -sv [file join $root sim fbus_reader_synthesis_top.sv]
synth_design -top fbus_reader_synthesis_top -part xcvu13p-fhga2104-2-i \
    -mode out_of_context -flatten_hierarchy rebuilt
create_clock -name fbus_clock -period 10.000 [get_ports clk]
report_utilization -file /tmp/fbus_reader_utilization.rpt
report_timing_summary -delay_type max -max_paths 5 -file /tmp/fbus_reader_timing.rpt
set brams [get_cells -hierarchical -filter {REF_NAME =~ RAMB*}]
if {[llength $brams] == 0} { error "Reader reorder RAM did not infer block RAM" }
set worst_path [lindex [get_timing_paths -delay_type max -max_paths 1] 0]
if {[llength $worst_path] == 0} { error "No reader setup path" }
set slack [get_property SLACK $worst_path]
puts "FBUS_READER_BRAM_CELLS=[llength $brams]"
puts "FBUS_READER_SYNTHESIS_SLACK_NS=$slack"
if {$slack < 0} { error "Reader synthesis misses 100 MHz" }
puts "FBUS_READER_SYNTHESIS=PASS"
