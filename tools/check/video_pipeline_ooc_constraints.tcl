# Apply the production endpoint exceptions at the local OOC hierarchy.
# No clock-domain exception; second stages and functional consumers stay timed.
set repo [file dirname [file dirname [file dirname [file normalize [info script]]]]]
if {$kind eq "perf-reset"} {
    set memory_perf_hierarchy "u_async/"
    set memory_perf_local_reset_pattern local_reset_sync_reg*
    source [file join $repo hw constraints memory_parallel_v3_cdc.tcl]
} elseif {$kind eq "camera"} {
    set first_inputs [get_pins -hier -quiet -filter \
        {NAME =~ dut/capture_enable_sync1_reg/D || \
         NAME =~ dut/diag_clear_video_sync1_reg/D || \
         NAME =~ dut/u_camera_telemetry/*/request_sync_reg[0]/D || \
         NAME =~ dut/u_camera_telemetry/*/payload_sync1_reg*/D || \
         NAME =~ dut/u_camera_telemetry/*/acknowledge_sync_reg[0]/D}]
    if {![llength $first_inputs]} {error "Camera first-stage mailbox inputs missing"}
    set_false_path -to $first_inputs
    # capture_resetn_sync is in the channel wrapper, outside this frontend
    # OOC top. Its two assertion pins are constrained in the production hook.
}
