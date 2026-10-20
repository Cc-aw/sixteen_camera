set s4_place_dir [file dirname [info script]]
source [file join $s4_place_dir placement_3x32.tcl]
if {[info exists timing_s4_baseline_check]} {
    foreach bank {inclusive_cache_bank_sched inclusive_cache_bank_sched_1} {
        set cells [get_cells -hier -quiet -filter "NAME =~ */coh_wrapper/l2/$bank"]
        report_utilization -cells $cells -file [file normalize [file join $s4_place_dir .. .. validation s1_baseline ${bank}_utilization.rpt]]
    }
}
# The Oct16 result fills 95.46%/99.48% of SLR0/1 CLBs.
# S2 moved both banks into SLR2: TNS improved, but SLR2 then filled 96.39%.
# Keep one whole bank in SLR2 and move bank0 to SLR3 (S2: 56.15% CLBs),
# Retain this bank distribution to isolate the S4 RTL effect. S4 replaces
# the S3 tag matrix with cached queue heads and local predecoded plans.
# The Head AXI slice cuts the long external path. MSHR data paths were
# already intra-SLR; this change addresses congestion, not a false crossing.
foreach {bank old_pb new_pb} {
    inclusive_cache_bank_sched memory_v3_l2_bank0_slr0 timing_s4_l2_bank0_slr3
    inclusive_cache_bank_sched_1 memory_v3_l2_bank1_slr2 timing_s4_l2_bank1_slr2
} {
    set bank_cell [get_cells -hier -quiet -filter "NAME =~ */coh_wrapper/l2/$bank"]
    if {[llength $bank_cell] != 1} {error "Missing cache bank $bank"}
    if {[llength [get_pblocks -quiet $old_pb]]} {delete_pblocks [get_pblocks $old_pb]}
    if {![llength [get_pblocks -quiet $new_pb]]} {create_pblock $new_pb}
    set slr [expr {$bank eq "inclusive_cache_bank_sched" ? "SLR3" : "SLR2"}]
    resize_pblock [get_pblocks $new_pb] -add $slr
    set_property IS_SOFT false [get_pblocks $new_pb]
    set_property CONTAIN_ROUTING false [get_pblocks $new_pb]
    set_property USER_SLR_ASSIGNMENT $slr $bank_cell
    add_cells_to_pblock [get_pblocks $new_pb] $bank_cell
    puts "TIMING_S4_L2_BANK_LOCALITY bank=$bank slr=$slr hard=[expr {![get_property IS_SOFT [get_pblocks $new_pb]]}] routing_containment=false"
}
# The retained 300 MHz response-FIFO busy -> write-enable path leaves SLR1, enters
# SLR0, then returns to SLR1. Keep only this small read bridge local to MIG.
# The large video and Gemmini allocations retain the baseline guides.
set reader_bridge [get_cells -quiet u_ddr_memory/u_video_memory_ports/u_reader_ui_cdc]
if {[llength $reader_bridge] != 1} {error "Missing UI read CDC bridge"}
set reader_pb timing_s4_ui_reader_slr0
if {![llength [get_pblocks -quiet $reader_pb]]} {create_pblock $reader_pb}
resize_pblock [get_pblocks $reader_pb] -add SLR0
set_property IS_SOFT false [get_pblocks $reader_pb]
set_property CONTAIN_ROUTING false [get_pblocks $reader_pb]
add_cells_to_pblock [get_pblocks $reader_pb] $reader_bridge
puts "TIMING_S4_UI_READER_LOCALITY=SLR0 routing_containment=false"
unset s4_place_dir

# S3's UI worst path is now INSIDE the s01 width converter, with the
# ready/enable feedback routed SLR1 -> SLR0 -> SLR1 (3.119ns routing).
# Keep the two small 300MHz converters near MIG, without constraining PHY.
# Discover the two actual width converters in the linked implementation
# netlist. In this BD s00 has only auto_cc; auto_us belongs to s01 and s02.
# Check the complete collection before creating either pblock so a changed
# BD cannot silently receive only half of the intended timing constraints.
set s4_interconnect u_ddr_memory/u_ddr_platform/u_ddr_bd/design_1_i/axi_interconnect_0
set s4_upsizers [get_cells -hier -quiet -filter "NAME =~ ${s4_interconnect}/s*_couplers/auto_us"]
if {[llength $s4_upsizers] != 2} {
    error "Expected two DDR upsizers after linking; found [llength $s4_upsizers]: $s4_upsizers"
}
foreach cell $s4_upsizers {
    set name [get_property NAME $cell]
    if {![regexp {/(s[0-9]+_couplers)/auto_us$} $name -> coupler]} {
        error "Unrecognized DDR upsizer hierarchy: $name"
    }
    set pb timing_s4_ui_upsizer_$coupler
    if {![llength [get_pblocks -quiet $pb]]} {create_pblock $pb}
    resize_pblock [get_pblocks $pb] -add SLR0
    set_property CONTAIN_ROUTING false [get_pblocks $pb]
    # In Vivado 2023.2 setting CONTAIN_ROUTING=false restores IS_SOFT=true.
    # Apply the hard placement property last and verify the resulting values.
    set_property IS_SOFT false [get_pblocks $pb]
    add_cells_to_pblock [get_pblocks $pb] $cell
    if {[get_property IS_SOFT [get_pblocks $pb]] ||
        [get_property CONTAIN_ROUTING [get_pblocks $pb]]} {
        error "DDR upsizer pblock properties did not take effect: $pb"
    }
    puts "TIMING_S4_UI_UPSIZER_LOCALITY=$coupler SLR0"
}
puts "TIMING_S4_UI_UPSIZERS_CHECKED=[llength $s4_upsizers]"
unset s4_interconnect s4_upsizers

