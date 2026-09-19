set repo_dir [file dirname [file dirname [file normalize [info script]]]]
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
    yolov5nu_tensor_frame_writer.sv
    yolov5nu_tensor_capture_sidecar.sv
    axi4_write_arbiter2.sv
} {
    if {[llength [get_files -quiet */$source]] != 1} {
        error "Missing or duplicate tensor sidecar source: $source"
    }
}
set bitstream [file join $repo_dir prj sixteen_camera.runs impl_1 top_wrapper.bit]
if {[file exists $bitstream]} {
    file copy -force $bitstream /tmp/sixteen_camera_before_tensor_sidecar.bit
}
reset_run synth_1
launch_runs synth_1 -jobs 8
wait_on_run synth_1
if {[get_property PROGRESS [get_runs synth_1]] ne "100%"} {
    error "Synthesis failed: [get_property STATUS [get_runs synth_1]]"
}
set_property strategy {Vivado Implementation Defaults} [get_runs impl_1]
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1
if {[get_property PROGRESS [get_runs impl_1]] ne "100%" ||
    ![file exists $bitstream]} {
    error "Bitstream generation failed: [get_property STATUS [get_runs impl_1]]"
}
open_run impl_1
report_timing_summary -file [file join $repo_dir prj tensor_sidecar_timing.rpt]
report_utilization -file [file join $repo_dir prj tensor_sidecar_utilization.rpt]
puts "TENSOR_SIDECAR_BITSTREAM=PASS"
puts "BITSTREAM=$bitstream"
close_project
