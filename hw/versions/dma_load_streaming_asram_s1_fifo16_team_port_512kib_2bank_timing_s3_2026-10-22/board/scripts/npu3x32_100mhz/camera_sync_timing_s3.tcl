# IOB locations follow fixed package pins even before placement. Restrict only
# the 11 second-stage sampling FFs per camera to their input banks' clock
# regions. Keep the existing 1.500ns requirement and every clock unchanged.
set s3_sync_total 0
for {set s3_ch 0} {$s3_ch < 8} {incr s3_ch} {
    set s3_names [list [format {cam_pclk[%d]} $s3_ch] \
        [format {cam_href[%d]} $s3_ch] [format {cam_vsync[%d]} $s3_ch]]
    for {set s3_bit 0} {$s3_bit < 8} {incr s3_bit} {
        lappend s3_names [format {cam_data[%d]} [expr {8*$s3_ch+$s3_bit}]]
    }
    set s3_ports [get_ports $s3_names]
    set s3_regions [get_clock_regions -of_objects [get_iobanks -of_objects $s3_ports]]
    set s3_regs [get_cells -hier -quiet -regexp [format \
        {^u_camera_hdmi/u_camera_subsystem/g_camera_frontend\[%d\]\.u_channel/u_frontend/u_input_sampler/dvp_(data|href|vsync|pclk)_sync_reg.*$} $s3_ch]]
    if {[llength $s3_ports] != 11 || [llength $s3_regs] != 11 || ![llength $s3_regions]} {
        error "S3 camera $s3_ch locality discovery failed"
    }
    # Replace the inherited broad SLR hint for these leaves only.
    foreach s3_old [get_pblocks -quiet pblock_dvp_sync*] {
        set s3_members [get_cells -quiet -of_objects $s3_old]
        set s3_remove {}
        foreach s3_reg $s3_regs {
            if {[lsearch -exact $s3_members $s3_reg] >= 0} {lappend s3_remove $s3_reg}
        }
        if {[llength $s3_remove]} {remove_cells_from_pblock $s3_old $s3_remove}
    }
    set s3_pb [create_pblock timing_s3_camera_sync_ch${s3_ch}]
    set s3_ranges {}
    foreach s3_region $s3_regions {
        lappend s3_ranges CLOCKREGION_[get_property NAME $s3_region]
    }
    resize_pblock $s3_pb -add $s3_ranges
    set_property IS_SOFT false $s3_pb
    set_property CONTAIN_ROUTING false $s3_pb
    add_cells_to_pblock $s3_pb $s3_regs
    puts "TIMING_S3_CAMERA=$s3_ch SYNC_FFS=[llength $s3_regs] INPUT_CLOCK_REGIONS=$s3_regions MAX_DELAY_NS=1.500"
    incr s3_sync_total [llength $s3_regs]
}
if {$s3_sync_total != 88} {error "S3 incomplete camera sampler selection"}
puts TIMING_S3_CAMERA_SYNC_LOCALITY_PASS
unset s3_sync_total s3_ch s3_names s3_bit s3_ports s3_regions s3_regs s3_old s3_members s3_remove s3_reg s3_pb s3_ranges s3_region
