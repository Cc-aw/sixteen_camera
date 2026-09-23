set repo_dir [file dirname [file dirname [file normalize [info script]]]]
foreach source {
    rtl/interfaces/video_stream_if.sv
    rtl/video/display/rgb888_to_rgb565.sv
    rtl/video/display/display_scaler.sv
    sim/display_stage_synthesis_tops.sv
} {
    read_verilog -sv [file join $repo_dir $source]
}
synth_design -top display_scaler_synth_top -part xcvu13p-fhga2104-2-i \
    -flatten_hierarchy rebuilt
report_utilization -file /tmp/display_scaler_utilization.rpt
puts "DISPLAY_SCALER_SYNTHESIS=PASS"
