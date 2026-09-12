set root [file dirname [file dirname [file normalize [info script]]]]
foreach source {
    yolov5nu_raw_class_lut.sv
    yolov5nu_dfl_lut.sv
    yolov5nu_class_reducer.sv
    yolov5nu_dfl_decoder.sv
    yolov5nu_bbox_decoder.sv
    yolov5nu_topk_nms.sv
    yolov5nu_postprocessor.sv
} {
    read_verilog -sv [file join $root rtl ai postprocess $source]
}
synth_design -top yolov5nu_postprocessor -part xcvu13p-fhga2104-2-i \
    -mode out_of_context -flatten_hierarchy rebuilt
create_clock -name ppu_clock -period 10.000 [get_ports clk]
report_utilization
report_timing_summary -delay_type max -max_paths 5
set worst_path [lindex [get_timing_paths -delay_type max -max_paths 1] 0]
if {[llength $worst_path] == 0} {
    error "No postprocessor setup timing path was found"
}
set worst_slack [get_property SLACK $worst_path]
if {$worst_slack < 0.0} {
    error "Postprocessor 100 MHz synthesis setup timing violation: $worst_slack ns"
}
puts "YOLOV5NU_POSTPROCESS_SYNTHESIS=PASS"
