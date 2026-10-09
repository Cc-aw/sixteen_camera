# Rebuild/open the integration example. Vivado controls IP/BD output paths.
# VIVADO_PROJECT optionally selects any local .xpr path, including outside build/.
set repo_dir [file dirname [file dirname [file dirname [file normalize [info script]]]]]
set build_project [file join $repo_dir hw vivado sixteen_camera.xpr]
if {[info exists ::env(VIVADO_PROJECT)] && $::env(VIVADO_PROJECT) ne ""} {
    set build_project [file normalize $::env(VIVADO_PROJECT)]
}
set project_work_dir [file dirname $build_project]
set project_name [file rootname [file tail $build_project]]
if {[current_project -quiet] eq ""} {
    if {[file exists $build_project]} {
        open_project $build_project
    } else {
        create_project $project_name $project_work_dir -part xcvu13p-fhga2104-2-i
    }
} elseif {[file normalize [get_property DIRECTORY [current_project]]] ne \
          [file normalize $project_work_dir] ||
          [get_property NAME [current_project]] ne $project_name} {
    error "Another project is open; use setup_vivado.tcl to merge sources into it"
}
set sc_batch_setup true
if {![info exists sc_bd_checkpoint_mode]} {
    set sc_bd_checkpoint_mode Hierarchical
}
if {![info exists sc_generate_synth_checkpoint]} {
    set sc_generate_synth_checkpoint true
}
source [file join $repo_dir hw vivado setup_vivado.tcl]
if {$sc_total_failed != 0 ||
    $::sixteen_camera_setup::bd_status ne "OK" ||
    $::sixteen_camera_setup::wrapper_status ne "OK" ||
    $sc_top_status ne "OK"} {
    error "Project setup did not pass"
}
puts "VIVADO_PROJECT=$build_project"
