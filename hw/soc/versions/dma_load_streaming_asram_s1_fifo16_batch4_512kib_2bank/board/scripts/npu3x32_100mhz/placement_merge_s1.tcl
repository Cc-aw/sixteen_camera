# Retain S5's cache, DSP, DDR UI and camera timing placement.
set merge_place_dir [file dirname [info script]]
source [file join $merge_place_dir placement_s5.tcl]
set merge_feature [file normalize [file join $merge_place_dir .. .. .. source/asram_feature]]
source [file join $merge_feature constraints physical_groups.tcl]

# ASRAM requires 72 URAM beside each Gemmini. Relocate Head URAM to SLR2,
# without importing the donor's older cache/DDR/camera floorplan.
set merge_head [::asram_physical::one */u_head_uram_router]
set merge_head_name [get_property NAME $merge_head]
set merge_head_urams [get_cells -hier -quiet -filter "NAME =~ ${merge_head_name}/* && REF_NAME =~ URAM288*"]
if {[llength $merge_head_urams] != 192} {error "Merged S1 expects 192 Head URAM"}
# Primitive-level old guides must be removed as well as the hierarchy hint.
foreach merge_pb [get_pblocks -quiet -of_objects $merge_head_urams] {
    remove_cells_from_pblock $merge_pb $merge_head_urams
}
set_property USER_SLR_ASSIGNMENT SLR2 $merge_head
::asram_physical::pblock merge_s1_head_controller SLR2 $merge_head true
::asram_physical::pblock merge_s1_head_uram SLR2 $merge_head_urams false
::asram_physical::activation_banks
foreach merge_pb {npu3x32_g0_rows_0_31 npu3x32_g1_rows_0_31 npu3x32_g2_rows_0_31 merge_s1_head_uram asram_lane0_uram asram_lane1_uram asram_lane2_uram} {
    set_property CONTAIN_ROUTING false [get_pblocks $merge_pb]
    set_property IS_SOFT false [get_pblocks $merge_pb]
    if {[get_property IS_SOFT [get_pblocks $merge_pb]]} {error "Lost hard resource placement: $merge_pb"}
}
puts "MERGED_S1_PLACEMENT=PASS HEAD_URAM=192@SLR2 ASRAM_URAM=72@SLR0/1/3 S5_L2_DDR_CAMERA_RETAINED=YES"
unset merge_place_dir merge_feature merge_head merge_head_name merge_head_urams merge_pb
