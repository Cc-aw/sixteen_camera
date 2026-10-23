source [file join [file dirname [info script]] placement_timing_s1.tcl]

# S1 placed the Tensor elastic source in SLR0, but allowed the FIFO's write
# pointer/full/reset FFs in SLR2. Localize only the video-side FFs as a unit;
# do not hard-bind dual-clock RAM or the SoC-side domain.
set s2_video_regs [filter [all_registers -clock [get_clocks camera_video_clk]] \
    {REF_NAME =~ FD* && NAME =~ u_ddr_memory/u_tensor_memory_bridge/*}]
if {[llength $s2_video_regs] < 100} {error "Missing Tensor video-side registers"}
set s2_pb timing_s2_tensor_video_control_slr0
create_pblock $s2_pb
resize_pblock [get_pblocks $s2_pb] -add SLR0
set_property CONTAIN_ROUTING false [get_pblocks $s2_pb]
set_property IS_SOFT false [get_pblocks $s2_pb]
add_cells_to_pblock [get_pblocks $s2_pb] $s2_video_regs
if {[get_property IS_SOFT [get_pblocks $s2_pb]]} {error "Tensor control locality was not applied"}
puts "TIMING_S2_TENSOR_LOCALITY=PASS VIDEO_FFS=[llength $s2_video_regs] DUAL_CLOCK_RAM_NOT_BOUND=1"
unset s2_video_regs s2_pb
