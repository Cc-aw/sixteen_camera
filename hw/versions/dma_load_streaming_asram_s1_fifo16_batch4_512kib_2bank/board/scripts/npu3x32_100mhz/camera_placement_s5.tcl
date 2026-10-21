# Separate the IOB aperture from the crossing launch stage. Full-SLR
# pblocks include Laguna resources, avoiding the former UTLZ-3 failure.
set s5_local_total 0
foreach {channels slr label} {0-3 SLR3 timing_s5_dvp_local_slr3 4-7 SLR2 timing_s5_dvp_local_slr2} {
    set pattern [format {.*g_camera_frontend\[[%s]\]\.u_channel/u_frontend/u_input_sampler/local_(data|href|vsync|pclk)_reg.*} $channels]
    set local_regs [get_cells -hier -quiet -regexp $pattern]
    if {![llength $local_regs] && [info exists timing_s5_baseline_check]} {continue}
    if {[llength $local_regs] != 44} {error "S5 expected 44 local camera registers in $slr; found [llength $local_regs]"}
    if {![llength [get_pblocks -quiet $label]]} {create_pblock $label}
    resize_pblock [get_pblocks $label] -add $slr
    set_property CONTAIN_ROUTING false [get_pblocks $label]
    set_property IS_SOFT false [get_pblocks $label]
    add_cells_to_pblock [get_pblocks $label] $local_regs
    incr s5_local_total [llength $local_regs]
}
puts "TIMING_S5_CAMERA_LOCAL_LAUNCH_REGS=$s5_local_total"
unset s5_local_total
