set script_dir [file dirname [file normalize [info script]]]
set project_root [file normalize [file join $script_dir ..]]
open_project [file join $script_dir sixteen_camera.xpr]
foreach relative_path {
    rtl/ai/preprocess/frame_preprocess_accel.sv
    rtl/ai/preprocess/batch_preprocess_engine.sv
} {
    set source_path [file join $project_root $relative_path]
    if {[llength [get_files -quiet $source_path]] == 0} {
        add_files -fileset sources_1 -norecurse $source_path
    }
}
update_compile_order -fileset sources_1
close_project
