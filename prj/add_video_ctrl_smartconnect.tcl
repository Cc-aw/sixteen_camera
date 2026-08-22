set script_dir [file dirname [file normalize [info script]]]
open_project [file join $script_dir sixteen_camera.xpr]
set legacy_dir [file normalize [file join $script_dir one_ov5645_hdmi.gen sources_1 ip video_ctrl_bd_smartconnect_0_0]]
set smartconnect_verilog [file join $legacy_dir synth video_ctrl_bd_smartconnect_0_0.v]
set smartconnect_bd [file join $legacy_dir bd_0 synth bd_85c3.v]
foreach source_file [list $smartconnect_verilog $smartconnect_bd] {
    if {![file exists $source_file]} { error "Missing generated SmartConnect source: $source_file" }
    if {[llength [get_files -quiet $source_file]] == 0} {
        add_files -norecurse $source_file
    }
}
update_compile_order -fileset sources_1
set_property top top_wrapper [get_filesets sources_1]
save_project
puts "VIDEO_CTRL_SMARTCONNECT_REGISTERED=PASS"
close_project
