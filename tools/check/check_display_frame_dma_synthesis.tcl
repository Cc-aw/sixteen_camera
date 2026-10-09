set repo_dir [file dirname [file dirname [file dirname [file normalize [info script]]]]]
foreach source {
    hw/rtl/interfaces/video_stream_if.sv
    hw/rtl/interfaces/axi4_if.sv
    hw/rtl/video/display/display_frame_packer.sv
    hw/rtl/video/framebuffer/channel_write_fifo.sv
    hw/rtl/video/framebuffer/multi_channel_video_dma.sv
    tests/rtl/benches/video/display_stage_synthesis_tops.sv
} {
    read_verilog -sv [file join $repo_dir $source]
}
synth_design -top display_frame_dma_synth_top -part xcvu13p-fhga2104-2-i \
    -flatten_hierarchy rebuilt
report_utilization -file /tmp/display_frame_dma_utilization.rpt
puts "DISPLAY_FRAME_DMA_SYNTHESIS=PASS"
