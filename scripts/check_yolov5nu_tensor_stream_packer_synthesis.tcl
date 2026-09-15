set root [file dirname [file dirname [file normalize [info script]]]]
read_verilog -sv [file join $root rtl ai preprocess yolov5nu_tensor_stream_packer.sv]
synth_design -top yolov5nu_tensor_stream_packer \
    -part xcvu13p-fhga2104-2-i -mode out_of_context \
    -flatten_hierarchy rebuilt
create_clock -name video_clock -period 6.666 [get_ports clk]
report_utilization
report_timing_summary -delay_type max -max_paths 5
set worst_path [lindex [get_timing_paths -delay_type max -max_paths 1] 0]
if {[llength $worst_path] == 0} {
    error "No tensor stream setup timing path was found"
}
set worst_slack [get_property SLACK $worst_path]
if {$worst_slack < 0.0} {
    error "Tensor stream packer 150 MHz synthesis violation: $worst_slack ns"
}
puts "YOLOV5NU_TENSOR_STREAM_PACKER_SYNTHESIS=PASS"
