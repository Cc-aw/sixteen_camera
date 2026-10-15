# Shared V3 repair hook. Keep the proven mesh/L2 partition, then make the
# 300 MHz crossbar and its final register slice a local DDR-side endpoint.
source [file join [file dirname [info script]] placement_3x32.tcl]
set xbar [get_cells -hierarchical -quiet -regexp {.*u_ddr_bd/design_1_i/axi_interconnect_0/xbar}]
set slice [get_cells -hierarchical -quiet -regexp {.*u_ddr_bd/design_1_i/m00_full_regslice}]
if {[llength $xbar] != 1 || [llength $slice] != 1} {
    error "DDR locality requires exactly one crossbar and one M00 register slice"
}
set locality memory_v3_ddr_xbar_slice_slr0
if {![llength [get_pblocks -quiet $locality]]} {create_pblock $locality}
resize_pblock [get_pblocks $locality] -add SLR0
set_property IS_SOFT true [get_pblocks $locality]
set_property CONTAIN_ROUTING false [get_pblocks $locality]
set_property USER_SLR_ASSIGNMENT SLR0 [concat $xbar $slice]
add_cells_to_pblock [get_pblocks $locality] [concat $xbar $slice]
puts "V3_TIMING_REPAIR_DDR_LOCALITY=SLR0 xbar=$xbar slice=$slice"
# AutonomousLane, tracker and native boundary carry source-level SLR
# attributes in the integrated variant. V3 without the frontend has none.
set lanes [get_cells -hierarchical -quiet -filter {REF_NAME =~ AutonomousLane*}]
if {[llength $lanes] ni {0 3}} {error "Expected zero or three autonomous lanes"}
puts "V3_TIMING_REPAIR_PLACEMENT_PASS autonomous_lanes=[llength $lanes]"
