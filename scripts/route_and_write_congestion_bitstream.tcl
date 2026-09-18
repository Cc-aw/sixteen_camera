set repo_dir [file dirname [file dirname [file normalize [info script]]]]
set run_dir [file join $repo_dir prj sixteen_camera.runs impl_congestion]
set physopt_checkpoint [file join $run_dir top_wrapper_physopt.dcp]
set routed_checkpoint [file join $run_dir top_wrapper_routed.dcp]
set run_bitstream [file join $run_dir top_wrapper.bit]
set canonical_bitstream [file join $repo_dir prj sixteen_camera.runs impl_1 \
    top_wrapper.bit]

if {![file isfile $physopt_checkpoint] ||
    [file size $physopt_checkpoint] == 0} {
    error "Missing physical-optimization checkpoint: $physopt_checkpoint"
}

set_param general.maxThreads 8
open_checkpoint $physopt_checkpoint
puts "SYNTHESIS_RELAUNCHED=NO"
puts "PLACEMENT_RELAUNCHED=NO"
puts "ROUTE_RESUME_CHECKPOINT=$physopt_checkpoint"

route_design -directive AlternateCLBRouting

# Save the legal routed design before running any memory-heavy reports. The
# previous run was killed inside report_timing_summary before its generated
# run script reached write_checkpoint and write_bitstream.
write_checkpoint -force $routed_checkpoint
write_bitstream -force $run_bitstream
file copy -force $run_bitstream $canonical_bitstream

puts "CONGESTION_AWARE_BITSTREAM=PASS"
puts "BITSTREAM=$canonical_bitstream"
close_design
