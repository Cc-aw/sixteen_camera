set root [file dirname [file dirname [file normalize [info script]]]]
read_verilog -sv [file join $root rtl interfaces axi4_if.sv]
foreach source {head_publication_manager.sv ppu_cache_publish_engine.sv ppu_publication_write_mux.sv} {
    read_verilog -sv [file join $root rtl ai postprocess $source]
}
read_verilog -sv [file join $root sim ppu_publication_synthesis_top.sv]
synth_design -top ppu_publication_synthesis_top -part xcvu13p-fhga2104-2-i -mode out_of_context -flatten_hierarchy rebuilt
create_clock -name ppu_clock -period 10.000 [get_ports clk]
report_utilization
report_timing_summary -delay_type max -max_paths 5
set path [lindex [get_timing_paths -delay_type max -max_paths 1] 0]
if {[llength $path]==0 || [get_property SLACK $path]<0} {error "Publication 100 MHz timing failed"}
puts "YOLOV5NU_POSTPROCESS_SYNTHESIS=PASS"
