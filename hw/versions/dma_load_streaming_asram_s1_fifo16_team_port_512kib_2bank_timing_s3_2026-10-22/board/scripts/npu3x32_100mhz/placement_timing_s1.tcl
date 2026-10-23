# Preserve the donor's DSP, ASRAM, Head URAM and L2 bank distribution.
set timing_s1_place_dir [file dirname [info script]]
source [file join $timing_s1_place_dir placement_merge_s1.tcl]

# Baseline: xbar -> S00 clock converter UI FFs has 95% route delay at 300MHz.
# Select only UI-clock FFs. Do not bind dual-clock RAM or the SoC port to SLR0.
set timing_s1_ui [filter [all_registers -clock [get_clocks mmcm_clkout0]] {REF_NAME =~ FD*}]
set timing_s1_cc [filter $timing_s1_ui \
    {NAME =~ u_ddr_memory/u_ddr_platform/u_ddr_bd/design_1_i/axi_interconnect_0/s00_couplers/auto_cc/*}]
if {[llength $timing_s1_cc] < 20} {error "Timing S1 missing S00 UI FFs"}
add_cells_to_pblock [get_pblocks timing_s5_ddr_ui_slr0] $timing_s1_cc

# Source-side elastic stages isolate CDC full/reset from video FIFO enables.
# These are soft hints, without adding a broad ordinary-logic hard pblock.
set timing_s1_tensor [get_cells -hier -quiet -filter \
    {NAME =~ u_ddr_memory/u_tensor_memory_bridge/u_aw_stage ||
     NAME =~ u_ddr_memory/u_tensor_memory_bridge/u_w_stage ||
     NAME =~ u_ddr_memory/u_tensor_memory_bridge/u_b_stage ||
     NAME =~ u_video_pipeline/u_tensor_ingress/u_tensor_dma}]
if {[llength $timing_s1_tensor] != 4} {error "Timing S1 missing Tensor source buffers"}
create_pblock timing_s1_tensor_source_slr0
resize_pblock [get_pblocks timing_s1_tensor_source_slr0] -add SLR0
set_property CONTAIN_ROUTING false [get_pblocks timing_s1_tensor_source_slr0]
set_property IS_SOFT true [get_pblocks timing_s1_tensor_source_slr0]
add_cells_to_pblock [get_pblocks timing_s1_tensor_source_slr0] $timing_s1_tensor
puts "TIMING_S1_LOCALITY=PASS UI_FFS=[llength $timing_s1_cc] TENSOR_GROUPS=[llength $timing_s1_tensor]"
unset timing_s1_place_dir timing_s1_ui timing_s1_cc timing_s1_tensor
