set repo_dir [file dirname [file dirname [file normalize [info script]]]]
set reference_checkpoint /tmp/top_wrapper_pre_mdrv_fix.dcp
if {[llength $argv] > 0} {
    set reference_checkpoint [file normalize [lindex $argv 0]]
}
if {![file isfile $reference_checkpoint]} {
    error "Incremental synthesis checkpoint does not exist: $reference_checkpoint"
}

open_project [file join $repo_dir prj sixteen_camera.xpr]
source [file join $repo_dir setup_vivado.tcl]
if {$sc_total_failed != 0 ||
    $::sixteen_camera_setup::bd_status ne "OK" ||
    $::sixteen_camera_setup::wrapper_status ne "OK" ||
    $sc_top_status ne "OK"} {
    error "Project setup did not pass"
}

foreach source {
    yolov5nu_tensor_stream_packer.sv
    yolov5nu_multi_channel_tensor_dma.sv
} {
    if {[llength [get_files -quiet */$source]] != 1} {
        error "Missing or duplicate tensor production source: $source"
    }
}

set synth_run [get_runs synth_1]
set impl_run [get_runs impl_1]
set_property strategy {Vivado Implementation Defaults} $impl_run
set bitstream [file join $repo_dir prj sixteen_camera.runs impl_1 top_wrapper.bit]
if {[file exists $bitstream]} {
    file copy -force $bitstream /tmp/sixteen_camera_before_tensor_production.bit
}

# The reference DCP is outside the run directory so reset_run cannot delete it.
# Vivado re-synthesizes changed RTL partitions and reuses unchanged partitions.
reset_run $synth_run
set_property INCREMENTAL_CHECKPOINT $reference_checkpoint $synth_run
puts "INCREMENTAL_SYNTH_CHECKPOINT=$reference_checkpoint"
launch_runs $synth_run -jobs 8
wait_on_run $synth_run
if {[get_property PROGRESS $synth_run] ne "100%"} {
    error "Incremental synthesis failed: [get_property STATUS $synth_run]"
}

launch_runs $impl_run -to_step write_bitstream -jobs 8
wait_on_run $impl_run
if {[get_property PROGRESS $impl_run] ne "100%" ||
    ![file exists $bitstream]} {
    error "Bitstream generation failed: [get_property STATUS $impl_run]"
}
open_run $impl_run
report_timing_summary -file [file join $repo_dir prj tensor_production_timing.rpt]
report_utilization -file [file join $repo_dir prj tensor_production_utilization.rpt]
puts "TENSOR_PRODUCTION_BITSTREAM=PASS"
puts "BITSTREAM=$bitstream"
close_project
