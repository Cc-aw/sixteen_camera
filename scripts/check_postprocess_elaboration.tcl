set script_dir [file dirname [file normalize [info script]]]
set repo_dir [file dirname $script_dir]

open_project [file join $repo_dir prj sixteen_camera.xpr]
source [file join $repo_dir setup_vivado.tcl]
update_compile_order -fileset sources_1

foreach required_file {
    axi4_channel_join.sv
    fbus_read_engine.sv
    postprocess_read_diagnostic.sv
    yolov5nu_postprocessor.sv
    yolov5nu_class_reducer.sv
    yolov5nu_raw_class_lut.sv
    yolov5nu_dfl_lut.sv
    yolov5nu_dfl_decoder.sv
    yolov5nu_bbox_decoder.sv
    yolov5nu_topk_nms.sv
} {
    if {[llength [get_files -quiet */$required_file]] != 1} {
        error "Required postprocessor source is missing or duplicated: $required_file"
    }
}

set part_name [get_property PART [current_project]]
synth_design -rtl -name postprocess_rtl_elab -top top_wrapper -part $part_name
puts "POSTPROCESS_TOP_ELABORATION=PASS"
close_design
close_project
