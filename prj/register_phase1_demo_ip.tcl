set script_dir [file dirname [file normalize [info script]]]
open_project [file join $script_dir sixteen_camera.xpr]

foreach stale_file [list \
    [file join $script_dir one_ov5645_hdmi.gen sources_1 ip video_ctrl_bd_smartconnect_0_0 synth video_ctrl_bd_smartconnect_0_0.v] \
    [file join $script_dir one_ov5645_hdmi.gen sources_1 ip video_ctrl_bd_smartconnect_0_0 bd_0 synth bd_85c3.v]] {
    set registered [get_files -quiet [file normalize $stale_file]]
    if {[llength $registered] != 0} { remove_files $registered }
}

set demo_src_dir [file normalize [file join $script_dir .. one_ov5645_hdmi.srcs sources_1 ip]]
foreach xci_file [list \
    [file join $demo_src_dir video_ctrl_bd_smartconnect_0_0 video_ctrl_bd_smartconnect_0_0.xci] \
    [file join $demo_src_dir clk_wiz_ov7670 clk_wiz_ov7670.xci]] {
    if {![file exists $xci_file]} { error "Missing demo IP source: $xci_file" }
    if {[llength [get_files -quiet [file normalize $xci_file]]] == 0} {
        add_files -norecurse $xci_file
    }
}

update_compile_order -fileset sources_1
set_property top top_wrapper [get_filesets sources_1]
puts "PHASE1_DEMO_IP_REGISTERED=PASS"
close_project
