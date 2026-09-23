set repo_dir [file dirname [file dirname [file normalize [info script]]]]
foreach source {
    rtl/interfaces/video_stream_if.sv
    rtl/interfaces/axi4_if.sv
    rtl/video/display/display_frame_packer.sv
    rtl/video/framebuffer/channel_write_fifo.sv
    rtl/video/framebuffer/multi_channel_video_dma.sv
    sim/display_stage_synthesis_tops.sv
} {
    read_verilog -sv [file join $repo_dir $source]
}
synth_design -top display_frame_dma_synth_top -part xcvu13p-fhga2104-2-i \
    -flatten_hierarchy rebuilt
report_utilization -file /tmp/display_frame_dma_utilization.rpt
puts "DISPLAY_FRAME_DMA_SYNTHESIS=PASS"
