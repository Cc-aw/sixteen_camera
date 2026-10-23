source [file join [file dirname [info script]] memory_s4_pre_opt.tcl]

# These six pins are the FIRST stages of explicit two-FF reset/status
# synchronizers in the unrelated Tensor video/SoC bridge. XPM constrains its
# own Gray pointers, but does not know about this wrapper's reset handshake.
# Keep the second stages and all same-domain functional paths timed.
set s2_reset_inputs [get_cells -hier -quiet -regexp \
    {^u_ddr_memory/u_tensor_memory_bridge/u_cdc/u_(aw|w|b)/(r_resetn_wsync|fifo_reset_rsync)_reg\[0\]$}]
if {[llength $s2_reset_inputs] != 6} {
    error "Timing S2 expects exactly six Tensor CDC first stages, found [llength $s2_reset_inputs]"
}
foreach s2_cell $s2_reset_inputs {
    if {[get_property ASYNC_REG $s2_cell] ni {1 true TRUE}} {
        error "Tensor CDC entry is not an explicit synchronizer: $s2_cell"
    }
}
set s2_reset_pins [get_pins -of_objects $s2_reset_inputs -filter {REF_PIN_NAME == D}]
if {[llength $s2_reset_pins] != 6} {error "Incomplete Tensor CDC pin set"}
set_false_path -to $s2_reset_pins
puts "TIMING_S2_CDC_FIRST_STAGE_PINS=[llength $s2_reset_pins] NO_DOMAIN_WIDE_EXCEPTIONS=1"
unset s2_reset_inputs s2_reset_pins s2_cell
