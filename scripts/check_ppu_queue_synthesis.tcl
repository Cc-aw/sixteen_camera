set root [file dirname [file dirname [file normalize [info script]]]]
foreach source {ppu_descriptor_fifo.sv ppu_command_queue.sv} {
 read_verilog -sv [file join $root rtl ai postprocess $source]
}
synth_design -top ppu_command_queue -part xcvu13p-fhga2104-2-i -mode out_of_context -flatten_hierarchy rebuilt
create_clock -name ppu_clock -period 10.000 [get_ports clk]
report_utilization
report_timing_summary -delay_type max -max_paths 5
set path [lindex [get_timing_paths -delay_type max -max_paths 1] 0]
if {[llength $path]==0 || [get_property SLACK $path]<0} {error "Queue 100 MHz timing failed"}
puts "YOLOV5NU_POSTPROCESS_SYNTHESIS=PASS"
