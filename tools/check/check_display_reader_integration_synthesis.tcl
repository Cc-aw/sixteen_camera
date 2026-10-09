set repo_dir [file dirname [file dirname [file dirname [file normalize [info script]]]]]
foreach source {
    hw/rtl/interfaces/axi4_if.sv
    hw/rtl/interfaces/axis_video_if.sv
    hw/rtl/video/display/rgb565_to_rgb888.sv
    hw/rtl/video/display/full_rgb565_reader.sv
    hw/rtl/video/display/mosaic_rgb565_reader.sv
    hw/rtl/video/overlay/detection_overlay.sv
    hw/rtl/video/framebuffer/display_reader_subsystem.sv
    tests/rtl/benches/video/display_stage_synthesis_tops.sv
} {
    read_verilog -sv [file join $repo_dir $source]
}
synth_design -top display_reader_compact_synth_top \
    -part xcvu13p-fhga2104-2-i -flatten_hierarchy rebuilt
report_utilization -file /tmp/display_reader_compact_utilization.rpt
puts "DISPLAY_READER_COMPACT_SYNTHESIS=PASS"
