# Only first-stage inputs of explicit two-stage CDC reset synchronizers and
# asynchronous assertion pins of the platform synchronizer are exceptions.
# All synchronous functional resets, CDC stage-2 D paths and data stay timed.
set stream_reset_first [get_cells -hier -quiet -regexp \
    {^u_capture_ingress_bridge/g_channel\[[0-7]\]\.u_hdmi_stream_cdc/(m_resetn_sync|fifo_reset_m_sync)_reg\[0\]$}]
if {[info exists timing_s3_baseline_check]} {
    if {![llength $stream_reset_first]} {error "Baseline stream reset synchronizers not found"}
} elseif {[llength $stream_reset_first] != 16} {
    error "S3 expected 16 local stream reset first stages, found [llength $stream_reset_first]"
}
foreach cell $stream_reset_first {
    if {![get_property ASYNC_REG $cell]} {error "Not an ASYNC_REG first stage: $cell"}
    set p [get_pins -of_objects $cell -filter {REF_PIN_NAME == D}]
    if {[llength $p] != 1} {error "Missing stream reset first-stage D: $cell"}
    set_false_path -to $p
}
set platform_reset_stages [get_cells -hier -quiet -regexp \
    {^u_ddr_memory/u_ddr_platform/((video|ddr)_reset_sync_reg\[[0-2]\]|(video|ddr)_reset_release_reg.*)$}]
if {[llength $platform_reset_stages] < 6} {error "Missing platform DDR/video reset release chains"}
foreach cell $platform_reset_stages {
    set p [get_pins -of_objects $cell -filter {REF_PIN_NAME == CLR || REF_PIN_NAME == PRE}]
    if {[llength $p] != 1} {error "Missing platform asynchronous assertion pin: $cell"}
    set_false_path -to $p
}
puts "TIMING_S3_RESET_EXCEPTIONS=PASS stream_first_D=[llength $stream_reset_first] platform_async_assert=[llength $platform_reset_stages]"

# The HDMI XPM reset has four stages. Allow physical duplication of just its
# output stage (2782 loads in S1); retain the first three synchronizing flops.
# Recovery/removal to the IP's functional registers remains constrained.
set hdmi_reset_out [get_cells -hier -quiet -regexp \
    {^u_camera_hdmi/u_hdmi/u_rx/u_hdmi_rx/inst/v_hdmi_rx/inst/SYS_INST/LRST_INST/XPM_RST_INST/syncstages_ff_reg\[3\]$}]
if {[llength $hdmi_reset_out] != 1} {error "Missing HDMI four-stage reset output"}
set_property ASYNC_REG false $hdmi_reset_out
set_property DONT_TOUCH false $hdmi_reset_out
puts "TIMING_S3_HDMI_RESET_OUTPUT_REPLICATION=ENABLED first_three_stages_preserved=1 recovery_checks_preserved=1"
