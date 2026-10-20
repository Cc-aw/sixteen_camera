# Placement only: no clock, delay, CDC or timing exception commands.
namespace eval ::asram_physical {}

proc ::asram_physical::one {pattern} {
    set cells [get_cells -hier -quiet -filter "NAME =~ $pattern"]
    if {[llength $cells] != 1} {error "Expected exactly one physical hierarchy: $pattern"}
    return $cells
}

proc ::asram_physical::pblock {label regions cells soft} {
    # Recreate this version's own block so re-sourcing never widens old ranges.
    if {[llength [get_pblocks -quiet $label]]} {delete_pblocks [get_pblocks $label]}
    create_pblock $label
    resize_pblock [get_pblocks $label] -add $regions
    set_property CONTAIN_ROUTING false [get_pblocks $label]
    add_cells_to_pblock [get_pblocks $label] $cells
    # Adding/reparenting cells may restore Vivado's default soft property.
    # Apply the intended strength after membership has been established.
    set_property IS_SOFT $soft [get_pblocks $label]
    puts "ASRAM_PHYSICAL_GROUP name=$label regions=$regions cells=[llength $cells] soft=$soft"
}

proc ::asram_physical::activation_banks {} {
    # Vivado uniquifies repeated modules as activation_sram_store__1/__2.
    # Lane hierarchy plus exact primitive counts below disambiguate the match.
    set stores [get_cells -hier -quiet -filter {REF_NAME =~ activation_sram_store*}]
    if {[llength $stores] != 3} {error "Expected three real ASRAM backing stores"}
    set seen {}
    foreach store $stores {
        set name [get_property NAME $store]
        if {![regexp {^(.*\/activationSrams(?:_([12]))?)\/} $name -> controller lane]} {
            error "Unrecognized physical ASRAM hierarchy: $name"
        }
        if {$lane eq ""} {set lane 0}
        if {$lane in $seen} {error "Duplicate ASRAM lane $lane"}
        lappend seen $lane
        set slr [lindex {SLR0 SLR1 SLR3} $lane]
        set cells [get_cells -hier -quiet -filter "NAME =~ ${name}/* && REF_NAME =~ URAM288*"]
        if {[llength $cells] != 72} {error "ASRAM lane $lane must retain 72 URAM primitives"}
        set parent [one $controller]
        set_property USER_SLR_ASSIGNMENT $slr $parent
        pblock asram_lane${lane}_controller $slr $parent true
        pblock asram_lane${lane}_uram $slr $cells false
    }
    if {[lsort $seen] ne {0 1 2}} {error "ASRAM lane identities must be 0/1/2"}
}

proc ::asram_physical::baseline_groups {} {
    # The routed DMA baseline puts 64/128 Head URAM in SLR0/1 and none in SLR2.
    # Use the free SLR2 URAM columns, leaving room for local Gemmini + ASRAM.
    set head [one */u_head_uram_router]
    set root [get_property NAME $head]
    set urams [get_cells -hier -quiet -filter "NAME =~ ${root}/* && REF_NAME =~ URAM288*"]
    if {[llength $urams] != 192} {error "Expected all 192 Head URAM primitives"}
    set_property USER_SLR_ASSIGNMENT SLR2 $head
    pblock asram_head_controller SLR2 $head true
    pblock asram_head_uram SLR2 $urams false

    # Release the baseline bank0 SLR0 preference, relieving the DDR-side SLR.
    # Keep these guides soft: timing placement may trade locality for congestion.
    foreach old [get_pblocks -quiet memory_v3_l2_bank*] {delete_pblocks $old}
    foreach {index bank} {0 inclusive_cache_bank_sched 1 inclusive_cache_bank_sched_1} {
        set cells [one */coh_wrapper/l2/$bank]
        set_property USER_SLR_ASSIGNMENT SLR2 $cells
        pblock asram_l2_bank${index} SLR2 $cells true
    }

    # Retain the crossbar's DDR-side locality. The final slice gets a regional
    # guide around the routed MIG AXI write packer, instead of a whole-SLR hint.
    set xbar [one */u_ddr_bd/design_1_i/axi_interconnect_0/xbar]
    set slice [one */u_ddr_bd/design_1_i/m00_full_regslice]
    foreach old [get_pblocks -quiet memory_v3_ddr_xbar_slice_slr0] {delete_pblocks $old}
    set_property USER_SLR_ASSIGNMENT SLR0 [concat $xbar $slice]
    pblock asram_ddr_xbar SLR0 $xbar true
    # Filled from the baseline checkpoint's endpoint clock region; see README.
    pblock asram_ddr_m00 {CLOCKREGION_X4Y2:CLOCKREGION_X5Y2} $slice true

    # Keep stream reset/CE decision logic near its upstream recovery/event
    # producer. This addresses the observed SLR1 -> SLR2 -> SLR1 detour.
    for {set lane 0} {$lane < 8} {incr lane} {
        set pattern [format {.*g_camera_frontend\[%d\]\.u_camera_stream$} $lane]
        set stream [get_cells -hier -quiet -regexp $pattern]
        if {[llength $stream] != 1} {error "Expected camera stream hierarchy $lane"}
        set slr [expr {$lane < 4 ? "SLR2" : "SLR1"}]
        set_property USER_SLR_ASSIGNMENT $slr $stream
        pblock asram_camera_stream${lane} $slr $stream true
    }
}
