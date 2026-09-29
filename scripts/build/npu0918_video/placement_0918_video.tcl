# Same hard DSP-only row split as the successful 0918 design. Leave the
# surrounding logic and the video's existing soft pblocks with the placer.
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
    for {set row 0} {$row < 64} {incr row} {
        for {set col 0} {$col < 8} {incr col} {
            set key $instance,$row,$col
            if {![dict exists $tile_counts $key] || [dict get $tile_counts $key] ni {4 8}} {
                error "Expected 4/8 DSPs in tile $key"
            }
        }
        if {[llength [dict get $mesh_cells $instance,$row]] != 48} {
            error "Expected 48 DSPs in $instance row $row"
        }
    }
}
if {$mesh_total != 9216} { error "Expected 9216 mesh DSPs, found $mesh_total" }
foreach {instance first last slr label} {
    applyOrElse    0 55 SLR0 npu0918_g0_rows_0_55
    applyOrElse   56 63 SLR1 npu0918_g0_rows_56_63
    applyOrElse_1  0 15 SLR1 npu0918_g1_rows_0_15
    applyOrElse_1 16 63 SLR2 npu0918_g1_rows_16_63
    applyOrElse_2  0  7 SLR2 npu0918_g2_rows_0_7
    applyOrElse_2  8 63 SLR3 npu0918_g2_rows_8_63
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
    puts "MESH_DSP_PBLOCK_0918 $label rows=$first..$last dsps=[llength $selected] slr=$slr"
}
puts "NPU0918_VIDEO_DSP_GUARD=PASS mesh=$mesh_total full_design=[llength $all_dsps]"
