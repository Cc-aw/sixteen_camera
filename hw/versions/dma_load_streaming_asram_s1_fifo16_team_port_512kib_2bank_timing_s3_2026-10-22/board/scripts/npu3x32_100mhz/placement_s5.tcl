# Retain the successful S4 L2/DSP distribution and upsizer constraints.
set s5_place_dir [file dirname [info script]]
source [file join $s5_place_dir placement_s4.tcl]

# S4 left the DDR event counters in SLR1 while their observed AXI source was
# in SLR0. Small feedback/decoder paths then crossed an SLR at 300 MHz.
# Keep UI logic near MIG; do not constrain PHY or move the SoC snapshot bank.
set s5_ddr_prefix u_ddr_memory/u_ddr_platform/u_ddr_bd/design_1_i
set s5_ddr_cells {}
foreach name [list ${s5_ddr_prefix}/axi_interconnect_0/xbar \
                   ${s5_ddr_prefix}/m00_full_regslice \
                   u_ddr_memory/u_ddr_platform/u_mig_events \
                   u_ddr_memory/u_memory_perf/u_video_events] {
    set cell [get_cells -quiet $name]
    if {[llength $cell] != 1} {error "S5 missing DDR UI hierarchy: $name"}
    lappend s5_ddr_cells $cell
}
# Dual-clock BRAM is one physical cell with ports in both domains. Select
# only FFs here so the video-side FIFO storage keeps its placement freedom.
set s5_ui_regs [filter [all_registers -clock [get_clocks mmcm_clkout0]] {REF_NAME =~ FD*}]
set s5_counter_regs [filter $s5_ui_regs {NAME =~ u_ddr_memory/u_memory_perf/u_async/*}]
set s5_bridge_regs [filter $s5_ui_regs \
    {NAME =~ u_ddr_memory/u_video_memory_ports/u_writer_ui_cdc/* ||
     NAME =~ u_ddr_memory/u_video_memory_ports/u_reader_ui_cdc/*}]
if {[llength $s5_counter_regs] < 1000 || [llength $s5_bridge_regs] < 20} {
    error "S5 DDR UI register discovery failed: counter=[llength $s5_counter_regs] bridge=[llength $s5_bridge_regs]"
}
set s5_ddr_pb timing_s5_ddr_ui_slr0
if {[llength [get_pblocks -quiet $s5_ddr_pb]]} {delete_pblocks [get_pblocks $s5_ddr_pb]}
create_pblock $s5_ddr_pb
resize_pblock [get_pblocks $s5_ddr_pb] -add SLR0
set_property CONTAIN_ROUTING false [get_pblocks $s5_ddr_pb]
set_property IS_SOFT false [get_pblocks $s5_ddr_pb]
add_cells_to_pblock [get_pblocks $s5_ddr_pb] $s5_ddr_cells
# Pass large Vivado collections directly. Tcl list expansion truncates them
# at collectionResultDisplayLimit and can silently omit most of the FFs.
add_cells_to_pblock [get_pblocks $s5_ddr_pb] $s5_counter_regs
add_cells_to_pblock [get_pblocks $s5_ddr_pb] $s5_bridge_regs
set s5_direct_count [llength [get_cells -quiet -of_objects [get_pblocks $s5_ddr_pb]]]
# Vivado can promote an assignment to a complete small hierarchy, so the
# direct-member count is slightly smaller than the number of register cells.
# Detect collection truncation without rejecting this legitimate promotion.
if {$s5_direct_count < 0.95*([llength $s5_counter_regs]+[llength $s5_bridge_regs])} {
    error "S5 incomplete UI pblock: $s5_direct_count cells"
}
foreach last [list [lindex $s5_counter_regs end] [lindex $s5_bridge_regs end]] {
    if {[lsearch -exact [get_pblocks -quiet -of_objects $last] $s5_ddr_pb] < 0} {
        error "S5 UI pblock omitted collection tail: $last"
    }
}
if {[get_property IS_SOFT [get_pblocks $s5_ddr_pb]] ||
    [get_property CONTAIN_ROUTING [get_pblocks $s5_ddr_pb]]} {error "S5 DDR pblock properties failed"}
puts "TIMING_S5_UI_LOCALITY=PASS counter_source_regs=[llength $s5_counter_regs] bridge_ui_regs=[llength $s5_bridge_regs] SLR0 hard=true routing_containment=false"

source [file join $s5_place_dir camera_placement_s5.tcl]
if {[info exists timing_s5_baseline_check]} {
    set timing_s5_replication_query_only 1
    set timing_s5_replication_probe 1
    source [file join $s5_place_dir replicate_s5_critical_controls.tcl]
    unset timing_s5_replication_query_only timing_s5_replication_probe
}
unset s5_place_dir s5_ddr_prefix s5_ddr_cells s5_ui_regs s5_counter_regs s5_bridge_regs s5_ddr_pb s5_direct_count
