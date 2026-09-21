set repo_dir [file dirname [file dirname [file normalize [info script]]]]
foreach source {
    rtl/interfaces/axi_lite_if.sv
    rtl/common/cdc/cdc_mailbox.sv
    rtl/control/telemetry/tensor_telemetry_cdc.sv
    rtl/video/framebuffer/multi_channel_framebuffer_ctrl.sv
    rtl/video/video_control_bridge.sv
} {
    read_verilog -sv [file join $repo_dir $source]
}
synth_design -top video_control_bridge -part xcvu13p-fhga2104-2-i \
    -flatten_hierarchy rebuilt
report_utilization -file /tmp/video_control_bridge_utilization.rpt
puts "VIDEO_CONTROL_BRIDGE_SYNTHESIS=PASS"
