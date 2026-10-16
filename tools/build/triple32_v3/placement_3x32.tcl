# Keep only DSPs in hard pblocks. Each smaller 32x32 worker fits in one SLR,
# so align the three meshes with their source-level Scratchpad SLR hints and
# leave surrounding logic and video pblocks to the placer.
set rockets [get_cells -hier -quiet -filter {REF_NAME == RocketTile}]
if {[llength $rockets] != 1} { error "Expected exactly one RocketTile" }
set root [get_property NAME $rockets]

# Rebuilt hierarchy can rename the clock port (saved_denied_reg in the
# video checkpoint). Query clocks on the actual input objects instead of
# relying on the RTL port name or selecting a global 100 MHz clock.
set input_pins [get_pins -quiet -of_objects $rockets -filter {DIRECTION == IN}]
if {[llength $input_pins] == 0} { error "RocketTile input pins not found" }
set clocks [get_clocks -quiet -of_objects $input_pins]
if {[llength $clocks] == 0} { error "RocketTile clock is unconstrained" }
foreach c $clocks {
    if {abs([get_property PERIOD $c] - 10.000) > 0.002} {
        error "RocketTile clock must be 100 MHz: $c"
    }
}
puts "NPU0918_VIDEO_CLOCK_OK clocks=$clocks"

# Query primitives once. Repeated whole-design hierarchical scans for each
# tile become expensive with the three meshes and the complete video design.
set all_dsps [get_cells -hier -quiet -filter {REF_NAME == DSP48E2}]
set mesh_cells [dict create]
set tile_counts [dict create]
set mesh_total 0
foreach cell $all_dsps {
    set name [get_property NAME $cell]
    foreach instance {applyOrElse applyOrElse_1 applyOrElse_2} {
        set prefix ${root}/${instance}/ex_controller/mesh/mesh/
        if {[string first $prefix $name] != 0} { continue }
        set tail [string range $name [string length $prefix] end]
        if {![regexp {^mesh_([0-9]+)_([0-9]+)/} $tail -> row col]} {
            error "Unrecognized mesh DSP hierarchy: $name"
        }
        dict lappend mesh_cells $instance,$row $cell
        dict incr tile_counts $instance,$row,$col
        incr mesh_total
    }
}
foreach instance {applyOrElse applyOrElse_1 applyOrElse_2} {
    for {set row 0} {$row < 32} {incr row} {
        for {set col 0} {$col < 4} {incr col} {
            set key $instance,$row,$col
            if {![dict exists $tile_counts $key] || [dict get $tile_counts $key] ni {4 8}} {
                error "Expected 4/8 DSPs in tile $key"
            }
        }
        if {[llength [dict get $mesh_cells $instance,$row]] != 24} {
            error "Expected 24 DSPs in $instance row $row"
        }
    }
}
if {$mesh_total != 2304} { error "Expected 2304 mesh DSPs, found $mesh_total" }
foreach {instance first last slr label} {
    applyOrElse    0 31 SLR0 npu3x32_g0_rows_0_31
    applyOrElse_1  0 31 SLR1 npu3x32_g1_rows_0_31
    applyOrElse_2  0 31 SLR3 npu3x32_g2_rows_0_31
} {
    set selected {}
    for {set row $first} {$row <= $last} {incr row} {
        lappend selected {*}[dict get $mesh_cells $instance,$row]
    }
    if {[llength [get_pblocks -quiet $label]] == 0} { create_pblock $label }
    resize_pblock [get_pblocks $label] -add $slr
    set_property IS_SOFT false [get_pblocks $label]
    set_property CONTAIN_ROUTING false [get_pblocks $label]
    add_cells_to_pblock [get_pblocks $label] $selected
    puts "MESH_DSP_PBLOCK_3X32 $label rows=$first..$last dsps=[llength $selected] slr=$slr"
}

# V2 left the third worker's command queue in SLR2 while its reservation
# station and mesh were in SLR3. That boundary accounts for 388 of the 1596
# setup failures. This is deliberately a soft guide covering only the queue
# and reservation station, not a broad worker pblock, so timing placement can
# override it and SLR3 routing is not contained.
set worker2_frontend [get_cells -hierarchical -regexp \
    [format {%s/applyOrElse_2/(unrolled_cmd_q|reservation_station)(/.*)?} $root]]
if {[llength $worker2_frontend] == 0} {
    error "Gemmini2 queue/reservation-station cells not found"
}
set worker2_pblock npu3x32_g2_queue_rs_slr3
if {[llength [get_pblocks -quiet $worker2_pblock]] == 0} {
    create_pblock $worker2_pblock
}
resize_pblock [get_pblocks $worker2_pblock] -add SLR3
set_property IS_SOFT true [get_pblocks $worker2_pblock]
set_property CONTAIN_ROUTING false [get_pblocks $worker2_pblock]
add_cells_to_pblock [get_pblocks $worker2_pblock] $worker2_frontend
puts "GEMMINI2_QUEUE_RS_GUIDE cells=[llength $worker2_frontend] slr=SLR3 soft=true"

# Spread the enlarged cache; retain the saved bank0/bank1 guides for fallback.
source [file join [file dirname [info script]] placement_l2_banks.tcl]
puts "NPU3X32_VIDEO_DSP_GUARD=PASS mesh=$mesh_total full_design=[llength $all_dsps]"
