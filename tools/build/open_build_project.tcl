# Open a build copy; keep the checked-in XPR, BD and standalone IP inputs intact.
set repo_dir [file dirname [file dirname [file dirname [file normalize [info script]]]]]
source [file join $repo_dir hw manifests soc_manifest.tcl]
set build_label $SOC_VARIANT
if {[info exists ::env(SOC_CONFIG)] && $::env(SOC_CONFIG) ne ""} {
    set build_label $SOC_CONFIG
}
set project_work_dir [file join $repo_dir build vivado $build_label]
file mkdir $project_work_dir
set build_project [file join $project_work_dir sixteen_camera.xpr]
if {[file exists $build_project]} {
    open_project $build_project
} else {
    puts [exec python3 [file join $repo_dir tools build prepare_vivado_project.py] \
        --work-dir $project_work_dir]
    open_project $build_project
}
set sc_ip_work_dir [file join $project_work_dir ip]
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
