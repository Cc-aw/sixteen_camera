set repo_dir [file dirname [file dirname [file dirname [file normalize [info script]]]]]
set sc_bd_checkpoint_mode None
set sc_generate_synth_checkpoint false
source [file join $repo_dir tools build open_build_project.tcl]
update_compile_order -fileset sources_1
foreach source {
    rgb888_to_rgb565.sv
    rgb565_to_rgb888.sv
    display_scaler.sv
    display_frame_packer.sv
    full_rgb565_reader.sv
    mosaic_rgb565_reader.sv
} {
    if {[llength [get_files -quiet */$source]] != 1} {
        error "Missing or duplicate Display source: $source"
    }
}
set part_name [get_property PART [current_project]]
synth_design -rtl -name display_compact_top_elab -top top_wrapper \
    -part $part_name
puts "DISPLAY_COMPACT_TOP_ELABORATION=PASS"
close_design
close_project
