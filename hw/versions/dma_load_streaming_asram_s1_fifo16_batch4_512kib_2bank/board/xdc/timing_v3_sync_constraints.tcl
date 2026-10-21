# Apply after synth, when ASYNC_REG cell objects and their pins are available.
# Cut only the input of the explicitly implemented reset synchronizers.
# Never exclude functional resets, second-stage D paths, FIFO payloads, or
# synchronous video/UI datapaths.
set video_reset_stage1 [get_cells -hier -quiet -regexp \
    {^u_ddr_memory/u_video_memory_ports/u_(reader|writer)_ui_cdc/u_(ar|r|aw|w|b)/(r_resetn_wsync|fifo_reset_rsync)_reg\[0\]$}]
if {[llength $video_reset_stage1] != 10} {
    error "Expected 10 video/UI reset first-stage synchronizers; got [llength $video_reset_stage1]"
}
foreach cell $video_reset_stage1 {
    if {![get_property ASYNC_REG $cell]} {
        error "Video/UI reset input is not an ASYNC_REG synchronizer: $cell"
    }
    set pins [get_pins -quiet -of_objects $cell -filter {REF_PIN_NAME == D}]
    if {[llength $pins] != 1} {error "Missing reset synchronizer D: $cell"}
    set_false_path -to $pins
}
set camera_reset_stages [get_cells -hier -quiet -regexp \
    {^u_camera_hdmi/u_camera_subsystem/g_camera_frontend\[[0-7]\]\.u_channel/capture_resetn_sync_reg\[[01]\]$}]
if {[llength $camera_reset_stages] != 16} {
    error "Expected 16 camera asynchronous-reset synchronizer stages; got [llength $camera_reset_stages]"
}
foreach cell $camera_reset_stages {
    if {![get_property ASYNC_REG $cell]} {error "Camera reset stage is not ASYNC_REG: $cell"}
    set pins [get_pins -quiet -of_objects $cell -filter {REF_PIN_NAME == CLR || REF_PIN_NAME == PRE}]
    if {[llength $pins] != 1} {error "Missing asynchronous-reset pin: $cell"}
    set_false_path -to $pins
}
puts "TIMING_V3_RESET_SYNCHRONIZERS=PASS video_first_stages=10 camera_async_reset_stages=16"

# The new UI return queue clears on the same remote-video reset as its CDC
# FIFO. Only its first synchronizer input is asynchronous; retain stage 2
# and all synchronous queue reset/ready paths in timing analysis.
set return_reset_stage1 [get_cells -hier -quiet -regexp \
    {^u_ddr_memory/u_video_memory_ports/u_reader_ui_cdc/video_resetn_ui_sync_reg\[0\]$}]
if {![llength $return_reset_stage1] && [info exists timing_v3_baseline_check]} {
    puts "TIMING_V3_RETURN_RESET=not present in unchanged baseline"
} else {
    if {[llength $return_reset_stage1] != 1 ||
        ![get_property ASYNC_REG $return_reset_stage1]} {
        error "Missing ASYNC_REG first stage for the UI return queue reset"
    }
    set return_reset_pin [get_pins -of_objects $return_reset_stage1 -filter {REF_PIN_NAME == D}]
    if {[llength $return_reset_pin] != 1} {error "Missing UI return reset first-stage D pin"}
    set_false_path -to $return_reset_pin
}
