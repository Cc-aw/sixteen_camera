set repo_dir [file dirname [file dirname [file normalize [info script]]]]
open_project [file join $repo_dir prj sixteen_camera.xpr]
source [file join $repo_dir setup_vivado.tcl]
update_compile_order -fileset sources_1
foreach source {
    yolov5nu_tensor_stream_packer.sv
    yolov5nu_tensor_frame_writer.sv
    yolov5nu_tensor_capture_sidecar.sv
    yolov5nu_tensor_slot_ingest.sv
    axi4_write_arbiter2.sv
} {
    if {[llength [get_files -quiet */$source]] != 1} {
        error "Missing or duplicate tensor production source: $source"
    }
}
set part_name [get_property PART [current_project]]
synth_design -rtl -name tensor_production_rtl_elab -top top_wrapper -part $part_name
puts "TENSOR_PRODUCTION_TOP_ELABORATION=PASS"
close_design
close_project
