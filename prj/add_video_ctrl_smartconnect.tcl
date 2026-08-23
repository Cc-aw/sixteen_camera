set script_dir [file dirname [file normalize [info script]]]
open_project [file join $script_dir sixteen_camera.xpr]
set smartconnect_xci [file normalize [file join $script_dir .. rtl ip \
    video_ctrl_bd_smartconnect_0_0 video_ctrl_bd_smartconnect_0_0.xci]]
if {![file exists $smartconnect_xci]} {
    error "Missing SmartConnect IP source: $smartconnect_xci"
}
if {[llength [get_files -quiet $smartconnect_xci]] == 0} {
    add_files -norecurse $smartconnect_xci
}
update_compile_order -fileset sources_1
set_property top top_wrapper [get_filesets sources_1]
save_project
puts "VIDEO_CTRL_SMARTCONNECT_XCI_REGISTERED=PASS"
close_project
