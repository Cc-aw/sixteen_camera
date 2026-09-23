set repo_dir [file dirname [file dirname [file normalize [info script]]]]
foreach source {
    rtl/interfaces/axi4_if.sv
    rtl/interfaces/axis_video_if.sv
    rtl/video/display/rgb565_to_rgb888.sv
    rtl/video/display/mosaic_rgb565_reader.sv
    sim/display_stage_synthesis_tops.sv
} {
    read_verilog -sv [file join $repo_dir $source]
}
synth_design -top mosaic_rgb565_synth_top -part xcvu13p-fhga2104-2-i \
    -flatten_hierarchy rebuilt
report_utilization -file /tmp/mosaic_rgb565_utilization.rpt
puts "MOSAIC_RGB565_SYNTHESIS=PASS"
