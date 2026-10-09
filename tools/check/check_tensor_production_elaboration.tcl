set repo_dir [file dirname [file dirname [file dirname [file normalize [info script]]]]]
set sc_bd_checkpoint_mode None
set sc_generate_synth_checkpoint false
source [file join $repo_dir tools build open_build_project.tcl]
update_compile_order -fileset sources_1
foreach source {
    yolov5nu_tensor_stream_packer.sv
    yolov5nu_multi_channel_tensor_dma.sv
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
