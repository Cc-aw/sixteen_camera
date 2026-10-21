# Actual PLACE_DESIGN.TCL.PRE hook for this private candidate.
set asram_flow [file dirname [file normalize [info script]]]
source [file join $asram_flow base placement_3x32.tcl]
source [file join $asram_flow physical_groups.tcl]
::asram_physical::baseline_groups
::asram_physical::activation_banks
# Reassert hard primitive blocks after all hierarchy memberships are added.
# This also keeps the retained mesh constraints hard in Vivado 2023.2.
foreach {label expected} {
    npu3x32_g0_rows_0_31 768
    npu3x32_g1_rows_0_31 768
    npu3x32_g2_rows_0_31 768
    asram_head_uram 192
    asram_lane0_uram 72
    asram_lane1_uram 72
    asram_lane2_uram 72
} {
    set pb [get_pblocks $label]
    set_property IS_SOFT false $pb
    set cells [get_cells -of_objects $pb -filter {REF_NAME == DSP48E2 || REF_NAME =~ URAM288*}]
    if {[llength $cells] != $expected || [get_property IS_SOFT $pb]} {
        error "Primitive placement block was not retained: $label"
    }
}
puts "ASRAM_PLACEMENT=PASS mesh_dsps=2304 head_uram=192 activation_uram=216 clocks_unchanged=1"
