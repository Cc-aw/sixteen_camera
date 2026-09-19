set root [file dirname [file dirname [file normalize [info script]]]]
read_verilog -sv [file join $root rtl interfaces axi4_if.sv]
read_verilog -sv [file join $root rtl ai postprocess head_uram_store.sv]
read_verilog -sv [file join $root rtl ai postprocess axi4_head_uram_router.sv]
read_verilog -sv [file join $root sim head_uram_router_synthesis_top.sv]
synth_design -top head_uram_router_synthesis_top \
    -part xcvu13p-fhga2104-2-i -mode out_of_context \
    -flatten_hierarchy rebuilt
create_clock -name head_router_clock -period 10.000 [get_ports clk]
set uram_count [llength [get_cells -hier -filter {REF_NAME =~ URAM288*}]]
puts "HEAD_URAM_P2_URAM_COUNT=$uram_count"
report_utilization
report_timing_summary -delay_type max -max_paths 5
if {$uram_count != 128} {
    error "Expected four 1 MiB Head slots to infer 128 URAM288 primitives, got $uram_count"
}
set worst_path [lindex [get_timing_paths -delay_type max -max_paths 1] 0]
if {[llength $worst_path] == 0} {
    error "No Head URAM P2 setup timing path was found"
}
set worst_slack [get_property SLACK $worst_path]
if {$worst_slack < 0.0} {
    error "Head URAM P2 100 MHz synthesis timing violation: $worst_slack ns"
}
puts "HEAD_URAM_P2_SYNTHESIS=PASS"
